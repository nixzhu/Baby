
import Foundation

public enum Value {
    case null
    case bool(value: Bool, isRequired: Bool)
    public enum Number {
        case int(Int)
        case double(Double)
    }
    case number(value: Number, isRequired: Bool)
    case string(value: String, isRequired: Bool)
    indirect case object(name: String, value: [String: Value], isRequired: Bool)
    indirect case array(name: String, value: [Value], isRequired: Bool)
    // hyper type
    case url(value: URL, isRequired: Bool)
}

extension Value {

    func updated(newName: String) -> Value {
        switch self {
        case .string(value: let value, isRequired: let isRequired):
            if let url = URL(string: value), let host = url.host, !host.isEmpty {
                return .url(value: url, isRequired: isRequired)
            } else {
                return self
            }
        case .object(name: _, value: let value, isRequired: let isRequired):
            var newValue: [String: Value] = [:]
            value.forEach { newValue[$0] = $1.updated(newName: $0) }
            return .object(name: newName, value: newValue, isRequired: isRequired)
        case .array(name: _, value: let value, isRequired: let isRequired):
            let newValue = value.map { $0.updated(newName: newName.propertyNameFromValue) }
            return .array(name: newName, value: newValue, isRequired: isRequired)
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
