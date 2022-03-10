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
    
    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        os_log("ℹ️ %@:%d:\n%@", log: log, type: .debug, file.fileName, line, message)
    }
    
    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        os_log("⚠️ %@:%d:\n%@", log: log, type: .default, file.fileName, line, message)
    }
    
    static func error(_ message: String, file: String = #file, line: Int = #line) {
        os_log("🚨 %@:%d:\n%@", log: log, type: .error, file.fileName, line, message)
    }
    
    static func fatal(_ message: String, file: String = #file, line: Int = #line) -> Never {
        os_log("⛔️ %@:%d:\n%@", log: log, type: .fault, file.fileName, line, message)
        fatalError("")
    }
}

fileprivate extension String {
    var fileName: String {
        (self as NSString).lastPathComponent
    }
}
