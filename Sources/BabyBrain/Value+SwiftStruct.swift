
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

extension Value {
    private func initializerCode(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        let indent1 = indentation.deeper.value
        var lines: [String] = []
        switch self {
        case let .object(_, dictionary):
            let arguments = dictionary.map({ "\($0.propertyName): \($1.type)" }).joined(separator: ", ")
            lines.append("\(indent)\(meta.publicCode)init(\(arguments)) {")
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

    private func optionalInitialCodeInArray(indentation: Indentation, meta: Meta, name: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case .empty:
            lines.append("\(indent)let \(name.propertyName) = json[\"\(name)\"] as? [Any]")
        case .null, .bool, .number, .string:
            lines.append("\(indent)let \(name.propertyName) = json[\"\(name)\"] as? [\(self.type)]")
        case .object:
            let jsonArray = "\(name.propertyName)JSONArray"
            lines.append("\(indent)let \(jsonArray) = json[\"\(name)\"] as? [\(meta.jsonDictionaryName)]")
            lines.append("\(indent)let \(name.propertyName) = \(jsonArray).flatMap({ \(name.singularForm.type)(json: $0) }).flatMap({ $0 })")
        case .array:
            fatalError("Unsupported array in array!")
        case .url:
            let urlStrings = "\(name.propertyName)Strings"
            lines.append("\(indent)let \(urlStrings) = json[\"\(name)\"] as? [String]")
            lines.append("\(indent)let \(name.propertyName) = \(urlStrings).flatMap({ URL(string: $0)! })")
        case .date(let type):
            let dateStrings = "\(name.propertyName)Strings"
            lines.append("\(indent)let \(dateStrings) = json[\"\(name)\"] as? [String]")
            switch type {
            case .iso8601:
                lines.append("\(indent)let \(name.propertyName) = \(dateStrings).flatMap({ DateFormatter.iso8601.date(from: $0) })")
            case .dateOnly:
                lines.append("\(indent)let \(name.propertyName) = \(dateStrings).flatMap({ DateFormatter.dateOnly.date(from: $0) })")
            }
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func optionalInitialCode(indentation: Indentation, meta: Meta, key: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case .empty:
            lines.append("\(indent)let \(key.propertyName) = json[\"\(key)\"]")
        case .null:
            lines.append("\(indent)let \(key.propertyName) = json[\"\(key)\"]")
        case .bool, .number, .string:
            lines.append("\(indent)let \(key.propertyName) = json[\"\(key)\"] as? \(self.type)")
        case let .object(name, _):
            let jsonDictionary = "\(name.propertyName)JSONDictionary"
            lines.append("\(indent)let \(jsonDictionary) = json[\"\(name)\"] as? \(meta.jsonDictionaryName)")
            lines.append("\(indent)let \(name.propertyName) = \(jsonDictionary).flatMap({ \(name.type)(json: $0) })")
        case let .array(name, values):
            if let value = values.first {
                lines.append(value.optionalInitialCodeInArray(indentation: indentation, meta: meta, name: name))
            } else {
                lines.append("\(indent)guard let \(name.propertyName) = json[\"\(name)\"] as? [Any] else { return nil }")
            }
        case .url:
            let urlString = "\(key.propertyName)String"
            lines.append("\(indent)let \(urlString) = json[\"\(key)\"] as? String")
            lines.append("\(indent)let \(key.propertyName) = \(urlString).flatMap({ URL(string: $0) })")
        case .date(let type):
            let dateString = "\(key.propertyName)String"
            lines.append("\(indent)let \(dateString) = json[\"\(key)\"] as? String")
            switch type {
            case .iso8601:
                lines.append("\(indent)let \(key.propertyName) = \(dateString).flatMap({ DateFormatter.iso8601.date(from: $0) })")
            case .dateOnly:
                lines.append("\(indent)let \(key.propertyName) = \(dateString).flatMap({ DateFormatter.dateOnly.date(from: $0) })")
            }
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func initialCodeInArray(indentation: Indentation, meta: Meta, name: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case .empty, .null, .bool, .number, .string:
            lines.append("\(indent)guard let \(name.propertyName) = json[\"\(name)\"] as? [\(self.type)] else { return nil }")
        case .object:
            let jsonArray = "\(name.propertyName)JSONArray"
            lines.append("\(indent)guard let \(jsonArray) = json[\"\(name)\"] as? [\(meta.jsonDictionaryName)] else { return nil }")
            lines.append("\(indent)let \(name.propertyName) = \(jsonArray).map({ \(name.singularForm.type)(json: $0) }).flatMap({ $0 })")
        case .array:
            fatalError("Unsupported array in array!")
        case .url:
            let urlStrings = "\(name.propertyName)Strings"
            lines.append("\(indent)guard let \(urlStrings) = json[\"\(name)\"] as? [String] else { return nil }")
            lines.append("\(indent)let \(name.propertyName) = \(urlStrings).map({ URL(string: $0) }).flatMap({ $0 })")
        case .date(let type):
            let dateString = "\(name.propertyName)String"
            lines.append("\(indent)guard let \(dateString) = json[\"\(name)\"] as? String else { return nil }")
            switch type {
            case .iso8601:
                lines.append("\(indent)let \(name.propertyName) = \(dateString).flatMap({ DateFormatter.iso8601.date(from: $0) })")
            case .dateOnly:
                lines.append("\(indent)let \(name.propertyName) = \(dateString).flatMap({ DateFormatter.dateOnly.date(from: $0) })")
            }
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func initialCode(indentation: Indentation, meta: Meta, key: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case .empty:
            lines.append("\(indent)guard let \(key.propertyName) = json[\"\(key)\"] else { return nil }")
        case let .null(optionalValue):
            if let value = optionalValue {
                lines.append(value.optionalInitialCode(indentation: indentation, meta: meta, key: key))
            } else {
                lines.append("\(indent)let \(key.propertyName) = json[\"\(key)\"]")
            }
        case .bool, .number, .string:
            lines.append("\(indent)guard let \(key.propertyName) = json[\"\(key)\"] as? \(self.type) else { return nil }")
        case let .object(name, _):
            let jsonDictionary = "\(name.propertyName)JSONDictionary"
            lines.append("\(indent)guard let \(jsonDictionary) = json[\"\(name)\"] as? \(meta.jsonDictionaryName) else { return nil }")
            lines.append("\(indent)guard let \(name.propertyName) = \(name.type)(json: \(jsonDictionary)) else { return nil }")
        case let .array(name, values):
            if let value = values.first {
                lines.append(value.initialCodeInArray(indentation: indentation, meta: meta, name: name))
            } else {
                lines.append("\(indent)guard let \(name.propertyName) = json[\"\(name)\"] as? [Any] else { return nil }")
            }
        case .url:
            let urlString = "\(key.propertyName)String"
            lines.append("\(indent)guard let \(urlString) = json[\"\(key)\"] as? String else { return nil }")
            lines.append("\(indent)guard let \(key.propertyName) = URL(string: \(urlString)) else { return nil }")
        case .date(let type):
            let dateString = "\(key.propertyName)String"
            lines.append("\(indent)guard let \(dateString) = json[\"\(key)\"] as? String else { return nil }")
            switch type {
            case .iso8601:
                lines.append("\(indent)guard let \(key.propertyName) = DateFormatter.iso8601.date(from: \(dateString)) else { return nil }")
            case .dateOnly:
                lines.append("\(indent)guard let \(key.propertyName) = DateFormatter.dateOnly.date(from: \(dateString)) else { return nil }")
            }
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func failableInitializerCode(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        let indent1 = indentation.deeper.value
        var lines: [String] = []
        switch self {
        case let .object(_, dictionary):
            lines.append("\(indent)\(meta.publicCode)init?(json: \(meta.jsonDictionaryName)) {")
            for (key, value) in dictionary {
                lines.append(value.initialCode(indentation: indentation.deeper, meta: meta, key: key))
            }
            let arguments = dictionary.keys.map({ "\($0.propertyName): \($0.propertyName)" }).joined(separator: ", ")
            lines.append("\(indent1)self.init(\(arguments))")
        default:
            break
        }
        lines.append("\(indent)}")
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    public func swiftStructCode(indentation: Indentation = Indentation.default, meta: Meta = Meta.default) -> String {
        let indent = indentation.value
        let indent1 = indentation.deeper.value
        switch self {
        case let .null(optionalValue):
            return optionalValue?.swiftStructCode(indentation: indentation, meta: meta) ?? ""
        case let .object(name, dictionary):
            var lines: [String] = ["\(indent)\(meta.publicCode)\(meta.modelType) \(name.type) {"]
            for (key, value) in dictionary {
                lines.append(value.swiftStructCode(indentation: indentation.deeper, meta: meta))
                lines.append("\(indent1)\(meta.publicCode)\(meta.declareKeyword) \(key.propertyName): \(value.type) ")
            }
            lines.append(self.initializerCode(indentation: indentation.deeper, meta: meta))
            lines.append(self.failableInitializerCode(indentation: indentation.deeper, meta: meta))
            lines.append("\(indent)}")
            return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
        case let .array(_, values):
            return values.first?.swiftStructCode(indentation: indentation, meta: meta) ?? ""
        default:
            return ""
        }
    }
}
