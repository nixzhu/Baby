
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
    indirect case array(PlainType)
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
                let type: Type
                if value.isArray {
                    type = Type(plainType: .array(code.plainType), status: .isOptional)
                } else {
                    type = Type(plainType: .primitive(.null(code.plainType)), status: .isOptional)
                }
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
                    let name = $0.name.propertyName(meta: meta)
                    let rawValue: Enum.Case.RawValue
                    let rawValueString = $0.rawValue ?? $0.name
                    if let intValue = Int(rawValueString) {
                        rawValue = .int(intValue)
                    } else if let doubleValue = Double(rawValueString) {
                        rawValue = .double(doubleValue)
                    } else {
                        rawValue = .string(rawValueString)
                    }
                    return Enum.Case(name: name, rawValue: rawValue)
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
                        let name = $0.name.propertyName(meta: meta)
                        let rawValue = Enum.Case.RawValue.string($0.rawValue ?? $0.name)
                        return Enum.Case(name: name, rawValue: rawValue)
                    }
                } else {
                    let allRawValues = rawValuesString.components(separatedBy: Meta.enumRawValueSeparator)
                    var validCaseRawValues: [String] = []
                    for rawValue in allRawValues {
                        if !validCaseRawValues.contains(rawValue) {
                            validCaseRawValues.append(rawValue)
                        }
                    }
                    cases = validCaseRawValues.map {
                        let name = $0.propertyName(meta: meta)
                        let rawValue = Enum.Case.RawValue.string($0)
                        return Enum.Case(name: name, rawValue: rawValue)
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

    func name(meta: Meta) -> String {
        switch self {
        case .bool: return "Bool"
        case .int: return "Int"
        case .double: return "Double"
        case .string: return "String"
        case .url: return "URL"
        case .date: return "Date"
        case .any: return "Any"
        case let .null(plainType): return plainType.name(meta: meta) + "?"
        }
    }
}

extension PlainType {

    func name(meta: Meta) -> String {
        switch self {
        case let .primitive(p): return p.name(meta: meta)
        case let .struct(s): return s.name.type(meta: meta)
        case let .enum(e): return e.name.type(meta: meta)
        case let .array(plainType): return "[" + plainType.name(meta: meta) + "]"
        }
    }
}

extension Type {

    func name(meta: Meta) -> String {
        let _name: String
        switch plainType {
        case let .primitive(p):
            _name = p.name(meta: meta)
        case let .struct(s):
            _name = s.typeName(meta: meta)
        case let .enum(e):
            _name = e.typeName(meta: meta)
        case let .array(plainType):
            _name = "[" + plainType.name(meta: meta) + "]"
        }
        let name: String
        switch status {
        case .normal:
            name = _name
        case .isOptional:
            if _name.hasSuffix("?") {
                name = _name
            } else {
                name = _name + "?"
            }
        case .inArray:
            name = "[" + _name + "]"
        }
        if _name == "Any" {
            return name + " //TODO: Specify the type to conforms Codable protocol"
        }
        return name
    }
}

extension Property {

    func typeName(meta: Meta) -> String {
        if let type = meta.propertyTypeMap[name] {
            if type == "?" {
                return self.type.name(meta: meta)
            } else {
                return type
            }
        } else {
            return type.name(meta: meta)
        }
    }

    func definition(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        var lines: [String] = []
        lines.append("\(indent)\(meta.publicCode)\(meta.declareKeyword) \(name.propertyName(meta: meta)): \(typeName(meta: meta))")
        return lines.joined(separator: "\n")
    }

    func nestedDefinition(indentation: Indentation = .default, meta: Meta = .default) -> String? {
        var lines: [String] = []
        func handlePlainType(_ plainType: PlainType) {
            switch plainType {
            case let .primitive(p):
                if case let .null(plainType) = p {
                    handlePlainType(plainType)
                }
            case let .struct(s):
                lines.append(s.definition(indentation: indentation.deeper, meta: meta))
            case let .enum(e):
                lines.append(e.definition(indentation: indentation.deeper, meta: meta))
            case let .array(plainType):
                handlePlainType(plainType)
            }
        }
        handlePlainType(type.plainType)
        if lines.isEmpty {
            return nil
        } else {
            return lines.joined(separator: "\n")
        }
    }
}

extension Struct {

    func typeName(meta: Meta, needSingularForm: Bool = false) -> String {
        return name.type(meta: meta, needSingularForm: needSingularForm)
    }

    func codingKeysEnum(indentation: Indentation, meta: Meta) -> String? {
        let keys = properties.map({ $0.name })
        func needCodingKeys() -> Bool {
            if meta.useSnakeCaseKeyDecodingStrategy {
                return false
            } else {
                for key in keys {
                    let propertyName = key.propertyName(meta: meta).removedQuotationMark()
                    if propertyName != key {
                        return true
                    }
                }
                return false
            }
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

    func definition(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        var lines: [String] = []
        lines.append("\(indent)\(meta.publicCode)\(meta.modelType) \(typeName(meta: meta).quotedIfNeed): Codable {")
        properties.forEach {
            $0.nestedDefinition(indentation: indentation, meta: meta).flatMap {
                lines.append($0)
            }
            lines.append($0.definition(indentation: indentation.deeper, meta: meta))
        }
        codingKeysEnum(indentation: indentation, meta: meta).flatMap {
            lines.append($0)
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

    func typeName(meta: Meta, needSingularForm: Bool = false) -> String {
        return name.type(meta: meta, needSingularForm: needSingularForm)
    }

    func definition(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        var lines: [String] = []
        lines.append("\(indent)\(meta.publicCode)enum \(typeName(meta: meta).quotedIfNeed): \(primitive.name(meta: meta)), Codable {")
        cases.forEach {
            lines.append($0.definition(indentation: indentation.deeper, meta: meta))
        }
        lines.append("\(indent)}")
        return lines.joined(separator: "\n")
    }
}

public func code(name: String, value: Value, meta: Meta) -> String? {
    let code = Code.create(name: name, value: value, meta: meta)
    if case let .struct(`struct`) = code.plainType {
        return `struct`.definition(indentation: .default, meta: meta)
    } else {
        return nil
    }
}
