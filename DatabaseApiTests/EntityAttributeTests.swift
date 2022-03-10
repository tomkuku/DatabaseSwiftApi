//
//  EntityAttributeTests.swift
//  DatabaseApiTests
//
//  Created by Tomasz Kukułka on 10/03/2022.
//

import Foundation
import Hamcrest
import XCTest

@testable import DatabaseApi

final class EntityAttributeTests: XCTestCase {
    
    private var sut: PersistentStoreClient!
    
    override func setUp() {
        super.setUp()
        
        let persistentStoreManager = PersistentStoreManagerImpl(mode: .test)
        self.sut = PersistentStoreClientImpl(context: persistentStoreManager.getContext())
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    func test__create_object_without_values() {
        let employee: Employee = sut.createObject()
        
        assertThat(employee.name, equalTo("-"))
        assertThat(employee.age, nilValue())
    }
    
    func test__set_optional_value() {
        let employee: Employee = sut.createObject()
        employee.name = "Tom"
        employee.age = nil
        
        assertThat(employee.name, equalTo("Tom"))
        assertThat(employee.age, nilValue())
    }
    
    func test__set_not_optional_value() {
        let employee: Employee = sut.createObject()
        employee.name = "Tom"
        employee.age = 23
        
        assertThat(employee.name, equalTo("Tom"))
        assertThat(employee.age, equalTo(23))
    }
}
