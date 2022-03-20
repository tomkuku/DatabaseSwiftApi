//
//  BackgorundDataStoreTests.swift
//  DatabaseApiTests
//
//  Created by Tomasz Kukułka on 18/03/2022.
//

import Foundation
import XCTest
import Hamcrest

@testable import DatabaseApi
import CoreData

class BackgorundDataStoreTests: XCTestCase {
    
    private var mock: ManagedObjectContextProvider!
    private var sut: DataStore!
    
    override func setUp() {
        super.setUp()
        mock = ManagedObjectContextProviderImpl(mode: .test("com.test.background.store.name"))
        sut = DataStoreImpl(context: mock.createNewBackgroundContext())
    }
    
    override func tearDown() {
        mock = nil
        sut = nil
        super.tearDown()
    }
    
    func test__delete_many() {
        sut.performAndWait {
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
            saveMainContext()
            
            var fetchedEmployees: [Employee] = sut.fetch()
            
            assertThat(fetchedEmployees.count, equalTo(4))
            
            sut.deleteMany(Employee.self, filter: .ageGreatThen(30))
            
            fetchedEmployees = sut.fetch()
            
            assertThat(fetchedEmployees.count, equalTo(2))
            
            fetchedEmployees.forEach {
                assertThat($0.age! <= 30)
            }
        }
    }
    
    func test__insert_many_objects() {
        let fileName = "employees_test_list"
        let url = Bundle.main.url(forResource: fileName, withExtension: "json")!
        var data: Data!
        var jsonArray: [[String: Any]] = []
        
        do {
            data = try Data(contentsOf: url)
            // swiftlint:disable:next force_cast
            jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
        } catch {
            fatalError()
        }
        
        sut.performAndWait {
            sut.insertMany(Employee.self, objects: jsonArray)
            
            let fetchedEmployees: [Employee] = sut.fetch()
            
            assertThat(fetchedEmployees.count, equalTo(jsonArray.count))
        }
    }
    
    func test__update_many() {
        sut.performAndWait {
            createEmployees()
            
            sut.saveChanges()
            saveMainContext()
            
            let newName = "JOHN"
            
            sut.updateMany(Employee.self, filter: .ageGreatThen(30), propertiesToUpdate: ["name": newName])
            
            let fetchedEmployees: [Employee] = sut.fetch()
            
            for employee in fetchedEmployees where employee.age! > 30 {
                assertThat(employee.name, equalTo(newName))
            }
        }
    }
    
    func test__observe_changes_on_main_context() {
        let mainDataStore: DataStore = DataStoreImpl(context: mock.mainContext)
        let backgroundDataStore: DataStore = DataStoreImpl(context: mock.createNewBackgroundContext())
        
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
        
        let expectation = expectation(description: "com.test.observe.changes")
        
        var insertedEmployees: [Employee] = []
        var updatedEmployees: [Employee] = []
        var deletedEmployees: [NSManagedObjectID] = []
        
        mainDataStore.observeChanges { (inserted: [Employee], updated: [Employee], deleted: [NSManagedObjectID]) in
            insertedEmployees = inserted
            updatedEmployees = updated
            deletedEmployees = deleted
            
            expectation.fulfill()
        }
        
        backgroundDataStore.performAndWait {
            backgroundDataStore.deleteObject(employee1)
            
            employee2.age = 37
            
            let employee3: Employee = backgroundDataStore.createObject()
            employee3.age = 43
            employee3.name = "Kate"
            
            backgroundDataStore.saveChanges()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
        backgroundDataStore.performAndWait {
            assertThat(insertedEmployees.count, equalTo(1))
            
            assertThat(updatedEmployees.count, equalTo(1))
            assertThat(updatedEmployees.first?.age, equalTo(37))
            
            assertThat(deletedEmployees.count, equalTo(1))
            assertThat(deletedEmployees.first, equalTo(employee1.managedObjectID))
        }
    }
    
    func test__observe_changes_on_background_context() {
        let mainDataStore: DataStore = DataStoreImpl(context: mock.mainContext)
        let backgroundDataStore: DataStore = DataStoreImpl(context: mock.createNewBackgroundContext())
        
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
        
        backgroundDataStore.perform {
            backgroundDataStore.observeChanges { (inserted: [Employee], updated: [Employee], deleted: [NSManagedObjectID]) in
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
    
    private func saveMainContext() {
        mock.mainContext.performAndWait {
            try? mock.mainContext.save()
        }
    }
    
    @discardableResult
    private func createEmployees() -> [Employee] {
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
            let employee: Employee = sut.createObject()
            employee.name = $0.value(forKey: "name") as! String
            employee.age = ($0.value(forKey: "age") as! Int)
            employees.append(employee)
        }
        
        return employees
        // swiftlint:enable force_cast
    }
    
}
