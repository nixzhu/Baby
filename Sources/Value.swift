
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
            let newValues = values.map { $0.upgraded(newName: newName.propertyNameFromValue) }
            let value = Value.mergedValue(of: newValues)
            return .array(name: newName, values: [value])
        default:
            return self
        }
    }
}

extension String {

    fileprivate var propertyNameFromValue: String {
        return String(self.characters.dropLast()) // TODO: better propertyNameFromValue
    }

    fileprivate var type: String {
        return self.capitalized.components(separatedBy: "_").joined(separator: "")
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

    var type: String {
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

    struct Indentation {
        let level: Int
        let unit: String
        static var `default`: Indentation {
            return Indentation(level: 0, unit: "    ")
        }
        var value: String {
            return String(repeating: unit, count: level)
        }
        var value1: String {
            return String(repeating: unit, count: level + 1)
        }
        var deeper: Indentation {
            return Indentation(level: level + 1, unit: unit)
        }
    }

    func structCode(indentation: Indentation = Indentation.default) -> String {
        let indent = indentation.value
        let indent1 = indentation.value1
        switch self {
        case let .object(name, dictionary):
            var lines: [String] = ["\(indent)struct \(name.type) {"]
            for (key, value) in dictionary {
                lines.append(value.structCode(indentation: indentation.deeper))
                lines.append("\(indent1)let \(key.propertyName): \(value.type) ")
            }
            lines.append("\(indent)}")
            return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
        case let .array(_, values):
            return values.first?.structCode(indentation: indentation) ?? ""
        default:
            break
        }
        return ""
    }
}
