//
//  PersistentStoreManager.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 08/03/2022.
//

import Foundation
import CoreData

protocol PersistentStoreManager {
}

final class PersistentStoreManagerImpl: PersistentStoreManager {
    
    enum Mode {
        case app, test
    }
    
    // MARK: Properties
    
    private lazy var masterContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.persistentStoreCoordinator = persistentStoreCoordinator
        return moc
    }()
    
    private let storeName = "DatabaseApi"
    private let mode: Mode
    
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
            Log.error("ManagedObjectModel not found")
        }
        
        let storeFileName = "\(storeName).sqlite"
        let documentsDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let persistentStoreUrl = documentsDirectoryUrl.appendingPathComponent(storeFileName)
        
        let poc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        do {
            try poc.addPersistentStore(ofType: storeType, configurationName: nil, at: persistentStoreUrl, options: nil)
            Log.debug("Added PersistentStore with url: \(persistentStoreUrl)")
        } catch {
            Log.error("Adding PersistentStore faild with error: \(error.localizedDescription)")
        }
        return poc
    }()
    
    init(mode: Mode = .app) {
        self.mode = mode
    }
    
    deinit {
        do {
            if masterContext.hasChanges {
                try masterContext.save()
            }
        } catch {
            Log.warning("Master context saving faild with error: \(error.localizedDescription)")
            assertionFailure()
        }
    }
}
