//
//  EntityAttributeTests.swift
//  DatabaseApiTests
//
//  Created by Tomasz Kukułka on 10/03/2022.
//

import Foundation
import Hamcrest
import XCTest

@testable import DatabaseApi

final class EntityAttributeTests: XCTestCase {
    
    private var sut: PersistentStoreClient!
    
    override func setUp() {
        super.setUp()
        
        let persistentStoreManager = PersistentStoreManagerImpl(mode: .test)
        self.sut = persistentStoreManager.createNewClient()
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    func test__create_object_without_values() {
        let employee: Employee = sut.createObject()
        
        assertThat(employee.name, equalTo("-"))
        assertThat(employee.age, nilValue())
        assertThat(employee.job, nilValue())
    }
    
    func test__set_optional_value() {
        let employee: Employee = sut.createObject()
        employee.name = "Tom"
        employee.age = nil
        employee.job = nil
        
        assertThat(employee.name, equalTo("Tom"))
        assertThat(employee.age, nilValue())
        assertThat(employee.job, nilValue())
    }
    
    func test__set_not_optional_value() {
        let company: Company = sut.createObject()
        company.name = "MyCompany"
        company.streetName = "custom street"
        
        let employee: Employee = sut.createObject()
        employee.name = "Tom"
        employee.age = 23
        employee.job = company
        company.employees.insert(employee)
        
        assertThat(employee.name, equalTo("Tom"))
        assertThat(employee.age, equalTo(23))
        assertThat(employee.job?.name, equalTo(company.name))
        assertThat(company.streetName, equalTo("custom street"))
        assertThat(employee.job?.employees.count, equalTo(1))
        assertThat(company.employees.first?.name, equalTo("Tom"))
    }
    
    func test__to_many_relationship() {
        let employee1: Employee = sut.createObject()
        employee1.name = "Tom"
        
        let employee2: Employee = sut.createObject()
        employee2.name = "John"
        
        let company: Company = sut.createObject()
        company.name = "MyCompany"
        company.streetName = "custom street"
        
        company.employees = [employee1]
        company.employees.insert(employee2)
        company.employees.insert(employee1)
        company.employees.insert(employee2)
        
        assertThat(company.employees.count, equalTo(2))
        
        company.employees.forEach {
            assertThat($0.job?.name, equalTo("MyCompany"))
        }
        
        company.employees.remove(employee1)
        
        assertThat(company.employees.count, equalTo(1))
        
        company.employees.removeAll()
        
        assertThat(company.employees, empty())

    }
}
