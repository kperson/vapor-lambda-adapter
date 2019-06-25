// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "VaporApp",
    products: [
        .library(
            name: "app",
            targets: ["VaporApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kperson/vapor-lambda-adapter.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "VaporApp",
            dependencies: ["VaporLambdaAdapter"],
            path: "./Sources"
        )
    ]
)
 
