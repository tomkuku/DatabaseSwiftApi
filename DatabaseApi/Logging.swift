//
//  Logging.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 08/03/2022.
//

import Foundation
import os.log

final class Log {
    
    private static let log = OSLog(subsystem: "database.api", category: "basic")
    
    private init() { }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log("\nℹ️ %@ %@:%d: %@", log: log, type: .debug, file.fileName, function, line, message)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log("\n⚠️ %@: %@%d: %@", log: log, type: .default, file.fileName, function, line, message)
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log("\n🚨 %@ %@:%d: %@", log: log, type: .error, file.fileName, function, line, message)
    }
    
    static func fatal(_ message: String, file: String = #file, function: String = #function, line: Int = #line) -> Never {
        os_log("\n⛔️ %@ %@:%d: %@", log: log, type: .fault, file.fileName, function, line, message)
        fatalError("")
    }
}

fileprivate extension String {
    var fileName: String {
        (self as NSString).lastPathComponent
    }
}
