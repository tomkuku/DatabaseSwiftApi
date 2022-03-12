//
//  PersistentStoreClient.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 08/03/2022.
//

import Foundation
import CoreData

protocol PersistentStoreClient {
    func createObject<T: EntityRepresentable>() -> T
    func saveChanges()
    func revertChanges()
    /**
     Deletes single object.
     If object has already been saved into database, object will be deleted when the saveChanges method is called.
     If object has been created in client only, object will be deleted immediately.
     - Parameter object: A EntityRepresentable object.
     */
    func deleteObject<T: EntityRepresentable>(_ object: T)
    func fetch<T: Fetchable>(filter: T.Filter?, sorting: [T.Sorting], fetchLimit: Int?) -> [T]
    /**
     Calls handler method each time when persistent store was modified (insert, update, deleted).
     This method is called only when another client modifies store.
     - Parameter handler: Code which is executes when persistent store was modified.
     */
    func observeChanges<T: EntityRepresentable>(
        handler: @escaping (_ inserted: [T], _ updated: [T], _ deletedIDs: [NSManagedObjectID]) -> Void)
}

extension PersistentStoreClient {
    func fetch<T: Fetchable>(filter: T.Filter? = nil, sorting: [T.Sorting] = [], fetchLimit: Int? = nil) -> [T] {
        fetch(filter: filter, sorting: sorting, fetchLimit: fetchLimit)
    }
    
    func fetchFirstObject<T: Fetchable>(filter: T.Filter? = nil, sorting: [T.Sorting] = []) -> T? {
        fetch(filter: filter, sorting: sorting, fetchLimit: 1).first
    }
}

final class PersistentStoreClientImpl: PersistentStoreClient {
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func saveChanges() {
        guard context.hasChanges else {
            Log.debug("Context doesn't have changes.")
            return
        }
        
        do {
            try context.save()
        } catch {
            Log.error("Saving context faild with error: \(error.localizedDescription)")
        }
    }
    
    func revertChanges() {
        context.rollback()
    }
    
    func observeChanges<T: EntityRepresentable>(handler: @escaping ([T], [T], [NSManagedObjectID]) -> Void) {
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidMerge,
                                               object: nil,
                                               queue: .current) { notification in
            let inserted: [T] = notification.getModifiedEntitys(forKey: NSInsertedObjectsKey)
            let updated: [T] = notification.getModifiedEntitys(forKey: NSUpdatedObjectsKey)
            var deleted: [NSManagedObjectID] = []
            
            if let deletes = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
                deleted = deletes.map { $0.objectID }
            } else {
                Log.debug("No deleted objects")
            }
            
            handler(inserted, updated, deleted)
        }
    }
    
    func createObject<T: EntityRepresentable>() -> T {
        let entityName = String(describing: T.self)
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            Log.fatal("Entity with name \(entityName) not found!")
        }
        let managedObject = NSManagedObject(entity: entity, insertInto: context)
        return T.init(managedObject: managedObject)
    }
    
    func fetch<T: Fetchable>(filter: T.Filter?, sorting: [T.Sorting], fetchLimit: Int?) -> [T] {
        let entityName = String(describing: T.self)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = filter?.predicate
        fetchRequest.sortDescriptors = sorting.map { $0.sortDescriptor }
        fetchRequest.fetchLimit = fetchLimit ?? fetchRequest.fetchLimit
        
        var objects: [NSManagedObject] = []
        
        do {
            objects = try context.fetch(fetchRequest)
        } catch {
            Log.error("Fetching \(entityName) failed with error \(error.localizedDescription)")
        }
        
        return objects.map {
            T.init(managedObject: $0)
        }
    }
    
    func deleteObject<T: EntityRepresentable>(_ object: T) {
        context.delete(object.managedObject)
    }
}
fileprivate extension NSManagedObjectContext {
    func getExistingObject(for id: NSManagedObjectID) -> NSManagedObject? {
        var object: NSManagedObject?
        
        do {
            object = try existingObject(with: id)
        } catch {
            Log.error("Getting existing object failed with error: \(error.localizedDescription)")
        }
        return object
    }
}

extension Notification.Name {
    // swiftlint:disable:next identifier_name
    static var NSManagedObjectContextObjectsDidMerge: Self {
        .init(rawValue: "NSManagedObjectContextObjectsDidChange")
    }
}

fileprivate extension Notification {
    func getModifiedEntitys<T: EntityRepresentable>(forKey key: String) -> [T] {
        guard let objects = self.userInfo?[key] as? Set<NSManagedObject> else {
            Log.debug("No ManagedObjects from notification for key \(key)")
            return []
        }
        return objects.compactMap { T.init(managedObject: $0) }
    }
}
