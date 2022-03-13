//
//  PersistentStoreClientTests.swift
//  DatabaseApiTests
//
//  Created by Tomasz Kukułka on 11/03/2022.
//

import XCTest
import Hamcrest

@testable import DatabaseApi

class PersistentStoreClientTests: XCTestCase {
    
    private var mock: PersistentStoreManager!
    private var sut: PersistentStoreClient!
    
    override func setUp() {
        super.setUp()
        mock = PersistentStoreManagerImpl(mode: .test)
        sut = mock.createNewClient()
    }
    
    override func tearDown() {
        sut = nil
        mock = nil
        
        super.tearDown()
    }
    
    func test__fetch_from_empty_store() {
        let fetchedEmployees: [Employee] = sut.fetch()
        
        assertThat(fetchedEmployees, empty())
    }
    
    func test__fetch_saved_objects() {
        let employee1: Employee = sut.createObject()
        employee1.age = 22
        
        let employee2: Employee = sut.createObject()
        employee2.age = 23
        
        let employee3: Employee = sut.createObject()
        employee3.age = 35
        
        let employee4: Employee = sut.createObject()
        employee4.age = 41
                        
        sut.saveChanges()
        
        var fetchedEmployees: [Employee] = sut.fetch(filter: .ageGreatThen(45))
        
        assertThat(fetchedEmployees, empty())
        
        fetchedEmployees = sut.fetch(filter: .ageGreatThen(23))
        
        assertThat(fetchedEmployees.count, equalTo(2))
    }
    
    func test__fetch_first_object() {        
        let employee1: Employee = sut.createObject()
        employee1.age = 22
        
        let employee2: Employee = sut.createObject()
        employee2.age = 35
        
        let employee3: Employee = sut.createObject()
        employee3.age = 41
        
        sut.saveChanges()
        
        let fetchedEmployee: Employee? = sut.fetchFirstObject(filter: .ageGreatThen(23), sorting: [.ageAscending])
        
        assertThat(fetchedEmployee?.age, equalTo(employee2.age))
    }
    
    func test__revert_changes_not_saved_client() {
        let employee1: Employee = sut.createObject()
        employee1.age = 22
        
        let employee2: Employee = sut.createObject()
        employee2.age = 41
        
        sut.revertChanges()
        
        assertThat(employee1.age, nilValue())
        assertThat(employee2.age, nilValue())
    }
    
    func test__revert_changes_saved_client() {
        let employee: Employee = sut.createObject()
        employee.age = 22
        
        sut.saveChanges()
        sut.revertChanges()
        
        let fetchedEmployees: [Employee] = sut.fetch()
        
        assertThat(fetchedEmployees.count, equalTo(1))
        assertThat(employee.age, equalTo(22))
    }
    
    func test__delete_not_saved_object() {
        let employee: Employee = sut.createObject()
        employee.age = 22
        
        sut.deleteObject(employee)
        
        let fetchedEmployees: [Employee] = sut.fetch()
        
        assertThat(fetchedEmployees, empty())
        assertThat(employee.age, nilValue())
    }
    
    func test__delete_saved_object() {
        let employee: Employee = sut.createObject()
        employee.age = 22
        
        sut.saveChanges()
        sut.deleteObject(employee)
        
        var fetchedEmployees: [Employee] = sut.fetch()
        
        assertThat(fetchedEmployees, empty())
        assertThat(employee.age, equalTo(22))
        
        sut.saveChanges()
        fetchedEmployees = sut.fetch()
        
        assertThat(fetchedEmployees, empty())
        assertThat(employee.age, nilValue())
    }
}