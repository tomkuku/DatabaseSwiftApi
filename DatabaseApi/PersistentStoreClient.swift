//
//  PersistentStoreClient.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 08/03/2022.
//

import Foundation
import CoreData

protocol PersistentStoreClient {
}

final class PersistentStoreClientImpl: PersistentStoreClient {
        
    init(context: NSManagedObjectContext) {
    }
}
