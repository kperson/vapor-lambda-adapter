// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "vapor-lambda-adapter",
    products: [
        .library(name: "VaporLambdaAdapter", targets: ["Adapter"])
    ],
    dependencies: [
        .package(url: "https://github.com/kperson/swift-aws-lambda-adapter.git", .branch("master")),
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMinor(from: "3.3.0"))
    ],
    targets: [
        .target(
            name: "Adapter", 
            dependencies: ["Vapor", "AWSLambdaAdapter"],
            path: "./Sources"
        )
    ]
)
