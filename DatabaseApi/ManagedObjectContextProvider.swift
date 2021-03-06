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
     You can use it to demanding operations like: deleteMany, insertMany, updateMany.
     */
    func createNewBackgroundContext() -> NSManagedObjectContext
}

final class ManagedObjectContextProviderImpl: ManagedObjectContextProvider {
    
    enum Mode {
        case app
        case test(String)
    }
    
    // MARK: Properties
    
    private let defaultStoreName = "DatabaseApi"
    private let storeName: String
    private let mode: Mode
    private var contexts: Set<NSManagedObjectContext> = []
    
    private(set) lazy var mainContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.persistentStoreCoordinator = persistentStoreCoordinator
        moc.automaticallyMergesChangesFromParent = false
        moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        addContextDidSaveObserver(to: moc)
        contexts.insert(moc)
        return moc
    }()
    
    private lazy var persistentStoreUrl: URL = {
        let storeFileName = "\(storeName).sqlite"
        let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectoryUrl.appendingPathComponent(storeFileName)
    }()
    
    private let managedObjectModel: NSManagedObjectModel = {
        guard
            let modelURL = Bundle.main.url(forResource: "DatabaseApi", withExtension: "momd"),
            let mom = NSManagedObjectModel(contentsOf: modelURL)
        else {
            Log.fatal("ManagedObjectModel not found.")
        }
        return mom
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let poc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        if case .test = mode {
            do {
                try poc.destroyPersistentStore(at: persistentStoreUrl, ofType: NSSQLiteStoreType, options: nil)
                Log.debug("Destroyed PersistentStore at url: \(persistentStoreUrl).")
            } catch {
                Log.fatal("Destroying PersistentStore failed with error: \(error.localizedDescription).")
            }
        }
        
        do {
            try poc.addPersistentStore(ofType: NSSQLiteStoreType,
                                       configurationName: nil,
                                       at: persistentStoreUrl,
                                       options: nil)
            Log.debug("Added PersistentStore at url: \(persistentStoreUrl).")
        } catch {
            Log.fatal("Adding PersistentStore faild with error: \(error.localizedDescription).")
        }
        return poc
    }()
    
    init(mode: Mode = .app) {
        switch mode {
        case .app:
            storeName = defaultStoreName
        case .test(let storeName):
            self.storeName = storeName
        }
        self.mode = mode
    }
    
    @objc private func contextDidMerge(notification: Notification) {
        guard let triggerContex = notification.object as? NSManagedObjectContext else {
            Log.error("Trigger context can not be found.")
            return
        }
        
        for context in contexts where context != triggerContex {
            context.performAndWait {
                context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                context.mergeChanges(fromContextDidSave: notification)
            }
            
            NotificationCenter.default.post(name: .NSManagedObjectContextObjectsDidMerge,
                                            object: context,
                                            userInfo: notification.userInfo)
        }
    }
    
    func createNewBackgroundContext() -> NSManagedObjectContext {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = mainContext
        moc.automaticallyMergesChangesFromParent = false
        addContextDidSaveObserver(to: moc)
        contexts.insert(moc)
        return moc
    }
    
    private func addContextDidSaveObserver(to context: NSManagedObjectContext) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidMerge(notification:)),
                                               name: .NSManagedObjectContextDidSave,
                                               object: context)
    }
}
