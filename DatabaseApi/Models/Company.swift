//
//  Company.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 10/03/2022.
//

import Foundation

final class Company: EntityRepresenter {
    
    @OptionalAttribute var name: String?
    @ToManyRelationship var employees: Set<Employee>
}
