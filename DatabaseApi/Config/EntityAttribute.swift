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
    fileprivate var name: String = ""
    
    init(_ name: String = "") {
        self.name = name
    }
    
    func set(name: String) {
        guard self.name == "" else { return }
        self.name = name
    }
}

// MARK: - Attribute

/**
 Represents single attribute of entity which can't to be passed or can't returned nil value.
 
 If name of property isn't equal to name of attribute in Model, you
 can pass it's name using `init(_ name: String)`.
 Using this wrapper in combination with optional attribute is
 programmer error and can lead to unidentified behavior.
 */
@propertyWrapper
final class Attribute<T>: EntityAttribute {
    var wrappedValue: T {
        get { databaseModelObject.getValue(forKey: name)! }
        set { databaseModelObject.set(newValue, forKey: name) }
    }
}

// MARK: - OptionalAttribute

/**
 Represents single attribute of entity which can to be passed an optional value.
 
 If name of property isn't equal to name of attribute in Model, you
 can pass it's name using `init(_ name: String)`.
 */
@propertyWrapper
final class OptionalAttribute<T>: EntityAttribute {
    var wrappedValue: T? {
        get { databaseModelObject.getValue(forKey: name) }
        set { databaseModelObject.set(newValue, forKey: name) }
    }
}

// MARK: - ToOneRelationship

/**
 Represents a ToOne relationship. This property must be an optional.
 
 If name of property isn't equal to name of attribute in Model, you
 can pass it's name using `init(_ name: String).`
 */
@propertyWrapper
final class ToOneRelationship<T: EntityRepresentable>: EntityAttribute {
    var wrappedValue: T? {
        get {
            guard let managedObject: NSManagedObject = databaseModelObject.getValue(forKey: name) else {
                Log.debug("ManagedObject is nil")
                return nil
            }
            return T.init(managedObject: managedObject)
        }
        set {
            guard
                let managedObjectID = newValue?.managedObjectID,
                let managedObject = databaseModelObject.managedObjectContext?.getExistingObject(for: managedObjectID)
            else { return }
            
            databaseModelObject.set(managedObject, forKey: name) }
    }
}

// MARK: - ToManyRelationship

/**
 Represents a ToMany relationship. This property must be `Set` of `EntityRepresentable`.
 
 If name of property isn't equal to name of attribute in Model, you
 can pass it's name using `init(_ name: String).`
 */
@propertyWrapper
final class ToManyRelationship<T: EntityRepresentable>: EntityAttribute {
    var wrappedValue: Set<T> {
        get {
            var objects: [NSManagedObject] = []
            
            databaseModelObject.managedObjectContext?.performAndWait {
                objects = databaseModelObject.mutableSetValue(forKey: name).allObjects as? [NSManagedObject]  ?? []
            }
            
            return Set(objects.map {
                T.init(managedObject: $0)
            })
        }
        set {
            databaseModelObject.managedObjectContext?.performAndWait {
                let set = databaseModelObject.mutableSetValue(forKey: name)
                set.removeAllObjects()
                for entity in newValue {
                    guard let managedObject = databaseModelObject.managedObjectContext?.getExistingObject(
                            for: entity.managedObjectID) else { continue }
                    set.add(managedObject)
                }
            }
        }
    }
}

extension NSManagedObject {
    func getValue<T>(forKey key: String) -> T? {
        var value: T?
        managedObjectContext?.performAndWait {
            willAccessValue(forKey: key)
            defer { didAccessValue(forKey: key) }
            value = primitiveValue(forKey: key) as? T
        }
        return value
    }
    
    func set(_ value: Any?, forKey key: String) {
        managedObjectContext?.performAndWait {
            willChangeValue(forKey: key)
            defer { didChangeValue(forKey: key) }
            guard let value = value else {
                setPrimitiveValue(nil, forKey: key)
                return
            }
            setPrimitiveValue(value, forKey: key)
        }
    }
}
