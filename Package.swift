
import PackageDescription

let package = Package(
    name: "baby",
    targets: [
        Target(
            name: "baby",
            dependencies: ["BabyBrain"]
        ),
        Target(name: "BabyBrain")
    ]
)

