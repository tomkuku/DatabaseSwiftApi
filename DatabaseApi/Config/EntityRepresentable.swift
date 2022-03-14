//
//  EntityRepresentable.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 10/03/2022.
//

import Foundation
import CoreData

typealias DatabaseObjectID = NSManagedObjectID

protocol EntityRepresentable: Hashable {
//    var managedObject: NSManagedObject { get }
    var managedObjectID: DatabaseObjectID { get }
    init(managedObject: NSManagedObject)
}

extension EntityRepresentable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(managedObjectID)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.managedObjectID == rhs.managedObjectID
    }
}

class EntityRepresenter: EntityRepresentable {
    private var managedObject: NSManagedObject
    
    var managedObjectID: DatabaseObjectID {
        managedObject.objectID
    }
    
    required init(managedObject: NSManagedObject) {
        self.managedObject = managedObject
        config()
    }
    
    private func config() {
        let mirrored = Mirror(reflecting: self)
        for child in mirrored.children {
            guard
                let childName = child.label,
                let attribute = mirrored.descendant(childName) as? EntityAttribute
            else { continue }
            
            attribute.databaseModelObject = self.managedObject
            attribute.set(name: String(childName.dropFirst()))
        }
    }
}
