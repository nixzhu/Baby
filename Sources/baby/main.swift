
import Foundation
import BabyBrain

func main(_ arguments: [String]) {
    let arguments = Arguments(arguments)
    let inputFilePathOption = Arguments.Option.Mixed(shortKey: "i", longKey: "input-file-path")
    guard let inputFilePath = arguments.valueOfOption(inputFilePathOption) else {
        print("Usage: $ baby -i JSONFilePath")
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
        let upgradedValue = value.upgraded(newName: "Model")
        print(upgradedValue.swiftStructCode())
    } else {
        print("Invalid JSON!")
    }
}

main(CommandLine.arguments)
