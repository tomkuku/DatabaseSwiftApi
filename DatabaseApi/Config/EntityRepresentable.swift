//
//  EntityRepresentable.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 10/03/2022.
//

import Foundation
import CoreData

protocol EntityRepresentable: EntityRepresenter {
    init(managedObject: NSManagedObject)
}

class EntityRepresenter: EntityRepresentable {
    private let managedObject: NSManagedObject
    
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
            attribute.set(key: String(childName.dropFirst()))
        }
    }
}
