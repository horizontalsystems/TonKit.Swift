// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TonKit",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "TonKit",
            targets: ["TonKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Kitura/BlueSocket.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/groue/GRDB.swift.git", .upToNextMajor(from: "6.0.0")),
        .package(url: "https://github.com/tristanhimmelman/ObjectMapper.git", .upToNextMajor(from: "4.1.0")),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.21.0"),
        .package(url: "https://github.com/tonkeeper/ton-api-swift.git", .upToNextMajor(from: "0.3.1")),
        .package(url: "https://github.com/tonkeeper/ton-swift.git", .upToNextMajor(from: "1.0.16")),
        .package(url: "https://github.com/horizontalsystems/HsCryptoKit.Swift.git", .upToNextMajor(from: "1.2.1")),
        .package(url: "https://github.com/horizontalsystems/HsToolKit.Swift.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/horizontalsystems/HsExtensions.Swift.git", .upToNextMajor(from: "1.0.6")),
    ],
    targets: [
        .target(
            name: "TonKit",
            dependencies: [
                "BigInt",
                .product(name: "Socket", package: "BlueSocket"),
                .product(name: "GRDB", package: "GRDB.swift"),
                "ObjectMapper",
                .product(name: "TonAPI", package: "ton-api-swift"),
                .product(name: "StreamURLSessionTransport", package: "ton-api-swift"),
                .product(name: "TonStreamingAPI", package: "ton-api-swift"),
                .product(name: "EventSource", package: "ton-api-swift"),
                .product(name: "TonSwift", package: "ton-swift"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "HsCryptoKit", package: "HsCryptoKit.Swift"),
                .product(name: "HsToolKit", package: "HsToolKit.Swift"),
                .product(name: "HsExtensions", package: "HsExtensions.Swift"),
            ]
        ),
    ]
)
