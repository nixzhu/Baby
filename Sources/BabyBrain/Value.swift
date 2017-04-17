
import Foundation

public enum Value {
    indirect case null(optionalValue: Value?)
    case bool(value: Bool)
    public enum Number {
        case int(Int)
        case double(Double)
    }
    case number(value: Number)
    case string(value: String)
    indirect case object(name: String, dictionary: [String: Value])
    indirect case array(name: String, values: [Value])
    // hyper type
    case url(value: URL)
}

extension Value {

    private static func mergedValue(of values: [Value]) -> Value {
        if let first = values.first {
            return values.dropFirst().reduce(first, { $0.merge($1) })
        } else {
            return .null(optionalValue: nil)
        }
    }

    private func merge(_ other: Value) -> Value {
        switch (self, other) {
        case (let .null(optionalValueA), let .null(optionalValueB)):
            switch (optionalValueA, optionalValueB) {
            case (.some(let a), .some(let b)):
                return .null(optionalValue: a.merge(b))
            case (.some(let a), .none):
                return .null(optionalValue: a)
            case (.none, .some(let b)):
                return .null(optionalValue: b)
            case (.none, .none):
                return .null(optionalValue: nil)
            }
        case (let .null(optionalValue), let valueB):
            if let valueA = optionalValue {
                return .null(optionalValue: .some(valueA.merge(valueB)))
            } else {
                return .null(optionalValue: .some(valueB))
            }
        case (let valueA, let .null(optionalValue)):
            if let valueB = optionalValue {
                return .null(optionalValue: .some(valueB.merge(valueA)))
            } else {
                return .null(optionalValue: .some(valueA))
            }
        case (let .bool(valueA), let .bool(valueB)):
            return .bool(value: valueA && valueB)
        case (let .number(valueA), let .number(valueB)):
            var newValue = valueA
            if case .double(_) = valueB {
                newValue = valueB
            }
            return .number(value: newValue)
        case (let .string(valueA), let .string(valueB)):
            let value = valueA.isEmpty ? valueB : valueA
            return .string(value: value)
        case (let .object(nameA, dictionaryA), let .object(nameB, dictionaryB)):
            guard nameA == nameB else { fatalError("Unsupported object merge!") }
            var dictionary = dictionaryA
            for key in dictionaryA.keys {
                let valueA = dictionaryA[key]!
                if let valueB = dictionaryB[key] {
                    dictionary[key] = valueA.merge(valueB)
                } else {
                    dictionary[key] = .null(optionalValue: valueA)
                }
            }
            for key in dictionaryB.keys {
                let valueB = dictionaryB[key]!
                if let valueA = dictionaryA[key] {
                    dictionary[key] = valueB.merge(valueA)
                } else {
                    dictionary[key] = .null(optionalValue: valueB)
                }
            }
            return .object(name: nameA, dictionary: dictionary)
        case (let .array(nameA, valuesA), let .array(nameB, valuesB)):
            guard nameA == nameB else { fatalError("Unsupported array merge!") }
            let value = Value.mergedValue(of: valuesA + valuesB)
            return .array(name: nameA, values: [value])
        case (.url(let valueA), .url):
            return .url(value: valueA)
        default:
            fatalError("Unsupported merge!")
        }
    }

    public func upgraded(newName: String) -> Value {
        switch self {
        case .string(value: let value):
            if let url = URL(string: value), url.host != nil {
                return .url(value: url)
            } else {
                return self
            }
        case .object(name: _, dictionary: let dictionary):
            var newDictionary: [String: Value] = [:]
            dictionary.forEach { newDictionary[$0] = $1.upgraded(newName: $0) }
            return .object(name: newName, dictionary: newDictionary)
        case .array(name: _, values: let values):
            let newValues = values.map { $0.upgraded(newName: newName.singularForm) }
            let value = Value.mergedValue(of: newValues)
            return .array(name: newName, values: [value])
        default:
            return self
        }
    }
}

extension String {

    fileprivate var singularForm: String {
        return String(self.characters.dropLast()) // TODO: better singularForm
    }

    fileprivate var type: String {
        return self.capitalized.components(separatedBy: "_").joined(separator: "") // TODO: better type
    }

    fileprivate var propertyName: String {
        let characters = type.characters
        if let first = characters.first {
            return String(first).lowercased() + String(characters.dropFirst())
        } else {
            return self
        }
    }
}

extension Value {

    fileprivate var type: String {
        switch self {
        case let .null(optionalValue):
            if let value = optionalValue {
                return value.type + "?"
            } else {
                return "Any?"
            }
        case .bool:
            return "Bool"
        case let .number(value):
            switch value {
            case .int:
                return "Int"
            case .double:
                return "Double"
            }
        case .string:
            return "String"
        case let .object(name, _):
            return name.type
        case let .array(_, values):
            if let value = values.first {
                return "[" + value.type + "]"
            } else {
                return "[Any]"
            }
        case .url:
            return "URL"
        }
    }
}

extension Value {

    private func initializerCode(indentation: Indentation) -> String {
        let indent = indentation.value
        let indent1 = indentation.deeper.value
        var lines: [String] = []
        switch self {
        case let .object(_, dictionary):
            let arguments = dictionary.map({ "\($0.propertyName): \($1.type)" }).joined(separator: ", ")
            lines.append("\(indent)init(\(arguments)) {")
            for (key, _) in dictionary {
                let propertyName = key.propertyName
                lines.append("\(indent1)self.\(propertyName) = \(propertyName)")
            }
        default:
            break
        }
        lines.append("\(indent)}")
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func optionalInitialCodeInArray(indentation: Indentation, name: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case .null:
            lines.append("\(indent)let \(name.propertyName) = json[\"\(name)\"] as? [Any?]")
        case .bool, .number, .string:
            lines.append("\(indent)let \(name.propertyName) = json[\"\(name)\"] as? [\(self.type)]")
        case .object:
            let jsonArray = "\(name.propertyName)JSONArray"
            lines.append("\(indent)let \(jsonArray) = json[\"\(name)\"] as? [[String: Any]]")
            lines.append("\(indent)let \(name.propertyName) = \(jsonArray).flatMap({ \(name.singularForm.type)(json: $0) }).flatMap({ $0 })")
        case .array:
            fatalError("Unsupported array in array!")
        case .url:
            let urlStrings = "\(name.propertyName)Strings"
            lines.append("\(indent)let \(urlStrings) = json[\"\(name)\"] as? [String]")
            lines.append("\(indent)let \(name.propertyName) = \(urlStrings).flatMap({ URL(string: $0)! })")
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func optionalInitialCode(indentation: Indentation, key: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case .null:
            lines.append("\(indent)let \(key.propertyName) = json[\"key\"]")
        case .bool, .number, .string:
            lines.append("\(indent)let \(key.propertyName) = json[\"\(key)\"] as? \(self.type)")
        case let .object(name, _):
            let jsonDictionary = "\(name.propertyName)JSONDictionary"
            lines.append("\(indent)let \(jsonDictionary) = json[\"\(name)\"] as? [String: Any]")
            lines.append("\(indent)let \(name.propertyName) = \(jsonDictionary).flatMap({ \(name.type)(json: $0) })")
        case let .array(name, values):
            if let value = values.first {
                lines.append(value.optionalInitialCodeInArray(indentation: indentation, name: name))
            } else {
                lines.append("\(indent)guard let \(name.propertyName) = json[\"\(name)\"] as? [Any] else { return nil }")
            }
        case .url:
            let urlString = "\(key.propertyName)String"
            lines.append("\(indent)let \(urlString) = json[\"\(key)\"] as? String")
            lines.append("\(indent)let \(key.propertyName) = \(urlString).flatMap({ URL(string: $0) })")
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func initialCodeInArray(indentation: Indentation, name: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case .null:
            lines.append("\(indent)guard let \(name.propertyName) = json[\"\(name)\"] as? [Any] else { return nil }")
        case .bool, .number, .string:
            lines.append("\(indent)guard let \(name.propertyName) = json[\"\(name)\"] as? [\(self.type)] else { return nil }")
        case .object:
            let jsonArray = "\(name.propertyName)JSONArray"
            lines.append("\(indent)guard let \(jsonArray) = json[\"\(name)\"] as? [[String: Any]] else { return nil }")
            lines.append("\(indent)let \(name.propertyName) = \(jsonArray).map({ \(name.singularForm.type)(json: $0) }).flatMap({ $0 })")
        case .array:
            fatalError("Unsupported array in array!")
        case .url:
            let urlStrings = "\(name.propertyName)Strings"
            lines.append("\(indent)guard let \(urlStrings) = json[\"\(name)\"] as? [String] else { return nil }")
            lines.append("\(indent)let \(name.propertyName) = \(urlStrings).map({ URL(string: $0) }).flatMap({ $0 })")
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func initialCode(indentation: Indentation, key: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case let .null(optionalValue):
            if let value = optionalValue {
                lines.append(value.optionalInitialCode(indentation: indentation, key: key))
            } else {
                lines.append("\(indent)let \(key.propertyName) = json[\"\(key)\"]")
            }
        case .bool, .number, .string:
            lines.append("\(indent)guard let \(key.propertyName) = json[\"\(key)\"] as? \(self.type) else { return nil }")
        case let .object(name, _):
            let jsonDictionary = "\(name.propertyName)JSONDictionary"
            lines.append("\(indent)guard let \(jsonDictionary) = json[\"\(name)\"] as? [String: Any] else { return nil }")
            lines.append("\(indent)guard let \(name.propertyName) = \(name.type)(json: \(jsonDictionary)) else { return nil }")
        case let .array(name, values):
            if let value = values.first {
                lines.append(value.initialCodeInArray(indentation: indentation, name: name))
            } else {
                lines.append("\(indent)guard let \(name.propertyName) = json[\"\(name)\"] as? [Any] else { return nil }")
            }
        case .url:
            let urlString = "\(key.propertyName)String"
            lines.append("\(indent)guard let \(urlString) = json[\"\(key)\"] as? String else { return nil }")
            lines.append("\(indent)guard let \(key.propertyName) = URL(string: \(urlString)) else { return nil }")
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func failableInitializerCode(indentation: Indentation) -> String {
        let indent = indentation.value
        let indent1 = indentation.deeper.value
        var lines: [String] = []
        switch self {
        case let .object(_, dictionary):
            lines.append("\(indent)init?(json: [String: Any]) {")
            for (key, value) in dictionary {
                lines.append(value.initialCode(indentation: indentation.deeper, key: key))
            }
            let arguments = dictionary.keys.map({ "\($0.propertyName): \($0.propertyName)" }).joined(separator: ", ")
            lines.append("\(indent1)self.init(\(arguments))")
        default:
            break
        }
        lines.append("\(indent)}")
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    public func structCode(indentation: Indentation = Indentation.default) -> String {
        let indent = indentation.value
        let indent1 = indentation.deeper.value
        switch self {
        case let .object(name, dictionary):
            var lines: [String] = ["\(indent)struct \(name.type) {"]
            for (key, value) in dictionary {
                lines.append(value.structCode(indentation: indentation.deeper))
                lines.append("\(indent1)let \(key.propertyName): \(value.type) ")
            }
            lines.append(self.initializerCode(indentation: indentation.deeper))
            lines.append(self.failableInitializerCode(indentation: indentation.deeper))
            lines.append("\(indent)}")
            return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
        case let .array(_, values):
            return values.first?.structCode(indentation: indentation) ?? ""
        default:
            return ""
        }
    }
}