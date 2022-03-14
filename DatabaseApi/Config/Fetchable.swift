//
//  Fetchable.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 11/03/2022.
//

import Foundation

protocol Filterable {
    var predicate: NSPredicate? { get }
}

protocol Sortable {
    var sortDescriptor: NSSortDescriptor { get }
}

protocol Fetchable: EntityRepresentable {
    associatedtype Filter: Filterable
    associatedtype Sorting: Sortable
}

enum VoidFilter: Filterable {
    var predicate: NSPredicate? { nil }
}

enum VoidSorting: Sortable {
    var sortDescriptor: NSSortDescriptor { NSSortDescriptor() }
}
