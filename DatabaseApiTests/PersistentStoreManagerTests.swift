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
    
    func test__observe_changes_the_same_client() {
        let client = sut.createNewClient()
        
        let employee1: Employee = client.createObject()
        employee1.name = "Tom"
        employee1.age = 22
        
        let employee2: Employee = client.createObject()
        employee2.name = "John"
        employee2.age = 35
        
        client.saveChanges()
        
        var insertedEmployees: [Employee] = []
        var updatedEmployees: [Employee] = []
        var deletedEmployees: [NSManagedObjectID] = []
        
        let expectation = expectation(description: "com.test.observe.changes.the.same.client")
        expectation.isInverted = true
        
        client.observeChanges { (inserted: [Employee], updated: [Employee], deleted: [NSManagedObjectID]) in
            insertedEmployees = inserted
            updatedEmployees = updated
            deletedEmployees = deleted
            expectation.fulfill()
        }
        
        client.deleteObject(employee1)
        
        employee2.age = 37
        
        createEmployees(forClient: client)
        
        client.saveChanges()
        
        waitForExpectations(timeout: 4, handler: nil)
        
        assertThat(insertedEmployees, empty())
        assertThat(updatedEmployees, empty())
        assertThat(deletedEmployees, empty())
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
        
        let expectation = expectation(description: "com.test.observe.changes")
        
        var insertedEmployees: [Employee] = []
        var updatedEmployees: [Employee] = []
        var deletedEmployees: [NSManagedObjectID] = []
        
        client2.observeChanges { (inserted: [Employee], updated: [Employee], deleted: [NSManagedObjectID]) in
            insertedEmployees = inserted
            updatedEmployees = updated
            deletedEmployees = deleted
            
            expectation.fulfill()
        }
        
        client1.deleteObject(employee1)
        
        employee2.age = 37
        
        let employees = createEmployees(forClient: client1)
        
        // action
        client1.saveChanges()
        
        waitForExpectations(timeout: 1, handler: nil)
        
        // check
        assertThat(insertedEmployees.count, equalTo(employees.count))
        
        assertThat(updatedEmployees.count, equalTo(1))
        assertThat(updatedEmployees.first?.age, equalTo(37))
        
        assertThat(deletedEmployees.count, equalTo(1))
        assertThat(deletedEmployees.first, equalTo(employee1.managedObjectID))
    }
    
    func test__observe_changes_of_multi_clients() {
        let client1 = sut.createNewClient()
        let client2 = sut.createNewClient()
        let client3 = sut.createNewClient()
        
        // prepare
        let employee1: Employee = client1.createObject()
        employee1.name = "Tom"
        employee1.age = 22
        
        let employee2: Employee = client1.createObject()
        employee2.name = "John"
        employee2.age = 35
        
        client1.saveChanges()
        
        let expectation = expectation(description: "com.test.observe.changes.of.multi.clients")
        expectation.expectedFulfillmentCount = 2
        
        var insertedEmployees: [Employee] = []
        var updatedEmployees: [Employee] = []
        var deletedEmployees: [NSManagedObjectID] = []
        
        client3.observeChanges { (inserted: [Employee], updated: [Employee], deleted: [NSManagedObjectID]) in
            insertedEmployees.append(contentsOf: inserted)
            updatedEmployees.append(contentsOf: updated)
            deletedEmployees.append(contentsOf: deleted)
            
            expectation.fulfill()
        }
        
        client1.deleteObject(employee1)
        
        employee2.age = 37
        
        let employees = createEmployees(forClient: client2)
        
        // action
        client1.saveChanges()
        client2.saveChanges()
        
        waitForExpectations(timeout: 1, handler: nil)
        
        // check
        assertThat(insertedEmployees.count, equalTo(employees.count))
        
        assertThat(updatedEmployees.count, equalTo(1))
        assertThat(updatedEmployees.first?.age, equalTo(37))
        
        assertThat(deletedEmployees.count, equalTo(1))
        assertThat(deletedEmployees.first, equalTo(employee1.managedObjectID))
    }
    
    @discardableResult
    private func createEmployees(forClient client: PersistentStoreClient) -> [Employee] {
        // swiftlint:disable force_cast
        let fileName = "employees_test_list"
        let url = Bundle.main.url(forResource: fileName, withExtension: "json")!
        var data: Data!
        var jsonArray: [NSDictionary] = []
        
        do {
            data = try Data(contentsOf: url)
            jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as! [NSDictionary]
        } catch {
            fatalError()
        }
        
        var employees: [Employee] = []
        
        jsonArray.forEach {
            let employee: Employee = client.createObject()
            employee.name = $0.value(forKey: "name") as! String
            employee.age = ($0.value(forKey: "age") as! Int)
            employees.append(employee)
        }
        
        return employees
        // swiftlint:enable force_cast
    }
}
