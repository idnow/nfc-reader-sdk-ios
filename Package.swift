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
            url: "https://github.com/idnow/nfc-reader-sdk-ios/releases/download/1.5.1/NFCReader.xcframework.zip",
            checksum: "3a1c9e81282a96868cbb3c3b70a3d37fa55ab852cde0ea83ddffe8cf592a9f59"
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