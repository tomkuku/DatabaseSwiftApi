//
//  DataStore.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 18/03/2022.
//

import Foundation
import CoreData

class DataStoreImpl {
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: DataStore
    
    func createObject<T: EntityRepresentable>() -> T {
        guard let entity = NSEntityDescription.entity(forEntityName: T.entityName, in: context) else {
            Log.fatal("Entity with name \(T.entityName) not found!")
        }
        
        let managedObject = NSManagedObject(entity: entity, insertInto: context)
        return T.init(managedObject: managedObject)
    }
    
    func saveChanges() {
        guard context.hasChanges else {
            Log.debug("Context has not changes.")
            return
        }
        do {
            try context.save()
        } catch {
            Log.error("Saving context failed with error \(error.localizedDescription)")
        }
    }
    
    func revertUnsavedChanges() {
        context.rollback()
    }
    
    func fetch<T: Fetchable>(filter: T.Filter?, sorting: [T.Sorting], fetchLimit: Int?) -> [T] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: T.entityName)
        fetchRequest.predicate = filter?.predicate
        fetchRequest.sortDescriptors = sorting.map { $0.sortDescriptor }
        fetchRequest.fetchLimit = fetchLimit ?? fetchRequest.fetchLimit
        
        var objects: [NSManagedObject] = []
        
        do {
            objects = try context.fetch(fetchRequest)
        } catch {
            Log.error("Fetching \(T.entityName) failed with error \(error.localizedDescription).")
        }
        
        return objects.map { T.init(managedObject: $0) }
    }
    
    func deleteObject<T: EntityRepresentable>(_ object: T) {
        context.delete(context.getExistingObject(for: object.managedObjectID))
    }
    
    func observeChanges<T: EntityRepresentable>(handler: @escaping ([T], [T], [DatabaseObjectID]) -> Void) {
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidMerge,
                                               object: context,
                                               queue: nil) { notification in
            let inserted: [T] = notification.getModifiedEntitys(forKey: NSInsertedObjectsKey)
            let updated: [T] = notification.getModifiedEntitys(forKey: NSUpdatedObjectsKey)
            var deleted: [NSManagedObjectID] = []
            
            if let deletes = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
                deleted = deletes.map { $0.objectID }
            } else {
                Log.debug("No deleted objects in notification.")
            }
            
            handler(inserted, updated, deleted)
        }
    }
}

fileprivate extension Notification {
    func getModifiedEntitys<T: EntityRepresentable>(forKey key: String) -> [T] {
        guard let objects = self.userInfo?[key] as? Set<NSManagedObject> else {
            Log.debug("No modified ManagedObjects from notification for key \(key).")
            return []
        }
        return objects.map { T.init(managedObject: $0) }
    }
}
