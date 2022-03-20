//
//  DataStoreTests.swift
//  DatabaseApiTests
//
//  Created by Tomasz Kukułka on 18/03/2022.
//

import Foundation
import XCTest
import Hamcrest
import CoreData

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
    
    func test__sync() {
        let mainDataStore: MainDataStore = MainDataStoreImpl(contextProvider: mock)
        let backgroundDataStore: BackgroundDataStore = BackgroundDataStoreImpl(contextProvider: mock)
        
        var fetchedEmployees: [Employee] = []
        
        var employee1: Employee!
        var employee2: Employee!
        
        backgroundDataStore.performAndWait {
            employee1 = backgroundDataStore.createObject()
            employee1.name = "Tom"
            employee1.age = 22
            
            employee2 = backgroundDataStore.createObject()
            employee2.name = "John"
            employee2.age = 35
            
            backgroundDataStore.saveChanges()
        }
        
        fetchedEmployees = mainDataStore.fetch()
        
        assertThat(fetchedEmployees.count, equalTo(2))
        
        let employeeToUpdate = fetchedEmployees.first(where: { $0.name == "Tom" })
        employeeToUpdate?.age = 24
        
        let employeeToDelete = fetchedEmployees.first(where: { $0.name == "John" })!
        
        let employee3: Employee = mainDataStore.createObject()
        employee3.age = 44
        employee3.name = "Kate"
        
        mainDataStore.deleteObject(employeeToDelete)
        
        mainDataStore.saveChanges()
        
        backgroundDataStore.performAndWait {
            fetchedEmployees = backgroundDataStore.fetch()
            
            assertThat(fetchedEmployees.count, equalTo(2))
            assertThat(employee1.age, equalTo(24))
        }
    }
    
    func test__observeChanges_on_background_store() {
        let mainDataStore: MainDataStore = MainDataStoreImpl(contextProvider: mock)
        let backgroundDataStore2: BackgroundDataStore = BackgroundDataStoreImpl(contextProvider: mock)
        
        // prepare
        let employee1: Employee = mainDataStore.createObject()
        employee1.name = "Tom"
        employee1.age = 22
        
        let employee2: Employee = mainDataStore.createObject()
        employee2.name = "John"
        employee2.age = 35
        
        mainDataStore.saveChanges()
        
        let expectation = expectation(description: "com.test.observe.changes")
        
        var insertedEmployees: [Employee] = []
        var updatedEmployees: [Employee] = []
        var deletedEmployees: [NSManagedObjectID] = []
        
        backgroundDataStore2.perform {
            backgroundDataStore2.observeChanges { (inserted: [Employee], updated: [Employee], deleted: [NSManagedObjectID]) in
                insertedEmployees = inserted
                updatedEmployees = updated
                deletedEmployees = deleted
                
                expectation.fulfill()
            }
        }
        
        mainDataStore.deleteObject(employee1)
        
        employee2.age = 37
        
        let employee3: Employee = mainDataStore.createObject()
        employee3.age = 43
        employee3.name = "Kate"
        
        // action
        mainDataStore.saveChanges()
        
        waitForExpectations(timeout: 1, handler: nil)
        
        // check
        assertThat(insertedEmployees.count, equalTo(1))
        
        assertThat(updatedEmployees.count, equalTo(1))
        assertThat(updatedEmployees.first?.age, equalTo(37))
        
        assertThat(deletedEmployees.count, equalTo(1))
        assertThat(deletedEmployees.first, equalTo(employee1.managedObjectID))
    }
}
