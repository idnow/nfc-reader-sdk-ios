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
            url: "https://github.com/idnow/nfc-reader-sdk-ios/releases/download/1.5.3/NFCReader.xcframework.zip",
            checksum: "f804933b76fd32cd6e5e25e2075c2aa10c01e005f9382e1961647fb1956b5b3a"
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