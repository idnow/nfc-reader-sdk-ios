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
            url: "https://github.com/idnow/nfc-reader-sdk-ios/releases/download/1.5.2/NFCReader.xcframework.zip",
            checksum: "6282bb7c9263b264154cee65f64d12f228827461a2c16bf3b92d746b19d91ce4"
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