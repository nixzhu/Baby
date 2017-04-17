
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

import PackageDescription

let package = Package(
    name: "Baby",
    targets: [
        Target(
            name: "Baby",
            dependencies: ["BabyBrain"]
        ),
        Target(name: "BabyBrain")
    ]
)
