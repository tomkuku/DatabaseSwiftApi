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

class BackgorundDataStoreTests: XCTestCase {
    
    private var mock: ManagedObjectContextProvider!
    private var sut: BackgroundDataStore!
    
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
            mock.mainContext.performAndWait {
                try! mock.mainContext.save() // swiftlint:disable:this force_try
            }
            
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
}
