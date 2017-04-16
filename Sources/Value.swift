
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

    /*
    func merge(_ other: Value) -> Value {
        switch (self, other) {
        case (.null, .null):
            return .null
        case (let .bool(value, isRequired), let .bool(value2, isRequired2)):
            return .bool(value: value && value2, isRequired: isRequired && isRequired2)
        case (let .number(value, isRequired), let .number(value2, isRequired2)):
            var newValue = value
            if case .double(_) = value2 {
                newValue = value2
            }
            return .number(value: newValue, isRequired: isRequired && isRequired2)
        case (let .string(value, isRequired), let .string(value2, isRequired2)):
            return .string(value: value + value2, isRequired: isRequired && isRequired2)
        case (let .object(name, value, isRequired), let .object(name2, value2, isRequired2)):
            guard name == name2 else { fatalError("Unsupported object union!") }
            var newValue: [String: Value] = [:]
            for key in value.keys {
                let v1 = value[key]!
                if let v2 = value2[key] {
                    newValue[key] = v1.merge(v2)
                } else {
                    
                }
            }

            
            var newValue = value
            value2.forEach { newValue[$0] = $1 }
            return .object(name: name, value: newValue, isRequired: isRequired && isRequired2)
        case (let .array(name, value, isRequired), let .array(name2, value2, isRequired2)):
            guard name == name2 else { fatalError("Unsupported array union!") }
            let values = value + value2
            guard let firstValue = values.first else {
                return .array(name: name, value: [], isRequired: false)
            }
            let newValue = values.dropFirst().reduce(firstValue, { $0.merge($1) })
            return .array(name: name, value: [newValue], isRequired: isRequired && isRequired2)

        default:
            return self
        }

        return self
    }*/

    func updated(newName: String) -> Value {
        switch self {
        case .string(value: let value):
            if let url = URL(string: value), url.host != nil {
                return .url(value: url)
            } else {
                return self
            }
        case .object(name: _, dictionary: let dictionary):
            var newDictionary: [String: Value] = [:]
            dictionary.forEach { newDictionary[$0] = $1.updated(newName: $0) }
            return .object(name: newName, dictionary: newDictionary)
        case .array(name: _, values: let values):
            let newValues = values.map { $0.updated(newName: newName.propertyNameFromValue) }
            return .array(name: newName, values: newValues)
        default:
            return self
        }
    }
}

extension String {

    var propertyNameFromValue: String {
        return String(self.characters.dropLast())
    }
}
