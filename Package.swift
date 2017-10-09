// swift-tools-version:4.0

/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

import PackageDescription

let package = Package(
    name: "Baby",
    products: [
        .library(
            name: "BabyBrain",
            targets: ["BabyBrain"]),
        .executable(
            name: "baby",
            targets: ["Baby"]),
    ],
    targets: [
        .target(
            name: "BabyBrain"),
        .target(
            name: "Baby",
            dependencies: ["BabyBrain"]),
    ]
)
