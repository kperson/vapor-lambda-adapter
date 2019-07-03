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


public class LambdaLogger: Logger, Service {
    
    public init() {
    }
    
    let printLogger = PrintLogger()
    
    public func log(_ string: String, at level: LogLevel, file: String, function: String, line: UInt, column: UInt) {
        printLogger.log(string, at: level, file: file, function: function, line: line, column: column)
        fflush(stdout)
    }
    
}
