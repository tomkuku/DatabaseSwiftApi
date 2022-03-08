//
//  Logging.swift
//  DatabaseApi
//
//  Created by Tomasz Kukułka on 08/03/2022.
//

import Foundation
import os.log

final class Log {
    
    private enum Level: String {
        case debug = "ℹ️"
        case error = "⛔️"
        case warning = "⚠️"
    }
    
    private static let log = OSLog(subsystem: "database.api", category: "basic")
    
    private init() { }
    
    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        os_log("%@ %@:%d: %@", log: log, type: .debug, Level.debug.rawValue, (file as NSString).lastPathComponent, line, message)
    }
    
    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        os_log("%@ %@:%d: %@", log: log, type: .default, Level.warning.rawValue, (file as NSString).lastPathComponent, line, message)
    }
    
    static func error(_ message: String, file: String = #file, line: Int = #line) -> Never {
        os_log("%@ %@:%d: %@", log: log, type: .error, Level.error.rawValue, (file as NSString).lastPathComponent, line, message)
        fatalError(message)
    }
}
