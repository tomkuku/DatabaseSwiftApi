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
}
