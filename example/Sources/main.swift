//MAC TIP: brew install libressl

import Vapor
import VaporLambdaAdapter

VaporLambdaHTTP.configure()


let runAsLambda = ProcessInfo.processInfo.environment["MODE"] == "lambda"
let app = try Application(runAsLambda: runAsLambda)
let router = try app.make(Router.self)

struct CurrentTime: Content {
    var unix: TimeInterval
    var greeting: String
}


router.get("hello") { req in
    return CurrentTime(
        unix: Date().timeIntervalSince1970,
        greeting: "hello"
    )
}

try app.run()
