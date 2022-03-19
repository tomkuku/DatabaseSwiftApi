//
//  DataStoreTests.swift
//  DatabaseApiTests
//
//  Created by Tomasz Kukułka on 18/03/2022.
//

import Foundation
import XCTest
import Hamcrest

@testable import DatabaseApi

final class DataStoreTests: XCTestCase {
    
    private var mock: ManagedObjectContextProvider!
    private var sut: MainDataStore!
    
    override func setUp() {
        super.setUp()
        
        mock = ManagedObjectContextProviderImpl(mode: .test("com.test.store.name"))
        sut = MainDataStoreImpl(contextProvider: mock)
    }
    
    override func tearDown() {
        mock = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: Create + Save + Fetch
    
    func test__fetch_from_empty_store() {
        let fetchedEmployees: [Employee] = sut.fetch()
        
        assertThat(fetchedEmployees, empty())
    }
    
    func test__fetch_create_object() {
        let employee: Employee = sut.createObject()
        employee.age = 23
        employee.name = "John"
        
        sut.saveChanges()
        
        let fetchedEmployees: [Employee] = sut.fetch()
        let fetchedEmployee = fetchedEmployees.first
        
        assertThat(fetchedEmployees.count, equalTo(1))
        assertThat(fetchedEmployee?.name, equalTo("John"))
        assertThat(fetchedEmployee?.age, equalTo(23))
    }
    
    func test__fetch_with_filtering_and_sorting() {
        let employee1: Employee = sut.createObject()
        employee1.age = 23
        employee1.name = "John"
        
        let employee2: Employee = sut.createObject()
        employee2.age = 31
        employee2.name = "Kate"
        
        let employee3: Employee = sut.createObject()
        employee3.age = 29
        employee3.name = "Mark"
        
        let employee4: Employee = sut.createObject()
        employee4.age = 44
        employee4.name = "Harry"
        
        sut.saveChanges()
        
        let fetchedEmployees: [Employee] = sut.fetch(filter: .ageGreatThen(27), sorting: [.ageAscending])
        let firstFetchedEmployee = fetchedEmployees.first
        
        assertThat(fetchedEmployees.count, equalTo(3))
        assertThat(firstFetchedEmployee?.name, equalTo("Mark"))
        assertThat(firstFetchedEmployee?.age, equalTo(29))
    }
    
    func test__fetch_first_object() {
        let employee1: Employee = sut.createObject()
        employee1.age = 23
        employee1.name = "John"
        
        let employee2: Employee = sut.createObject()
        employee2.age = 31
        employee2.name = "Kate"
        
        let employee3: Employee = sut.createObject()
        employee3.age = 29
        employee3.name = "Mark"
        
        sut.saveChanges()
        
        let fetchedEmployee: Employee? = sut.fetchFirst(filter: .ageGreatThen(23), sorting: [.ageAscending])
        
        assertThat(fetchedEmployee?.name, equalTo("Mark"))
        assertThat(fetchedEmployee?.age, equalTo(29))
    }
    
    // MARK: Delete
    
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
                
        fetchedEmployees = sut.fetch()
        
        assertThat(fetchedEmployees, empty())
        assertThat(employee.age, equalTo(22))
        
        // save afert delete
        
        sut.saveChanges()
        
        fetchedEmployees = sut.fetch()
        
        assertThat(fetchedEmployees, empty())
        assertThat(employee.age, nilValue())
    }
    
    // MARK: RevertUnsavedChanes
    
    func test__revert_changes_not_saved_client() {
        let employee1: Employee = sut.createObject()
        employee1.age = 22
             
        sut.saveChanges()
        
        employee1.age = 23
                
        let employee2: Employee = sut.createObject()
        employee2.age = 45
        
        sut.revertUnsavedChanges()
        
        assertThat(employee1.age, equalTo(22))
        assertThat(employee2.age, nilValue())
    }
    
    func test__revert_changes_saved_client() {
        let employee: Employee = sut.createObject()
        employee.age = 22
        
        sut.saveChanges()
        sut.revertUnsavedChanges()
        
        let fetchedEmployees: [Employee] = sut.fetch()
        
        assertThat(fetchedEmployees.count, equalTo(1))
        assertThat(employee.age, equalTo(22))
    }
}
