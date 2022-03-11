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
    func fetch<T: Fetchable>(filter: T.Filter?, sorting: [T.Sorting], fetchLimit: Int?) -> [T]
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
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
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
            Log.error("Fetching \(entityName) failure with error \(error.localizedDescription)")
        }
        
        return objects.map {
            T.init(managedObject: $0)
        }
    }
}
