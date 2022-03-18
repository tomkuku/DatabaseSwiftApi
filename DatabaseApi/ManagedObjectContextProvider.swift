//
//  ManagedObjectContextProvider.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 17/03/2022.
//

import Foundation
import CoreData

protocol ManagedObjectContextProvider {
    /**
     It's special Context to be used only on main thread.
     You should use this context to undemanding operations.
    */
    var mainContext: NSManagedObjectContext { get }
    /**
     It's special Context to be used only on it's private dispatch queue.
     You can use is to demanding operations like: deleteMany, insertMany, updateMany.
    */
    func createNewBackgroundContext() -> NSManagedObjectContext
}

final class ManagedObjectContextProviderImpl: ManagedObjectContextProvider {
    
    enum Mode {
        case app, test
    }
    
    // MARK: Properties
    
    private(set) lazy var mainContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = persistentStoreCoordinator
        moc.automaticallyMergesChangesFromParent = false
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return moc
    }()
    
    private let storeName = "DatabaseApi"
    private let mode: Mode
    private let notificationCenter = NotificationCenter.default
    
    private lazy var storeType: String = {
        switch mode {
        case .app:
            return NSSQLiteStoreType
        case .test:
            return NSInMemoryStoreType
        }
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        guard
            let modelURL = Bundle.main.url(forResource: storeName, withExtension: "momd"),
            let mom = NSManagedObjectModel(contentsOf: modelURL)
        else {
            Log.fatal("ManagedObjectModel not found.")
        }
        
        let storeFileName = "\(storeName).sqlite"
        let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let persistentStoreUrl = documentsDirectoryUrl.appendingPathComponent(storeFileName)
        
        let poc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        do {
            try poc.addPersistentStore(ofType: storeType, configurationName: nil, at: persistentStoreUrl, options: nil)
        } catch {
            Log.fatal("Adding PersistentStore faild with error: \(error.localizedDescription).")
        }
        return poc
    }()
    
    init(mode: Mode = .app) {
        self.mode = mode
    }
    
    func createNewBackgroundContext() -> NSManagedObjectContext {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = mainContext
        moc.automaticallyMergesChangesFromParent = false
        return moc
    }
}
