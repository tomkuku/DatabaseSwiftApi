//
//  PersistentStoreManager.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 08/03/2022.
//

import Foundation
import CoreData

protocol PersistentStoreManager {
    var masterContext: NSManagedObjectContext { get }
    func createNewClient() -> PersistentStoreClient
}

final class PersistentStoreManagerImpl: PersistentStoreManager {
    
    enum Mode {
        case app, test
    }
    
    // MARK: Properties
    
    lazy var masterContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = persistentStoreCoordinator
        return moc
    }()
    
    private(set) lazy var viewContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.parent = masterContext
        moc.automaticallyMergesChangesFromParent = true
        return moc
    }()
    
    private var clients: [PersistentStoreClientImpl] = []
    private var chlidrenContexts: Set<NSManagedObjectContext> = []
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
    
    deinit {
        masterContext.performAndWait {
            do {
                if masterContext.hasChanges {
                    try masterContext.save()
                }
            } catch {
                Log.error("Master context saving faild with error: \(error.localizedDescription).")
                assertionFailure()
            }
        }
        
        notificationCenter.removeObserver(self)
    }
    
    @objc private func clientDidSaved(notification: Notification) {
        guard let triggerContex = notification.object as? NSManagedObjectContext else {
            Log.error("Trigger context can not be found.")
            return
        }
        
        Log.debug("Context \(triggerContex) did save.")
        
        for client in clients where client.context != triggerContex {
            client.context.performAndWait {
                client.context.mergeChanges(fromContextDidSave: notification)
            }
        }
        self.notificationCenter.post(name: .NSManagedObjectContextObjectsDidMerge,
                                     object: triggerContex,
                                     userInfo: notification.userInfo)
    }
    
    private func getObjectIDs(from notification: Notification, key: String) -> Set<NSManagedObjectID> {
        guard let objects = notification.userInfo?[key] as? Set<NSManagedObject> else {
            Log.debug("No ManagedObjects from notification.")
            return []
        }
        return Set(objects.compactMap { $0.objectID })
    }
    
    func createNewBackgroundContex() -> NSManagedObjectContext {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.parent = viewContext
        moc.automaticallyMergesChangesFromParent = true
        return moc
    }
    
    func createNewClient() -> PersistentStoreClient {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.parent = masterContext
        moc.automaticallyMergesChangesFromParent = true
        
        notificationCenter.addObserver(self,
                                       selector: #selector(clientDidSaved(notification:)),
                                       name: .NSManagedObjectContextDidSave,
                                       object: moc)
        
        chlidrenContexts.insert(moc)
        
        let client = PersistentStoreClientImpl(context: moc)
        clients.append(client)
        return client
    }
}
