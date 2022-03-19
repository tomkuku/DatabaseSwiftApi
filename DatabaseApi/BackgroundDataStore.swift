//
//  BackgroundDataStore.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 19/03/2022.
//

import Foundation
import CoreData

protocol BackgroundDataStore: MainDataStore {
    func perform(_ block: @escaping () -> Void)
    func performAndWait(_ block: () -> Void)
    func deleteMany<T: Fetchable>(_ entity: T.Type, filter: T.Filter?)
    func insertMany<T: EntityRepresentable>(_ entity: T.Type, objects: [[String: Any]])
    func updateMany<T: Fetchable>(_ entity: T.Type, filter: T.Filter?, propertiesToUpdate: [AnyHashable: Any])
}

extension BackgroundDataStore {
    func deleteMany<T: Fetchable>(_ entity: T.Type, filter: T.Filter? = nil) {
        deleteMany(entity, filter: filter)
    }
    
    func updateMany<T: Fetchable>(_ entity: T.Type, filter: T.Filter? = nil, propertiesToUpdate: [AnyHashable: Any]) {
        updateMany(entity, filter: filter, propertiesToUpdate: propertiesToUpdate)
    }
}

final class BackgroundDataStoreImpl: DataStoreImpl, BackgroundDataStore {
    
    init(contextProvider: ManagedObjectContextProvider) {
        super.init(context: contextProvider.createNewBackgroundContext())
    }
    
    func perform(_ block: @escaping () -> Void) {
        context.perform {
            block()
        }
    }
    
    func performAndWait(_ block: () -> Void) {
        context.performAndWait {
            block()
        }
    }
        
    func deleteMany<T: Fetchable>(_ entity: T.Type, filter: T.Filter? = nil) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: T.entityName)
        fetchRequest.predicate = filter?.predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        var batchDeleteResult: NSBatchDeleteResult?
                
        do {
            batchDeleteResult = try context.execute(deleteRequest) as? NSBatchDeleteResult
        } catch {
            Log.error("Executing batch delete request falied with error: \(error.localizedDescription).")
        }
        
        guard let objectIDs = batchDeleteResult?.result as? [NSManagedObjectID], objectIDs.count > 0 else {
            Log.debug("No deleted object ids.")
            return
        }
        
        mergeChanges(objectIDs: objectIDs, key: NSDeletedObjectIDsKey)
    }
    
    func insertMany<T: EntityRepresentable>(_ entity: T.Type, objects: [[String: Any]]) {
        let batchInsertRequest = NSBatchInsertRequest(entityName: T.entityName, objects: objects)
        batchInsertRequest.resultType = .objectIDs
        
        var batchInsertResult: NSBatchInsertResult?
        
        do {
            batchInsertResult = try context.execute(batchInsertRequest) as? NSBatchInsertResult
        } catch {
            Log.error("Executing batch insert request falied with error: \(error.localizedDescription).")
        }
        
        guard let objectIDs = batchInsertResult?.result as? [NSManagedObjectID], objectIDs.count > 0 else {
            Log.debug("No inserted object ids.")
            return
        }
        
        mergeChanges(objectIDs: objectIDs, key: NSInsertedObjectsKey)
    }
    
    func updateMany<T: Fetchable>(_ entity: T.Type, filter: T.Filter?, propertiesToUpdate: [AnyHashable: Any]) {
        let request = NSBatchUpdateRequest(entityName: T.entityName)
        request.predicate = filter?.predicate
        request.propertiesToUpdate = propertiesToUpdate
        request.resultType = .updatedObjectIDsResultType
        
        var result: NSBatchUpdateResult?
        
        do {
            result = try context.execute(request) as? NSBatchUpdateResult
        } catch {
            Log.error("Updating many failed with error: \(error.localizedDescription)")
        }
        
        guard let objectIDs = result?.result as? [NSManagedObjectID], objectIDs.count > 0 else {
            Log.error("No updated objectIDs")
            return
        }
        
        mergeChanges(objectIDs: objectIDs, key: NSUpdatedObjectIDsKey)
    }
    
    private func mergeChanges(objectIDs: [NSManagedObjectID], key: String) {
        let save = [key: objectIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: save, into: [context])
    }
}
