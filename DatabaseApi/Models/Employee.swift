//
//  Employee.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 10/03/2022.
//

import Foundation

final class Employee: EntityRepresenter {
    
    @Attribute var name: String
    @OptionalAttribute var age: Int?
    @ToOneRelationship var job: Company?
}

extension Employee: Fetchable {
    typealias Filter = FitlerPredicate
    typealias Sorting = SortDescriptors
    
    enum FitlerPredicate: Filterable {
        case ageGreatThen(Int)
        
        var predicate: NSPredicate? {
            switch self {
            case .ageGreatThen(let age): return NSPredicate(format: "age > %i", age)
            }
        }
    }
    
    enum SortDescriptors: Sortable {
        case ageAscending
        
        var sortDescriptor: NSSortDescriptor {
            switch self {
            case .ageAscending: return NSSortDescriptor(key: "age", ascending: true)
            }
        }
    }
}
