//
//  PersistentStoreManagerTests.swift
//  DatabaseApiTests
//
//  Created by Tomasz Kukułka on 11/03/2022.
//

import Foundation
import XCTest
import Hamcrest

@testable import DatabaseApi
import CoreData

final class PersistentStoreManagerTests: XCTestCase {
    
    private var sut: PersistentStoreManager!
    
    override func setUp() {
        super.setUp()
        
        sut = PersistentStoreManagerImpl(mode: .test)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func test__sync_between_clients() {
        let client1 = sut.createNewClient()
        let client2 = sut.createNewClient()
        
        let employee1: Employee = client1.createObject()
        employee1.name = "Tom"
        employee1.age = 22
        
        let employee2: Employee = client1.createObject()
        employee2.name = "John"
        employee2.age = 35

        let employee3: Employee = client1.createObject()
        employee3.age = 41
        
        var fetchedEmployees: [Employee] = client2.fetch()
        
        assertThat(fetchedEmployees, empty())
        
        client1.saveChanges()
        
        fetchedEmployees = client2.fetch()
        
        assertThat(fetchedEmployees.count, equalTo(3))
        
        let fetchedEmployee1 = fetchedEmployees.first(where: { $0.age == 22 })
        fetchedEmployee1?.age = 23
        
        client2.saveChanges()
        
        assertThat(employee1.age, equalTo(23))
    }
    
    func test__observeChanges() {
        let client1 = sut.createNewClient()
        let client2 = sut.createNewClient()
        
        // prepare
        let employee1: Employee = client1.createObject()
        employee1.name = "Tom"
        employee1.age = 22
        
        let employee2: Employee = client1.createObject()
        employee2.name = "John"
        employee2.age = 35
        
        client1.saveChanges()
        
        let expectation = expectation(description: "com.observe.changes")
        
        var insertedEmployees: [Employee] = []
        var updatedEmployees: [Employee] = []
        var deletedEmployees: [NSManagedObjectID] = []
        
        client2.observeChanges { (inserted: [Employee], updated: [Employee], deleted: [NSManagedObjectID]) in
            insertedEmployees = inserted
            updatedEmployees = updated
            deletedEmployees = deleted
            
            expectation.fulfill()
        }
        
        let employee3: Employee = client1.createObject()
        employee3.age = 41
        employee3.name = "Susan"
        
        client1.deleteObject(employee1)
        
        employee2.age = 37
        
        // action
        client1.saveChanges()
        
        waitForExpectations(timeout: 1, handler: nil)
        
        // check
        assertThat(insertedEmployees.count, equalTo(1))
        assertThat(insertedEmployees.first?.name, equalTo("Susan"))
        
        assertThat(updatedEmployees.count, equalTo(1))
        assertThat(updatedEmployees.first?.age, equalTo(37))
        
        assertThat(deletedEmployees.count, equalTo(1))
        assertThat(deletedEmployees.first, equalTo(employee1.managedObjectID))
    }
}
