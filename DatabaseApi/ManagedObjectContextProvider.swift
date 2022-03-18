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
        case app
        case test(String)
    }
    
    // MARK: Properties
    
    private let storeName: String
    private let mode: Mode
    
    private(set) lazy var mainContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = persistentStoreCoordinator
        moc.automaticallyMergesChangesFromParent = false
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return moc
    }()
    
    private lazy var persistentStoreUrl: URL = {
        let storeFileName = "\(storeName).sqlite"
        let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectoryUrl.appendingPathComponent(storeFileName)
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        guard
            let modelURL = Bundle.main.url(forResource: "DatabaseApi", withExtension: "momd"),
            let mom = NSManagedObjectModel(contentsOf: modelURL)
        else {
            Log.fatal("ManagedObjectModel not found.")
        }
        
        let poc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        if case .test = mode {
            do {
                try poc.destroyPersistentStore(at: persistentStoreUrl, ofType: NSSQLiteStoreType, options: nil)
            } catch {
                Log.error("Destroying persistent store failed with error: \(error.localizedDescription)")
            }
        }
        
        do {
            try poc.addPersistentStore(ofType: NSSQLiteStoreType,
                                       configurationName: nil,
                                       at: persistentStoreUrl,
                                       options: nil)
        } catch {
            Log.fatal("Adding PersistentStore faild with error: \(error.localizedDescription).")
        }
        return poc
    }()
    
    init(mode: Mode = .app) {
        switch mode {
        case .app:
            storeName = "DatabaseApi"
        case .test(let storeName):
            self.storeName = storeName
        }
        self.mode = mode
    }
    
    func createNewBackgroundContext() -> NSManagedObjectContext {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = mainContext
        moc.automaticallyMergesChangesFromParent = false
        return moc
    }
}
