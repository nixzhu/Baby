
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

import PackageDescription

let package = Package(
    name: "_Baby",
    targets: [
        Target(
            name: "_Baby",
            dependencies: ["BabyBrain"]
        ),
        Target(name: "BabyBrain")
    ]
)
