//
//  LambdaLogger.swift
//  AWSLambdaAdapter
//
//  Created by Kelton Person on 7/2/19.
//

import Foundation
import Vapor

#if os(Linux)
import Glibc
#else
import Darwin.C
#endif

extension LogLevel {
    
    var rank: Int {
        switch self {
        case .verbose: return 1
        case .debug: return 2
        case .info: return 3
        case .warning: return 4
        case .error: return 5
        case .fatal: return 6
        default: return 7
        }
    }
    
    static var all: [LogLevel] = [.verbose, .debug, .info, .warning, .error, .fatal]
    
}

public struct LambdaLogMessage {
    
    public let message: String
    public let file: String
    public let function: String
    public let line: UInt
    public let column: UInt
    public let level: LogLevel
    public let date: Date
    public let passesThreshold: Bool
}

public protocol LambdaLoggerAppender {
    
    func append(message: LambdaLogMessage)
    
}

public class LambdaLogger: Logger, Service {
    
    private let levelThreshold: LogLevel
    
    public static var appenders: [LambdaLoggerAppender] = []
    public static var shouldPrint: Bool = true
    let printLogger = PrintLogger()
    
    public init(level: LogLevel? = nil) {
        if let l = level {
            self.levelThreshold = l
        }
        else if
            let l = ProcessInfo.processInfo.environment["LOG_LEVEL"],
            let level = LogLevel.all.first(where: { String(describing: $0) == l })
        {
            self.levelThreshold = level
        }
        else {
            self.levelThreshold = .info
        }
    }
    
    
    public func log(_ string: String, at level: LogLevel, file: String, function: String, line: UInt, column: UInt) {
        let passesThreshold = level.rank >= levelThreshold.rank
        if passesThreshold {
            if LambdaLogger.shouldPrint {
                printLogger.log(string, at: level, file: file, function: function, line: line, column: column)
                fflush(stdout)
            }
        }
        
        let message = LambdaLogMessage(
            message: string,
            file: file,
            function: function,
            line: line,
            column: column,
            level: level,
            date: Date(),
            passesThreshold: passesThreshold
        )
        for a in LambdaLogger.appenders {
            a.append(message: message)
        }
    }
    
}
