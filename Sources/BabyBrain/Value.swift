
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

import Foundation

public enum Value {
    case empty
    indirect case null(optionalValue: Value?)
    case bool(value: Bool)
    public enum Number {
        case int(Int)
        case double(Double)
    }
    case number(value: Number)
    case string(value: String)
    indirect case object(name: String, dictionary: [String: Value], keys: [String])
    indirect case array(name: String, values: [Value])
    // hyper types
    case url(value: URL)
    public enum DateType {
        case iso8601
        case dateOnly
        case secondsSince1970
    }
    case date(type: DateType)
}

extension Value {
    public func prettyPrinted(indentation: Indentation = .default) -> String {
        switch self {
        case .empty: return "null"
        case .null(let optionalValue): return optionalValue?.prettyPrinted() ?? "null"
        case .bool(let value): return "\(value)"
        case .number(let value):
            switch value {
            case .int(let int): return "\(int)"
            case .double(let double): return "\(double)"
            }
        case .string(let value): return "\"\(value.escaped)\""
        case .object(_, let dictionary, let keys):
            var lines: [String] = ["{"]
            let properties = keys.map({ key in
                let value = dictionary[key]!
                return "\(indentation.deeper.value)\"\(key)\": \(value.prettyPrinted(indentation: indentation.deeper))"
            }).joined(separator: ",\n")
            lines.append(properties)
            lines.append("\(indentation.value)}")
            return lines.joined(separator: "\n")
        case .array(_, let values):
            var lines: [String] = ["["]
            let valueLines = values.map({ value in
                return indentation.deeper.value + value.prettyPrinted(indentation: indentation.deeper)
            }).joined(separator: ",\n")
            lines.append(valueLines)
            lines.append("\(indentation.value)]")
            return lines.joined(separator: "\n")
        case .url:
            return "@"
        case .date:
            return "$"
        }
    }
}

extension Value {
    private static func mergedValue(of values: [Value]) -> Value {
        if let first = values.first {
            return values.dropFirst().reduce(first, { $0.merge($1) })
        } else {
            return .empty
        }
    }

    private func merge(_ other: Value) -> Value {
        switch (self, other) {
        case (.empty, .empty):
            return .empty
        case (.empty, let valueB):
            return valueB
        case (let valueA, .empty):
            return valueA
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
            return .string(value: valueA + Meta.enumRawValueSeparator + valueB)
        case (let .object(nameA, dictionaryA, keysA), let .object(nameB, dictionaryB, keysB)):
            guard nameA == nameB else { fatalError("Unsupported object merge!") }
            var dictionary = dictionaryA
            for key in keysA {
                let valueA = dictionaryA[key]!
                if let valueB = dictionaryB[key] {
                    dictionary[key] = valueA.merge(valueB)
                } else {
                    dictionary[key] = valueA.isNull ? valueA : .null(optionalValue: valueA)
                }
            }
            for key in keysB {
                let valueB = dictionaryB[key]!
                if let valueA = dictionaryA[key] {
                    dictionary[key] = valueA.merge(valueB)
                } else {
                    dictionary[key] = valueB.isNull ? valueB : .null(optionalValue: valueB)
                }
            }
            var keys = keysA
            for key in keysB {
                if !keys.contains(key) {
                    keys.append(key)
                }
            }
            return .object(name: nameA, dictionary: dictionary, keys: keys)
        case (let .array(nameA, valuesA), let .array(nameB, valuesB)):
            guard nameA == nameB else { fatalError("Unsupported array merge!") }
            let value = Value.mergedValue(of: valuesA + valuesB)
            return .array(name: nameA, values: [value])
        case (let .url(valueA), .url):
            return .url(value: valueA)
        case (let .date(typeA), .date):
            return .date(type: typeA)
        case (.url, let .string(value)):
            return .string(value: value)
        case (let .string(value), .url):
            return .string(value: value)
        default:
            return .empty
        }
    }

    public func upgraded(newName: String, arrayObjectMap: [String: String], removedKeySet: Set<String>) -> Value {
        switch self {
        case let .number(value):
            switch value {
            case .int(let int):
                if let dateType = int.dateType {
                    return .date(type: dateType)
                } else {
                    return self
                }
            case .double(let double):
                if let dateType = double.dateType {
                    return .date(type: dateType)
                } else {
                    return self
                }
            }
        case let .string(value):
            if let url = URL(string: value), url.host != nil { // TODO: better url detect
                return .url(value: url)
            } else if let dateType = value.dateType {
                return .date(type: dateType)
            } else {
                return self
            }
        case let .object(_, dictionary, keys):
            var newDictionary: [String: Value] = [:]
            dictionary.forEach {
                if !removedKeySet.contains($0) {
                    newDictionary[$0] = $1.upgraded(newName: $0, arrayObjectMap: arrayObjectMap, removedKeySet: removedKeySet)
                }
            }
            var newKeys: [String] = []
            for key in keys {
                if !removedKeySet.contains(key) {
                    newKeys.append(key)
                }
            }
            return .object(name: newName, dictionary: newDictionary, keys: newKeys)
        case let .array(_, values):
            let newValues = values.map {
                $0.upgraded(newName: newName.singularForm(arrayObjectMap: arrayObjectMap), arrayObjectMap: arrayObjectMap, removedKeySet: removedKeySet)
            }
            let value = Value.mergedValue(of: newValues)
            return .array(name: newName, values: [value])
        default:
            return self
        }
    }
}

extension Value {
    func type(key: String, meta: Meta) -> String {
        if let type = meta.propertyTypeMap[key] {
            return type
        }
        switch self {
        case .empty:
            return "Any"
        case let .null(optionalValue):
            if let value = optionalValue {
                return value.type(key: key, meta: meta) + "?"
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
        case let .object(name, _, _):
            return name.type(meta: meta)
        case let .array(_, values):
            if let value = values.first {
                return "[" + value.type(key: key, meta: meta) + "]"
            } else {
                return "[Any]"
            }
        case .url:
            return "URL"
        case .date:
            return "Date"
        }
    }

    enum PropertyType {
        case normal(name: String)
        // Gender, Gender|Gender?|[Gender], String
        enum RawType: String {
            case string = "String"
            case int = "Int"
            case double = "Double"

            var string: String {
                return rawValue
            }
        }
        case `enum`(name: String, propertyType: String, rawType: RawType, rawValues: String)

        var name: String {
            switch self {
            case .normal(let name): return name
            case .enum(let name, _, _, _): return name
            }
        }
        var propertyType: String {
            switch self {
            case .normal(let name): return name
            case .enum(_, let propertyType, _, _): return propertyType
            }
        }
        var enumRawType: String {
            switch self {
            case .normal: fatalError()
            case .enum(_, _, let rawType, _): return rawType.string
            }
        }
    }

    func propertyType(key: String, meta: Meta, inArray: Bool = false) -> PropertyType {
        if meta.contains(enumPropertyKey: key) {
            var rawValues: String = ""
            if case .string(let _rawValues) = self {
                rawValues = _rawValues
            }
            if case .array(_, let values) = self {
                var _rawValues: [String] = []
                for value in values {
                    if case .string(let rawValue) = value {
                        _rawValues.append(rawValue)
                    }
                }
                rawValues = _rawValues.joined(separator: Meta.enumRawValueSeparator)
            }
            var name: String
            let propertyType: String
            let ckey = key.type(meta: meta)
            var baseValue: Value?
            switch self {
            case .null(let optionalValue):
                name = ckey
                propertyType = "\(ckey)?"
                baseValue = optionalValue
            case .array(_, let values):
                name = ckey.singularForm(meta: meta)
                propertyType = "[\(ckey.singularForm(meta: meta))]"
                baseValue = values.first
            default:
                if inArray {
                    name = ckey.singularForm(meta: meta)
                    propertyType = ckey.singularForm(meta: meta)
                } else {
                    name = ckey
                    propertyType = ckey
                }
                baseValue = self
            }
            if Meta.swiftKeywords.contains(name) {
                name = "`\(name)`"
            }
            let rawType: PropertyType.RawType
            if let baseValue = baseValue {
                switch baseValue {
                case .string:
                    rawType = .string
                case .number(let value):
                    switch value {
                    case .int:
                        rawType = .int
                    case .double:
                        rawType = .double
                    }
                default:
                    rawType = .string
                }
            } else {
                rawType = .string
            }
            return .enum(name: name, propertyType: propertyType, rawType: rawType, rawValues: rawValues)
        } else {
            return .normal(name: type(key: key, meta: meta))
        }
    }
}

extension Value {
    var isNull: Bool {
        switch self {
        case .null:
            return true
        default:
            return false
        }
    }

    var isArray: Bool {
        switch self {
        case .array:
            return true
        default:
            return false
        }
    }
}

extension String {
    func singularForm(meta: Meta) -> String {
        return singularForm(arrayObjectMap: meta.arrayObjectMap)
    }
    func singularForm(arrayObjectMap: [String: String]) -> String { // TODO: better singularForm
        if let name = arrayObjectMap[self] {
            return name
        } else {
            if self.count > 4 && hasSuffix("list") {
                return String(dropLast(4))
            } else if self.count > 1 && hasSuffix("s") {
                return String(dropLast())
            } else {
                return self
            }
        }
    }

    var detectedType: String {
        let string = self
            .replacingOccurrences(of: "-", with: "_")
            .components(separatedBy: "_")
            .map({ $0.capitalizingFirstLetter() })
            .joined()
            .capitalizingFirstLetter()
        if isNumber(string) {
            return "_" + string
        } else {
            return string
        }
    }

    func type(meta: Meta, needSingularForm: Bool = false) -> String { // TODO: better type
        if let type = meta.propertyTypeMap[self] {
            return needSingularForm ? type.singularForm(meta: meta) : type
        } else {
            let type = detectedType
            return needSingularForm ? type.singularForm(meta: meta) : type
        }
    }

    func propertyName(meta: Meta) -> String {
        if let propertyName = meta.propertyMap[self] {
            return propertyName
        } else if Meta.swiftKeywords.contains(self) {
            return "`\(self)`"
        } else {
            return detectedType.lowercasingFirstLetter()
        }
    }

    func removedQuotationMark() -> String {
        return self.trimmingCharacters(in: CharacterSet(charactersIn: "`"))
    }

    func capitalizingFirstLetter() -> String {
        if let first = first {
            return String(first).uppercased() + String(dropFirst())
        } else {
            return self
        }
    }

    func lowercasingFirstLetter() -> String {
        if let first = first {
            return String(first).lowercased() + String(dropFirst())
        } else {
            return self
        }
    }
}

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        return formatter
    }()

    static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension String {
    var dateType: Value.DateType? {
        if DateFormatter.iso8601.date(from: self) != nil {
            return .iso8601
        }
        if DateFormatter.dateOnly.date(from: self) != nil {
            return .dateOnly
        }
        return nil
    }
    var escaped: String {
        var string = self
        string = string.replacingOccurrences(of: "\"", with: "\\\"")
        string = string.replacingOccurrences(of: "\\", with: "\\\\")
        string = string.replacingOccurrences(of: "\n", with: "\\n")
        string = string.replacingOccurrences(of: "\r", with: "\\r")
        string = string.replacingOccurrences(of: "\t", with: "\\t")
        return string
    }
}

extension Int {
    var dateType: Value.DateType? {
        if self >= 1000000000 {
            return .secondsSince1970
        }
        return nil
    }
}

extension Double {
    var dateType: Value.DateType? {
        if self >= 1000000000 {
            return .secondsSince1970
        }
        return nil
    }
}
