//
//  NSManagedObject+getSetValue.swift
//  DatabaseApi
//
//  Created by Kukułka Tomasz on 28/05/2022.
//

import Foundation
import CoreData

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
