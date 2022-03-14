//
//  NSManagedObjectContext+getExistingObject.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 12/03/2022.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func getExistingObject(for id: NSManagedObjectID) -> NSManagedObject {
        var object: NSManagedObject!
        
        performAndWait {
            do {
                object = try existingObject(with: id)
            } catch {
                Log.fatal("Getting existing object failed with error: \(error.localizedDescription).")
            }
        }
        return object
    }
}
