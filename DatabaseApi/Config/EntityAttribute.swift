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

/**
 Represents single attribute of entity which can't to be passed or can't returned nil value.
 
 If name of property isn't equal to name of attribute in Model, you
 can pass it's name using `init(_ key: String)`.
 Using this wrapper in combination with optional attribute is
 programmer error and can lead to unidentified behavior.
 */
@propertyWrapper
final class Attribute<T>: EntityAttribute {
    var wrappedValue: T {
        get { databaseModelObject.getValue(forKey: key)! }
        set { databaseModelObject.set(newValue, forKey: key) }
    }
}

// MARK: - OptionalAttribute

/**
 Represents single attribute of entity which can to be passed an optional value.
 
 If name of property isn't equal to name of attribute in Model, you
 can pass it's name using `init(_ key: String)`.
 */
@propertyWrapper
final class OptionalAttribute<T>: EntityAttribute {
    var wrappedValue: T? {
        get { databaseModelObject.getValue(forKey: key) }
        set { databaseModelObject.set(newValue, forKey: key) }
    }
}

// MARK: - ToOneRelationship

/**
 Represents a ToOne relationship. This property must be an optional.
 
 If name of property isn't equal to name of attribute in Model, you
 can pass it's name using `init(_ key: String).`
 */
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

/**
 Represents a ToMany relationship. This property must be `Set` of `EntityRepresentable`.
 
 If name of property isn't equal to name of attribute in Model, you
 can pass it's name using `init(_ key: String).`
 */
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
            set.removeAllObjects()
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
