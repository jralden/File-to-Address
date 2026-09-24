// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FileToAddress",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "FileToAddress",
            path: "src/FileToAddress",
            linkerSettings: [.linkedFramework("Carbon")]
        ),
        .testTarget(
            name: "FileToAddressTests",
            dependencies: ["FileToAddress"],
            path: "tests/FileToAddressTests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
