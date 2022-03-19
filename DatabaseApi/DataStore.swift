//
//  DataStore.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 18/03/2022.
//

import Foundation
import CoreData

protocol DataStore {
    func createObject<T: EntityRepresentable>() -> T
    func saveChanges()
    func revertUnsavedChanges()
    func fetch<T: Fetchable>(filter: T.Filter?, sorting: [T.Sorting], fetchLimit: Int?) -> [T]
    func deleteObject<T: EntityRepresentable>(_ object: T)
}

extension DataStore {
    func fetch<T: Fetchable>(filter: T.Filter? = nil, sorting: [T.Sorting] = [], fetchLimit: Int? = nil) -> [T] {
        fetch(filter: filter, sorting: sorting, fetchLimit: fetchLimit)
    }
    
    func fetchFirst<T: Fetchable>(filter: T.Filter? = nil, sorting: [T.Sorting] = []) -> T? {
        fetch(filter: filter, sorting: sorting, fetchLimit: 1).first
    }
}

protocol BackgroundDataStore: DataStore {
    func perform(_ block: @escaping () -> Void)
    func performAndWait(_ block: () -> Void)
    func deleteMany<T: Fetchable>(_ entity: T.Type, filter: T.Filter?)
    func insertMany<T: EntityRepresentable>(_ entity: T.Type, objects: [[String: Any]])
}

extension BackgroundDataStore {
    func deleteMany<T: Fetchable>(_ entity: T.Type, filter: T.Filter? = nil) {
        deleteMany(entity, filter: filter)
    }
}

final class DataStoreImpl: DataStore, BackgroundDataStore {
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: DataStore
    
    func createObject<T: EntityRepresentable>() -> T {
        let entityName = String(describing: T.self)
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            Log.fatal("Entity with name \(entityName) not found!")
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
        let entityName = String(describing: T.self)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        fetchRequest.predicate = filter?.predicate
        fetchRequest.sortDescriptors = sorting.map { $0.sortDescriptor }
        fetchRequest.fetchLimit = fetchLimit ?? fetchRequest.fetchLimit
        
        var objects: [NSManagedObject] = []
        
        do {
            objects = try context.fetch(fetchRequest)
        } catch {
            Log.error("Fetching \(entityName) failed with error \(error.localizedDescription).")
        }
        
        return objects.map { T.init(managedObject: $0) }
    }
    
    func deleteObject<T: EntityRepresentable>(_ object: T) {
        context.delete(context.getExistingObject(for: object.managedObjectID))
    }
    
    // MARK: BackgroundDataStore
    
    func perform(_ block: @escaping () -> Void) {
        context.perform {
            block()
        }
    }
    
    func performAndWait(_ block: () -> Void) {
        context.performAndWait {
            print("block hadling")
            block()
        }
    }
        
    func deleteMany<T: Fetchable>(_ entity: T.Type, filter: T.Filter? = nil) {
        let entityName = String(describing: T.self)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = filter?.predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        var batchDeleteResult: NSBatchDeleteResult?
                
        do {
            batchDeleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
        } catch {
            Log.error("Executing batch delete request falied with error: \(error.localizedDescription)")
        }
        
        let objectIDArray = batchDeleteResult?.result as? [NSManagedObjectID]
        let deletedObjects: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDArray]
        
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: deletedObjects, into: [context])
    }
    
    func insertMany<T: EntityRepresentable>(_ entity: T.Type, objects: [[String: Any]]) {
        let entityName = String(describing: T.self)
        let batchInsertRequest = NSBatchInsertRequest(entityName: entityName, objects: objects)
        batchInsertRequest.resultType = .objectIDs
        
        let result = try? context.execute(batchInsertRequest) as? NSBatchInsertResult
        
        if let objectIDs = result?.result as? [NSManagedObjectID], objectIDs.count > 0 {
            let save = [NSInsertedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: save, into: [context])
        }
    }
}
