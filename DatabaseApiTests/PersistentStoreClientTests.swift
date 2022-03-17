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
        mock = PersistentStoreManagerImpl(mode: .app)
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
    
    func test__delete_many_saved_objects() {
        let emplyees = createEmployees(forClient: sut)
        
        sut.saveChanges()
        try! mock.masterContext.save()
        
        var fetchedEmployees: [Employee] = sut.fetch()
        
        assertThat(fetchedEmployees.count, equalTo(emplyees.count))
        
        sut.deleteMany(object: Employee.self, predicate: .ageGreatThen(12))
        
        fetchedEmployees = sut.fetch()
        
        assertThat(fetchedEmployees, empty())
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
        
        sut.insertMany(Employee.self, objects: jsonArray)
                
        let fetchedEmployees: [Employee] = sut.fetch()
                
        assertThat(fetchedEmployees.count, equalTo(jsonArray.count))
    }
    
    func test__update_many() {
        createEmployees(forClient: sut)
        
        sut.saveChanges()
        try? mock.masterContext.save()
        
        sut.updateMany(entity: Employee.self, filter: .ageGreatThen(30), propertiesToUpdate: ["name": "new name"])
        
        let fetchedEmployees: [Employee] = sut.fetch()
        
       let isAllEmployeesUpdated = fetchedEmployees.allSatisfy { employee in
            if employee.age! > 30 {
                return employee.name == "new name"
            } else {
                return true
            }
        }
        
        assertThat(isAllEmployeesUpdated == true)
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
