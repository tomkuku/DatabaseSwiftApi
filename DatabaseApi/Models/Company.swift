//
//  Company.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 10/03/2022.
//

import Foundation

final class Company: EntityRepresenter {
    
    @OptionalAttribute("street_name") var streetName: String?
    @OptionalAttribute var name: String?
    @ToManyRelationship var employees: Set<Employee>
}
