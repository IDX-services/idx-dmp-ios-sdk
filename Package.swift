// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "idx-dmp-ios-sdk",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "idx-dmp-ios-sdk",
            targets: ["idx-dmp-ios-sdk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift.git", exact: "10.33.0"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "9.9.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "idx-dmp-ios-sdk",
            dependencies: [
                .product(name: "RealmSwift", package: "realm-swift"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            path: "IdxDmpSdk"),
             
    ]
)
