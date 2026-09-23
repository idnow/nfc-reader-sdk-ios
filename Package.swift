// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "NFCReader",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "NFCReaderLibrary",
            targets: ["NFCReaderWrapper"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/idnow/openssl-sdk-ios.git", exact: "3.6.1")
    ],
    targets: [
        .binaryTarget(
            name: "NFCReaderLibrary",
            url: "https://github.com/idnow/nfc-reader-sdk-ios/releases/download/1.5.0/NFCReader.xcframework.zip",
            checksum: "456b9e9b70863e92ab27f52e553949b3f9b6b8cf8f2c5b9021e26fc206569247"
        ),
        .target(
             // Main target which contains both NFCReader and the OpenSSL dependency. Automatically downloaded when client fetch NFCReader.
            name: "NFCReaderWrapper",
            dependencies: [
                "NFCReaderLibrary",
                .product(name: "OpenSSL", package: "openssl-sdk-ios")
            ],
            path: "sources"
        )
    ]
)