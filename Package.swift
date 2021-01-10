// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "vapor-lambda-adapter",
    products: [
        .library(name: "VaporLambdaAdapter", targets: ["VaporLambdaAdapter"])
    ],
    dependencies: [
        .package(url: "https://github.com/kperson/swift-aws-lambda-adapter.git", .upToNextMinor(from: "1.0.0")),
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMinor(from: "3.3.0"))
    ],
    targets: [
        .target(
            name: "VaporLambdaAdapter", 
            dependencies: ["Vapor", "AWSLambdaAdapter"],
            path: "./Sources"
        )
    ]
)
