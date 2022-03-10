//
//  PersistentStoreClient.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 08/03/2022.
//

import Foundation
import CoreData

protocol PersistentStoreClient {
    func createObject<E: EntityRepresentable>() -> E
    func saveChanges()
    func fetch<E: EntityRepresentable>() -> [E]
}

final class PersistentStoreClientImpl: PersistentStoreClient {
        
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func createObject<E: EntityRepresentable>() -> E {
        let entityName = String(describing: E.self)
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else {
            Log.fatal("Entity with name \(entityName) not found!")
        }
        let managedObject = NSManagedObject(entity: entity, insertInto: context)
        return E.init(managedObject: managedObject)
    }
    
    func saveChanges() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                Log.error("Saving context failure with error: \(error.localizedDescription)")
            }
        }
    }
    
    func fetch<E: EntityRepresentable>() -> [E] {
        let entityName = String(describing: E.self)
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        var objects: [NSManagedObject] = []
        
        do {
            objects = try context.fetch(fetchRequest)
        } catch {
            Log.error("Fetching \(entityName) failure with error \(error.localizedDescription)")
        }
        
        return objects.map {
            E.init(managedObject: $0)
        }
    }
}
