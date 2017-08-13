
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
    case date
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

    var plainType: PlainType {
        switch self {
        case let .type(type):
            return type.plainType
        case let .property(property):
            return property.type.plainType
        case let .struct(`struct`):
            return .struct(`struct`)
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
    static func create(name: String, value: Value) -> Code {
        switch value {
        case .empty:
            let property = Property(
                name: name,
                type: Type(plainType: .primitive(.any), status: .normal)
            )
            return .property(property)
        case let .null(optionalValue):
            if let value = optionalValue {
                let code = create(name: name, value: value)
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
        case .string:
            let property = Property(
                name: name,
                type: Type(plainType: .primitive(.string), status: .normal)
            )
            return .property(property)
        case let .object(name, dictionary, keys):
            let properties: [Property] = keys.map {
                let value = dictionary[$0]!
                let code = create(name: $0, value: value)
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
                let code = create(name: name, value: value)
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
        case .date:
            let property = Property(
                name: name,
                type: Type(plainType: .primitive(.date), status: .normal)
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

    func definition(indentation: Indentation = .default, meta: Meta = .default) -> String {
        let indent = indentation.value
        var lines: [String] = []
        lines.append("\(indent)let \(name.propertyName(meta: meta)): \(type.name)")
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

    func definition(indentation: Indentation = .default, meta: Meta = .default) -> String {
        let indent = indentation.value
        var lines: [String] = []
        lines.append("\(indent)struct \(typeName) {")
        properties.forEach {
            $0.nestedDefinition(indentation: indentation, meta: meta).flatMap {
                lines.append($0)
            }
            lines.append($0.definition(indentation: indentation.deeper, meta: meta))
        }
        lines.append("\(indent)}")
        return lines.joined(separator: "\n")
    }
}

extension Enum {

    var typeName: String {
        return name.type
    }

    func definition(indentation: Indentation = .default, meta: Meta = .default) -> String {
        let indent = indentation.value
        var lines: [String] = []
        lines.append("\(indent)enum \(typeName) {")
        lines.append("\(indent)}")
        return lines.joined(separator: "\n")
    }
}

public func code(name: String, value: Value, meta: Meta) {
    let code = Code.create(name: name, value: value)
    if case let .struct(`struct`) = code {
        print("-----------struct-----------")
        print(`struct`)
        print("-----------definition-----------")
        print(`struct`.definition(meta: meta))
    }
}
