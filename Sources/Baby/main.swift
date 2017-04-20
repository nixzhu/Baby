
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

import Foundation
import BabyBrain

func main(_ arguments: [String]) {
    let arguments = Arguments(arguments)
    let helpOption = Arguments.Option.Mixed(shortKey: "h", longKey: "help")
    func printVersion() {
        print("Version 0.5.0")
        print("Created by nixzhu with love.")
    }
    func printUsage() {
        print("Usage: $ baby -i JSONFilePath")
    }
    func printHelp() {
        print("-i, --input-file-path JSONFilePath")
        print("--model-name ModelName")
        print("--public")
        print("--json-dictionary-name JSONDictionaryName")
        print("-h, --help")
        print("-v, --version")
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
        let modelNameOption = Arguments.Option.Long(key: "model-name")
        let modelName = arguments.valueOfOption(modelNameOption) ?? "MyModel"
        let upgradedValue = value.upgraded(newName: modelName)
        let publicOption = Arguments.Option.Long(key: "public")
        let jsonDictionaryNameOption = Arguments.Option.Long(key: "json-dictionary-name")
        let isPublic = arguments.containsOption(publicOption)
        let jsonDictionaryName = arguments.valueOfOption(jsonDictionaryNameOption) ?? "[String: Any]"
        let meta = Meta(isPublic: isPublic, jsonDictionaryName: jsonDictionaryName)
        print(upgradedValue.swiftStructCode(meta: meta))
    } else {
        print("Invalid JSON!")
    }
}

main(CommandLine.arguments)
