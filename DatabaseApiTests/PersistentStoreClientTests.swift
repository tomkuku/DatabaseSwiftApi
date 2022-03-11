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
        sut = PersistentStoreClientImpl(context: mock.getNewContext())
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
        let secondPersistentStoreClient = PersistentStoreClientImpl(context: mock.getNewContext())
        
        let employee1: Employee = secondPersistentStoreClient.createObject()
        employee1.age = 22
        
        let employee2: Employee = secondPersistentStoreClient.createObject()
        employee2.age = 23
        
        let employee3: Employee = secondPersistentStoreClient.createObject()
        employee3.age = 35
        
        let employee4: Employee = secondPersistentStoreClient.createObject()
        employee4.age = 41
        
        var fetchedEmployees: [Employee] = sut.fetch()
        
        assertThat(fetchedEmployees, empty())
        
        secondPersistentStoreClient.saveChanges()
        
        fetchedEmployees = sut.fetch()
        
        assertThat(fetchedEmployees.count, equalTo(4))
        
        fetchedEmployees = sut.fetch(filter: .ageGreatThen(45))
        
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
    
    func test__revert_changes() {
        let employee1: Employee = sut.createObject()
        employee1.age = 22
        
        let employee2: Employee = sut.createObject()
        employee2.age = 41
        
        sut.saveChanges()
        
        employee2.age = 42
        
        let employee3: Employee = sut.createObject()
        employee3.age = 33
        
        sut.revertChanges()
        
        let fetchedEmployees: [Employee] = sut.fetch()
        
        assertThat(fetchedEmployees.count, equalTo(2))
        assertThat(employee3.age, nilValue())
    }
}
