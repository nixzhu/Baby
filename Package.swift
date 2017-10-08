// swift-tools-version:4.0

/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

import PackageDescription

let package = Package(
    name: "Baby",
    products: [
        .executable(
            name: "baby",
            targets: ["Baby"])
    ],
    targets: [
        .target(
            name: "Baby",
            dependencies: ["BabyBrain"]
        ),
        .target(name: "BabyBrain")
    ]
)
