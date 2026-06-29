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
            url: "https://github.com/idnow/nfc-reader-sdk-ios/releases/download/1.4.2/NFCReader.xcframework.zip",
            checksum: "5b7b2a1bf7686eb0ab8fe279f552e16b40691abd7a20f12acc8fe28d302da241"
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