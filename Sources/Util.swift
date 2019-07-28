//
//  Util.swift
//  AWSLambdaAdapter
//
//  Created by Kelton Person on 7/27/19.
//

import Foundation
import Vapor

public extension Vapor.Request {
    
    var noContentResponse: Vapor.Response {
        let r = response()
        r.http.status = .noContent
        return r
    }
    
}
