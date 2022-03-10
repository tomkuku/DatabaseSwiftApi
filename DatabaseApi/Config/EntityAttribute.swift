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
    fileprivate var key: String = ""
    
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
    var wrappedValue: T {
        get { databaseModelObject.getValue(forKey: key)! }
        set { databaseModelObject.set(newValue, forKey: key) }
    }
}

// MARK: - OptionalAttribute

@propertyWrapper
final class OptionalAttribute<T>: EntityAttribute {
    var wrappedValue: T? {
        get { databaseModelObject.getValue(forKey: key) }
        set { databaseModelObject.set(newValue, forKey: key) }
    }
}

// MARK: - ToOneRelationship

@propertyWrapper
final class ToOneRelationship<T: EntityRepresentable>: EntityAttribute {
    var wrappedValue: T? {
        get {
            guard let managedObject: NSManagedObject = databaseModelObject.getValue(forKey: key) else {
                Log.debug("ManagedObject is nil")
                return nil
            }
            return T.init(managedObject: managedObject)
        }
        set { databaseModelObject.set(newValue?.managedObject, forKey: key) }
    }
}

// MARK: - ToManyRelationship

@propertyWrapper
final class ToManyRelationship<T: EntityRepresentable>: EntityAttribute {
    var wrappedValue: Set<T> {
        get {
            guard let objects = databaseModelObject.mutableSetValue(forKey: key).allObjects as? [NSManagedObject] else {
                Log.debug("Converting NSMutableSet to array of NSManagedObjects faild!")
                return []
            }
            
            return Set(objects.map {
                T.init(managedObject: $0)
            })
        }
        set {
            let set = databaseModelObject.mutableSetValue(forKey: key)
            newValue.forEach {
                set.add($0.managedObject)
            }
        }
    }
}

extension NSManagedObject {
    func getValue<T>(forKey key: String) -> T? {
        willAccessValue(forKey: key)
        defer { didAccessValue(forKey: key) }
        return primitiveValue(forKey: key) as? T
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
