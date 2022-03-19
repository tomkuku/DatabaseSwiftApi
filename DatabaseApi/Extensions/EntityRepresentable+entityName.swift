//
//  EntityRepresentable+entityName.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 19/03/2022.
//

import Foundation

extension EntityRepresentable {
    static var entityName: String {
        String(describing: Self.self)
    }
}
