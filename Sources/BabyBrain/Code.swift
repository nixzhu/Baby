
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

import Foundation

enum Primitive {
    case bool
    case int
    case double
    case string
    case url
    case date(type: Value.DateType)
    case any
    indirect case null(PlainType)
}

enum PlainType {
    case primitive(Primitive)
    case `struct`(Struct)
    case `enum`(Enum)
}

struct Type {
    let plainType: PlainType
    enum Status {
        case normal
        case isOptional
        case inArray
    }
    let status: Status
}

struct Property {
    let name: String
    let type: Type
}

struct Struct {
    let name: String
    let properties: [Property]
}

struct Enum {
    let name: String
    let primitive: Primitive
    struct Case {
        let name: String
        enum RawValue {
            case string(String)
            case int(Int)
            case double(Double)
        }
        let rawValue: RawValue?
    }
    let cases: [Case]
}

enum Code {
    case type(Type)
    case property(Property)
    case `struct`(Struct)
    case `enum`(Enum)

    var plainType: PlainType {
        switch self {
        case let .type(type):
            return type.plainType
        case let .property(property):
            return property.type.plainType
        case let .struct(s):
            return .struct(s)
        case let .enum(e):
            return .enum(e)
        }
    }
}

extension Value {

    var status: Type.Status {
        switch self {
        case .null:
            return .isOptional
        case .array:
            return .inArray
        default:
            return .normal
        }
    }
}

extension Code {
    static func create(name: String, value: Value, meta: Meta) -> Code {
        switch value {
        case .empty:
            let property = Property(
                name: name,
                type: Type(plainType: .primitive(.any), status: .normal)
            )
            return .property(property)
        case let .null(optionalValue):
            if let value = optionalValue {
                let code = create(name: name, value: value, meta: meta)
                let type = Type(plainType: .primitive(.null(code.plainType)), status: .isOptional)
                let property = Property(
                    name: name,
                    type: type
                )
                return .property(property)
            } else {
                let property = Property(
                    name: name,
                    type: Type(plainType: .primitive(.any), status: .isOptional)
                )
                return .property(property)
            }
        case .bool:
            let property = Property(
                name: name,
                type: Type(plainType: .primitive(.bool), status: .normal)
            )
            return .property(property)
        case let .number(number):
            if meta.contains(enumPropertyKey: name) {
                let cases: [Enum.Case] = (meta.enumCases(key: name) ?? []).map {
                    let rawValue = $0.rawValue.flatMap {
                        Enum.Case.RawValue.string($0)
                    }
                    return Enum.Case(name: $0.name, rawValue: rawValue)
                }
                let e: Enum
                switch number {
                case .int:
                    e = Enum(name: name, primitive: .int, cases: cases)
                case .double:
                    e = Enum(name: name, primitive: .double, cases: cases)
                }
                let property = Property(
                    name: name,
                    type: Type(plainType: .enum(e), status: .normal)
                )
                return .property(property)
            } else {
                let property: Property
                switch number {
                case .int:
                    property = Property(
                        name: name,
                        type: Type(plainType: .primitive(.int), status: .normal)
                    )
                case .double:
                    property = Property(
                        name: name,
                        type: Type(plainType: .primitive(.double), status: .normal)
                    )
                }
                return .property(property)
            }
        case .string(let rawValuesString):
            if meta.contains(enumPropertyKey: name) {
                let cases: [Enum.Case]
                if let _cases = meta.enumCases(key: name) {
                    cases = _cases.map {
                        let rawValue = $0.rawValue.flatMap {
                            Enum.Case.RawValue.string($0)
                        }
                        return Enum.Case(name: $0.name, rawValue: rawValue)
                    }
                } else {
                    let rawValues = rawValuesString.components(separatedBy: Meta.enumRawValueSeparator)
                    cases = rawValues.map {
                        let rawValue = Enum.Case.RawValue.string($0)
                        return Enum.Case(name: $0.propertyName(meta: meta), rawValue: rawValue)
                    }
                }
                let e = Enum(name: name, primitive: .string, cases: cases)
                let property = Property(
                    name: name,
                    type: Type(plainType: .enum(e), status: .normal)
                )
                return .property(property)
            } else {
                let property = Property(
                    name: name,
                    type: Type(plainType: .primitive(.string), status: .normal)
                )
                return .property(property)
            }
        case let .object(name, dictionary, keys):
            let properties: [Property] = keys.map {
                let value = dictionary[$0]!
                let code = create(name: $0, value: value, meta: meta)
                let property = Property(
                    name: $0,
                    type: Type(plainType: code.plainType, status: value.status)
                )
                return property
            }
            let `struct` = Struct(name: name, properties: properties)
            return .struct(`struct`)
        case let .array(name, values):
            if let value = values.first {
                let code = create(name: name, value: value, meta: meta)
                let type = Type(plainType: code.plainType, status: .inArray)
                return .type(type)
            } else {
                let type = Type(plainType: .primitive(.any), status: .inArray)
                return .type(type)
            }
        case .url:
            let property = Property(
                name: name,
                type: Type(plainType: .primitive(.url), status: .normal)
            )
            return .property(property)
        case let .date(type):
            let property = Property(
                name: name,
                type: Type(plainType: .primitive(.date(type: type)), status: .normal)
            )
            return .property(property)
        }
    }
}

extension Primitive {

    var name: String {
        switch self {
        case .bool: return "Bool"
        case .int: return "Int"
        case .double: return "Double"
        case .string: return "String"
        case .url: return "URL"
        case .date: return "Date"
        case .any: return "Any"
        case let .null(plainType): return plainType.name + "?"
        }
    }
}

extension PlainType {

    var name: String {
        switch self {
        case let .primitive(p): return p.name
        case let .struct(s): return s.name
        case let .enum(e): return e.name
        }
    }
}

extension Type {

    var name: String {
        let _name: String
        switch plainType {
        case let .primitive(p):
            _name = p.name
        case let .struct(s):
            _name = s.typeName
        case let .enum(e):
            _name = e.typeName
        }
        switch status {
        case .normal: return _name
        case .isOptional:
            if _name.hasSuffix("?") {
                return _name
            } else {
                return _name + "?"
            }
        case .inArray: return "[" + _name + "]"
        }
    }
}

extension Property {

    func definition(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        var lines: [String] = []
        lines.append("\(indent)\(meta.declareKeyword) \(name.propertyName(meta: meta)): \(type.name)")
        return lines.joined(separator: "\n")
    }

    func nestedDefinition(indentation: Indentation = .default, meta: Meta = .default) -> String? {
        var lines: [String] = []
        switch type.plainType {
        case .primitive:
            break
        case let .struct(s):
            lines.append(s.definition(indentation: indentation.deeper, meta: meta))
        case let .enum(e):
            lines.append(e.definition(indentation: indentation.deeper, meta: meta))
        }
        if lines.isEmpty {
            return nil
        } else {
            return lines.joined(separator: "\n")
        }
    }
}

extension Struct {

    var typeName: String {
        return name.type
    }

    func codingKeysEnum(indentation: Indentation, meta: Meta) -> String? {
        let keys = properties.map({ $0.name })
        func needCodingKeys() -> Bool {
            for key in keys {
                let propertyName = key.propertyName(meta: meta).removedQuotationMark()
                if propertyName != key {
                    return true
                }
            }
            return false
        }
        if needCodingKeys() {
            let indent1 = indentation.deeper.value
            let indent2 = indentation.deeper.deeper.value
            var lines: [String] = []
            lines.append("\(indent1)private enum CodingKeys: String, CodingKey {")
            for key in keys {
                let propertyName = key.propertyName(meta: meta)
                if propertyName == key {
                    lines.append("\(indent2)case \(propertyName)")
                } else {
                    lines.append("\(indent2)case \(propertyName) = \"\(key)\"")
                }
            }
            lines.append("\(indent1)}")
            return lines.joined(separator: "\n")
        } else {
            return nil
        }
    }

    func designatedInitializer(indentation: Indentation, meta: Meta) -> String {
        let indent1 = indentation.deeper.value
        let indent2 = indentation.deeper.deeper.value
        var lines: [String] = []
        let arguments = properties.map({
            ($0.name.propertyName(meta: meta), $0.type.name)
        }).map({
            "\($0.0): \($0.1)"
        }).joined(separator: ", ")
        lines.append("\(indent1)\(meta.publicCode)init(\(arguments)) {")
        properties.forEach {
            let propertyName = $0.name.propertyName(meta: meta)
            lines.append("\(indent2)self.\(propertyName) = \(propertyName)")
        }
        lines.append("\(indent1)}")
        return lines.joined(separator: "\n")
    }

    func failableInitializer(indentation: Indentation, meta: Meta) -> String {
        let indent1 = indentation.deeper.value
        let indent2 = indentation.deeper.deeper.value
        var lines: [String] = []
        lines.append("\(indent1)\(meta.publicCode)init?(json: \(meta.jsonDictionaryName)) {")
        properties.forEach {
            let propertyName = $0.name.propertyName(meta: meta)
            switch $0.type.status {
            case .normal:
                switch $0.type.plainType {
                case let .primitive(p):
                    switch p {
                    case .bool, .int, .double, .string:
                        lines.append("\(indent2)guard let \(propertyName) = json[\"\($0.name)\"] as? \(p.name) else { return nil }")
                    case .url:
                        lines.append("\(indent2)guard let \(propertyName)String = json[\"\($0.name)\"] as? String else { return nil }")
                        lines.append("\(indent2)guard let \(propertyName) = URL(string: \(propertyName)String) else { return nil }")
                    case let .date(type):
                        switch type {
                        case .iso8601:
                            let dateString = "\(propertyName)String"
                            lines.append("\(indent2)guard let \(dateString) = json[\"\($0.name)\"] as? String else { return nil }")
                            lines.append("\(indent2)guard let \(propertyName) = DateFormatter.iso8601.date(from: \(dateString)) else { return nil }")
                        case .dateOnly:
                            let dateString = "\(propertyName)String"
                            lines.append("\(indent2)guard let \(dateString) = json[\"\($0.name)\"] as? String else { return nil }")
                            lines.append("\(indent2)guard let \(propertyName) = DateFormatter.dateOnly.date(from: \(dateString)) else { return nil }")
                        case .secondsSince1970:
                            let dateTimeInterval = "\(propertyName)TimeInterval"
                            lines.append("\(indent2)guard let \(dateTimeInterval) = json[\"\($0.name)\"] as? TimeInterval else { return nil }")
                            lines.append("\(indent2)let \(propertyName) = Date(timeIntervalSince1970: \(dateTimeInterval))")
                        }
                    case .any:
                        lines.append("\(indent2)let \(propertyName) = json[\"\($0.name)\"]")
                    case .null:
                        assertionFailure("No null for normal")
                        break
                    }
                case let .struct(s):
                    lines.append("\(indent2)guard let \(propertyName)JSONDictionary = json[\"\($0.name)\"] as? \(meta.jsonDictionaryName) else { return nil }")
                    lines.append("\(indent2)guard let \(propertyName) = \(s.typeName)(json: \(propertyName)JSONDictionary) else { return nil }")
                case let .enum(e):
                    lines.append("\(indent2)guard let \(propertyName)RawValue = json[\"\($0.name)\"] as? \(e.primitive.name) else { return nil }")
                    lines.append("\(indent2)guard let \(propertyName) = \(e.typeName)(rawValue: \(propertyName)RawValue) else { return nil }")
                }
            case .isOptional:
                switch $0.type.plainType {
                case let .primitive(p):
                    lines.append("\(indent2)let \(propertyName) = json[\"\($0.name)\"] as? \(p.name)")
                case let .struct(s):
                    lines.append("\(indent2)let \(propertyName)JSONDictionary = json[\"\($0.name)\"] as? \(meta.jsonDictionaryName)")
                    lines.append("\(indent2)let \(propertyName) = \(propertyName)JSONDictionary.flatMap({ \(s.typeName)(json: $0) })")
                case let .enum(e):
                    lines.append("\(indent2)let \(propertyName)RawValue = json[\"\($0.name)\"] as? \(e.primitive.name)")
                    lines.append("\(indent2)let \(propertyName) = \(propertyName)RawValue.flatMap({ \(e.typeName)(rawValue: $0) })")
                }
            case .inArray:
                switch $0.type.plainType {
                case let .primitive(p):
                    lines.append("\(indent2)guard let \(propertyName) = json[\"\($0.name)\"] as? [\(p.name)] else { return nil }")
                    break
                case let .struct(s):
                    lines.append("\(indent2)guard let \(propertyName)JSONArray = json[\"\($0.name)\"] as? [\(meta.jsonDictionaryName)] else { return nil }")
                    lines.append("\(indent2)let \(propertyName) = \(propertyName)JSONArray.map({ \(s.typeName)(json: $0) }).flatMap({ $0 })")
                case let .enum(e):
                    lines.append("\(indent2)guard let \(propertyName)RawValues = json[\"\($0.name)\"] as? [\(e.primitive.name)] else { return nil }")
                    lines.append("\(indent2)let \(propertyName) = \(propertyName)RawValues.map({ \(e.typeName)(rawValue: $0) }).flatMap({ $0 })")
                }
            }
        }
        let arguments = properties.map({
            $0.name.propertyName(meta: meta)
        }).map({
            "\($0): \($0)"
        }).joined(separator: ", ")
        lines.append("\(indent2)init(\(arguments))")
        lines.append("\(indent1)}")
        return lines.joined(separator: "\n")
    }

    func definition(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        var lines: [String] = []
        if meta.codable {
            lines.append("\(indent)\(meta.publicCode)struct \(typeName): Codable {")
        } else {
            lines.append("\(indent)\(meta.publicCode)struct \(typeName) {")
        }
        properties.forEach {
            $0.nestedDefinition(indentation: indentation, meta: meta).flatMap {
                lines.append($0)
            }
            lines.append($0.definition(indentation: indentation.deeper, meta: meta))
        }
        if meta.codable {
            codingKeysEnum(indentation: indentation, meta: meta).flatMap {
                lines.append($0)
            }
        } else {
            lines.append(designatedInitializer(indentation: indentation, meta: meta))
            lines.append(failableInitializer(indentation: indentation, meta: meta))
        }
        lines.append("\(indent)}")
        return lines.joined(separator: "\n")
    }
}

extension Enum.Case {

    func definition(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        if let rawValue = rawValue {
            switch rawValue {
            case .string(let rawValue):
                if name.removedQuotationMark() == rawValue {
                    return "\(indent)case \(name)"
                } else {
                    return "\(indent)case \(name) = \"\(rawValue)\""
                }
            case .int(let rawValue):
                if name.removedQuotationMark() == "\(rawValue)" {
                    return "\(indent)case \(name)"
                } else {
                    return "\(indent)case \(name) = \(rawValue)"
                }
            case .double(let rawValue):
                if name.removedQuotationMark() == "\(rawValue)" {
                    return "\(indent)case \(name)"
                } else {
                    return "\(indent)case \(name) = \(rawValue)"
                }
            }
        } else {
            return "\(indent)case \(name)"
        }
    }
}

extension Enum {

    var typeName: String {
        return name.type
    }

    func definition(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        var lines: [String] = []
        if meta.codable {
            lines.append("\(indent)\(meta.publicCode)enum \(typeName): \(primitive.name), Codable {")
        } else {
            lines.append("\(indent)\(meta.publicCode)enum \(typeName): \(primitive.name) {")
        }
        cases.forEach {
            lines.append($0.definition(indentation: indentation.deeper, meta: meta))
        }
        lines.append("\(indent)}")
        return lines.joined(separator: "\n")
    }
}

public func code(name: String, value: Value, meta: Meta) {
    let code = Code.create(name: name, value: value, meta: meta)
    if case let .struct(`struct`) = code {
        print("-----------struct-----------")
        print(`struct`)
        print("-----------definition-----------")
        print(`struct`.definition(indentation: .default, meta: meta))
    }
}
