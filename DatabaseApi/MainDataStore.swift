//
//  MainDataStore.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 19/03/2022.
//

import Foundation
import CoreData

protocol MainDataStore {
    func createObject<T: EntityRepresentable>() -> T
    func saveChanges()
    func revertUnsavedChanges()
    func fetch<T: Fetchable>(filter: T.Filter?, sorting: [T.Sorting], fetchLimit: Int?) -> [T]
    func deleteObject<T: EntityRepresentable>(_ object: T)
}

extension MainDataStore {
    func fetch<T: Fetchable>(filter: T.Filter? = nil, sorting: [T.Sorting] = [], fetchLimit: Int? = nil) -> [T] {
        fetch(filter: filter, sorting: sorting, fetchLimit: fetchLimit)
    }
    
    func fetchFirst<T: Fetchable>(filter: T.Filter? = nil, sorting: [T.Sorting] = []) -> T? {
        fetch(filter: filter, sorting: sorting, fetchLimit: 1).first
    }
}

final class MainDataStoreImpl: DataStoreImpl, MainDataStore {
    init(contextProvider: ManagedObjectContextProvider) {
        super.init(context: contextProvider.mainContext)
    }
}
