
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
        case .null, .bool, .number, .string:
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
        case .null, .bool, .number, .string:
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

    public func swiftStructCode(indentation: Indentation = Indentation.default) -> String {
        let indent = indentation.value
        let indent1 = indentation.deeper.value
        switch self {
        case let .object(name, dictionary):
            var lines: [String] = ["\(indent)struct \(name.type) {"]
            for (key, value) in dictionary {
                lines.append(value.swiftStructCode(indentation: indentation.deeper))
                lines.append("\(indent1)let \(key.propertyName): \(value.type) ")
            }
            lines.append(self.initializerCode(indentation: indentation.deeper))
            lines.append(self.failableInitializerCode(indentation: indentation.deeper))
            lines.append("\(indent)}")
            return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
        case let .array(_, values):
            return values.first?.swiftStructCode(indentation: indentation) ?? ""
        default:
            return ""
        }
    }
}
