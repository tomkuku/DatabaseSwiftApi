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
            
            sut.deleteMany(Employee.self, filter: .ageGreatThen(30))
            
            let fetchedEmployees: [Employee] = sut.fetch()
            
            assertThat(fetchedEmployees.count, equalTo(2))
            
            fetchedEmployees.forEach {
                assertThat($0.age! <= 30)
            }
        }
    }
}
