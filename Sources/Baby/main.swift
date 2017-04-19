
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

import Foundation
import BabyBrain

func main(_ arguments: [String]) {
    let arguments = Arguments(arguments)
    let helpOption = Arguments.Option.Mixed(shortKey: "h", longKey: "help")
    func printVersion() {
        print("Version 0.3.0")
        print("Created by nixzhu with love.")
    }
    func printUsage() {
        print("Usage: $ baby -i JSONFilePath")
    }
    func printHelp() {
        print("-i (--input-file-path) JSONFilePath")
        print("-h (--help)")
        print("-v (--version)")
    }
    if arguments.containsOption(helpOption) {
        print("Create models from a JSON file, even a Baby can do it.")
        printHelp()
        printVersion()
        return
    }
    let versionOption = Arguments.Option.Mixed(shortKey: "v", longKey: "version")
    if arguments.containsOption(versionOption) {
        printVersion()
        return
    }
    let inputFilePathOption = Arguments.Option.Mixed(shortKey: "i", longKey: "input-file-path")
    guard let inputFilePath = arguments.valueOfOption(inputFilePathOption) else {
        printUsage()
        printVersion()
        return
    }
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: inputFilePath) else {
        print("File NOT found at `\(inputFilePath)`!")
        return
    }
    guard fileManager.isReadableFile(atPath: inputFilePath) else {
        print("No permission to read file at `\(inputFilePath)`!")
        return
    }
    guard let data = fileManager.contents(atPath: inputFilePath) else {
        print("File is empty!")
        return
    }
    guard let jsonString = String(data: data, encoding: .utf8) else {
        print("File is NOT encoding with UTF8!")
        return
    }
    if let (value, _) = parse(jsonString) {
        let upgradedValue = value.upgraded(newName: "MyModel")
        print(upgradedValue.swiftStructCode())
    } else {
        print("Invalid JSON!")
    }
}

main(CommandLine.arguments)
