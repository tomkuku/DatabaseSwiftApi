//
//  EntityAttribute.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 10/03/2022.
//

import Foundation
import CoreData

class EntityAttribute {
    var databaseModelObject: NSManagedObject!
    private(set) var key: String = ""
    
    init(_ key: String = "") {
        self.key = key
    }
    
    func set(key: String) {
        guard self.key == "" else { return }
        self.key = key
    }
}

// MARK: - Attribute

@propertyWrapper
final class Attribute<T>: EntityAttribute {
    var wrappedValue: T? {
        get { databaseModelObject.getValue(forKey: key) }
        set { databaseModelObject.set(newValue, forKey: key) }
    }
}

extension NSManagedObject {
    func getValue<T>(forKey key: String) -> T? {
        var returnValue: T?
        willAccessValue(forKey: key)
        defer { didAccessValue(forKey: key) }
        
        returnValue = primitiveValue(forKey: key) as? T
        return returnValue
    }
    
    func set(_ value: Any?, forKey key: String) {
        willChangeValue(forKey: key)
        defer { didChangeValue(forKey: key) }
        
        guard let value = value else {
            setPrimitiveValue(nil, forKey: key)
            return
        }
        setPrimitiveValue(value, forKey: key)
    }
}
