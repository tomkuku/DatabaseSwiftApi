//
//  EntityRepresentable.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 10/03/2022.
//

import Foundation
import CoreData

protocol EntityRepresentable: AnyObject {
    init(managedObject: NSManagedObject)
}
