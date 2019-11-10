//
//  VaporLambdaHTTP.swift
//  AWSLambdaAdapter
//
//  Created by Kelton Person on 6/23/19.
//
import Foundation
import AWSLambdaAdapter
import Vapor

public class VaporLambdaHTTP {
    
    public class func configure() {
        if
            CommandLine.arguments[0] == "/opt/swift-shared-libs/ld-linux-x86-64.so.2"
            && CommandLine.arguments[1] == "--library-path"
            && CommandLine.arguments[2] == "/opt/swift-shared-libs/lib"
        {
            CommandLine.arguments.remove(at: 0)
            CommandLine.arguments.remove(at: 0)
            CommandLine.arguments.remove(at: 0)
        }
    }
    
}

public extension Application {
    
    convenience init(
        runAsLambda: Bool,
        config: Config = Config.default(),
        environment: Environment = .development,
        services: Services = Services.default()
        ) throws {
        if runAsLambda {
            var newConfig = config
            newConfig.prefer(LambdaHTTPServer.self, for: Server.self)
            newConfig.prefer(LambdaLogger.self, for: Logger.self)
            
            var newServices = services
            newServices.register(LambdaHTTPServer.self)
            
            newServices.register(Logger.self) { _ in
                return LambdaLogger()
            }
            
            try self.init(config: newConfig, environment: environment, services: newServices)
        }
        else {
            try self.init(config: config, environment: environment, services: services)
        }
    }
    
}


struct LambdaHTTPRequest {
    
    let httpMethod: String
    let path: String
    let body: Data?
    let queryStringParameters: [String: String]
    let headers: [String: String]
    
    init?(dictionary: [String: Any], lambdaHeaders: [String : Any]) {
        if  let hm = dictionary["httpMethod"] as? String,
            let pathParameters = dictionary["pathParameters"] as? [String : Any],
            let isBase64Encoded = dictionary["isBase64Encoded"] as? Bool {
            let path = pathParameters["proxy"] as? String ?? ""
            self.httpMethod = hm
            
            self.path = path.starts(with: "/") ? path : "/\(path)"
            self.queryStringParameters = dictionary["queryStringParameters"] as? [String: String] ?? [:]
            var hs = dictionary["headers"] as? [String: String] ?? [:]
            
            for (k, v) in lambdaHeaders {
                if let val = v as? String {
                    hs[k] = val
                }
            }
            self.headers = hs
            
            if let b = dictionary["body"] as? String {
                body = isBase64Encoded ? Data(base64Encoded: b) : b.data(using: .utf8)
            }
            else {
                body = nil
            }
        }
        else {
            return nil
        }
    }
    
    var vaporRequest: HTTPRequest {
        var c = URLComponents()
        c.host = "localhost"
        c.path = path
        c.scheme = "http"
        c.port = 8080
        
        if !queryStringParameters.isEmpty {
            c.queryItems = queryStringParameters.map { k, v in
                URLQueryItem(name: k, value: v)
            }
        }
        
        let method: HTTPMethod
        switch httpMethod.lowercased() {
        case "get":
            method = HTTPMethod.GET
        case "post":
            method = HTTPMethod.POST
        case "patch":
            method = HTTPMethod.PATCH
        case "put":
            method = HTTPMethod.PUT
        case "options":
            method = HTTPMethod.OPTIONS
        case "head":
            method = HTTPMethod.HEAD
        default:
            method = HTTPMethod.RAW(value: httpMethod)
        }
        
        let headerPairs = headers.map { $0 }
        return HTTPRequest(
            method: method,
            url: c.url!.absoluteString.replacingOccurrences(
                of: "http://localhost:8080",
                with: "",
                options: [],
                range: nil
            ),
            version: .init(major: 1, minor: 1),
            headers: HTTPHeaders(headerPairs),
            body: body ?? "".data(using: .utf8)!
        )
    }
}

struct LambdaHTTPResponse {
    
    let statusCode: UInt
    let body: String
    let headers: [String: String]
    
    var dictionary: [String: Any] {
        return [
            "statusCode": statusCode,
            "body":  body,
            "headers": headers
        ]
    }
    
}

extension Response {
    
    var lambdaResponse: LambdaHTTPResponse {
        return LambdaHTTPResponse(
            statusCode: http.status.code,
            body: http.body.data.map { String(data: $0, encoding: .utf8)! } ?? "",
            headers: Dictionary(uniqueKeysWithValues: http.headers.map { $0 })
        )
    }
    
}


public final class LambdaHTTPServer: Server, ServiceType, LambdaEventHandler {
    
    let container: Container
    let onClosePromise: EventLoopPromise<Void>
    var responder: Responder?
    
    init (container: Container) {
        self.container = container
        self.onClosePromise = container.eventLoop.newPromise(Void.self)
    }
    
    public func start(hostname: String?, port: Int?) -> EventLoopFuture<Void> {
        do {
            responder = try container.make(Responder.self)
            
            let logLevelStr = ProcessInfo.processInfo.environment["LOG_LEVEL"] ?? "info"
            let logLevel = BasicLambdaLoggerLevel(str: logLevelStr)
            let dispatcher = LambdaEventDispatcher(handler: self, logLevel: logLevel)
            _ = dispatcher.start()
            
            //kinda a hack to prevent the service from closing, works fine for lambdas
            return container.eventLoop.newPromise(of: Void.self).futureResult
        }
        catch let error {
            return container.eventLoop.newFailedFuture(error: error)
        }
        
    }
    
    
    public func handle(
        data: [String : Any],
        headers: [String : Any],
        eventLoopGroup: EventLoopGroup
    ) -> EventLoopFuture<[String : Any]> {
        do {
            let logger = LambdaLogger()
            logger.debug("data: \(data.debugDescription)")
            logger.debug("headers: \(headers.debugDescription)")
            var extraHeaders:[String : Any] = [:]
            
            //Add authorizer keys
            if  let requestContext = data["requestContext"] as? [String : Any],
                let authorizer = requestContext["authorizer"] as? [String : Any] {
                for (k, v) in authorizer {
                    extraHeaders["authorizer-\(k)"] = v
                }
            }
            
            //Add RAW header
            for (k, v) in headers {
                extraHeaders[k] = v
            }
            
            
            logger.debug("extra headers: \(extraHeaders.debugDescription)")
            if let r = responder, let httpRequest = LambdaHTTPRequest(dictionary: data, lambdaHeaders: extraHeaders) {
                let request = Request(http: httpRequest.vaporRequest, using: container)
                return try r.respond(to: request).map { $0.lambdaResponse.dictionary }
            }
            else {
                return container.eventLoop.newSucceededFuture(result:
                    LambdaHTTPResponse(
                        statusCode: 404,
                        body: "request not found",
                        headers: ["Content-Type": "text/plain"]
                    ).dictionary
                )
            }
        }
        catch let error {
            if let logger = try? container.make(Logger.self) {
                var s = ""
                print(error, to: &s)
                logger.error(s)
            }
            else {
                print(error)
            }
            return container.eventLoop.newSucceededFuture(result:
                LambdaHTTPResponse(
                    statusCode: 500,
                    body: "an unkown error has occurred",
                    headers: ["Content-Type": "text/plain"]
                ).dictionary
            )
        }
    }
    
    public static func makeService(for container: Container) throws -> LambdaHTTPServer {
        return LambdaHTTPServer(container: container)
    }
    
    public static var serviceSupports: [Any.Type] { return [Server.self] }
    
}
