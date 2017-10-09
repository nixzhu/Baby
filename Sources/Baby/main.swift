
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

import Foundation
import BabyBrain

func main(_ arguments: [String]) {
    let arguments = Arguments(arguments)
    let helpOption = Arguments.Option.Mixed(shortKey: "h", longKey: "help")
    func printVersion() {
        print("Version 0.29.0")
        print("Created by nixzhu with love.")
    }
    func printUsage() {
        print("Usage: $ baby -i JSONFilePath")
    }
    func printHelp() {
        print("-i, --input-file-path JSONFilePath")
        print("--public")
        print("--model-type ModelType")
        print("--model-name ModelName")
        print("--codable")
        print("--var")
        print("--json-dictionary-name JSONDictionaryName")
        print("--property-map \"foo: bar, not_used: _\"")
        print("--array-object-map \"skills: Skill, itemlist: Item\"")
        print("--property-type-map \"id: UInt64\"")
        print("--enum-properties \"type, gender[male, female, other: unknown]\"")
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
        let propertyMapOption = Arguments.Option.Long(key: "property-map")
        let propertyMapString = arguments.valueOfOption(propertyMapOption) ?? ""
        let propertyMap = map(of: propertyMapString)
        let arrayObjectMapOption = Arguments.Option.Long(key: "array-object-map")
        let arrayObjectMapString = arguments.valueOfOption(arrayObjectMapOption) ?? ""
        let arrayObjectMap = map(of: arrayObjectMapString)
        var removedKeySet: Set<String> = []
        for (key, value) in propertyMap {
            if value.isEmpty || value == "_" {
                removedKeySet.insert(key)
            }
        }
        let upgradedValue = value.upgraded(newName: modelName, arrayObjectMap: arrayObjectMap, removedKeySet: removedKeySet)
        let publicOption = Arguments.Option.Long(key: "public")
        let modelTypeOption = Arguments.Option.Long(key: "model-type")
        let codableOption = Arguments.Option.Long(key: "codable")
        let varOption = Arguments.Option.Long(key: "var")
        let jsonDictionaryNameOption = Arguments.Option.Long(key: "json-dictionary-name")
        let isPublic = arguments.containsOption(publicOption)
        let modelType = arguments.valueOfOption(modelTypeOption) ?? "struct"
        let codable = arguments.containsOption(codableOption)
        let declareVariableProperties = arguments.containsOption(varOption)
        let jsonDictionaryName = arguments.valueOfOption(jsonDictionaryNameOption) ?? "[String: Any]"
        let propertyTypeMapOption = Arguments.Option.Long(key: "property-type-map")
        let propertyTypeMapString = arguments.valueOfOption(propertyTypeMapOption) ?? ""
            let propertyTypeMap = map(of: propertyTypeMapString)
        let enumPropertiesOption = Arguments.Option.Long(key: "enum-properties")
        let enumPropertiesString = arguments.valueOfOption(enumPropertiesOption) ?? ""
        let enumProperties: [Meta.EnumProperty] = list(of: enumPropertiesString).map({ .init(name: $0, cases: $1) })
        let meta = Meta(
            isPublic: isPublic,
            modelType: modelType,
            codable: codable,
            declareVariableProperties: declareVariableProperties,
            jsonDictionaryName: jsonDictionaryName,
            propertyMap: propertyMap,
            arrayObjectMap: arrayObjectMap,
            propertyTypeMap: propertyTypeMap, 
            enumProperties: enumProperties
        )
        print(upgradedValue.swiftCode(meta: meta))
    } else {
        print("Invalid JSON!")
    }
}

main(CommandLine.arguments)
