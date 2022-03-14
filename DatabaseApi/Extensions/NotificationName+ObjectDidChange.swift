//
//  NotificationName+ObjectDidChange.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 13/03/2022.
//

import Foundation

extension Notification.Name {
    // swiftlint:disable:next identifier_name
    static var NSManagedObjectContextObjectsDidMerge: Self {
        .init(rawValue: "NSManagedObjectContext.ObjectsDidChange")
    }
}
