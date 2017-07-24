
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

extension Value {
    private func initializerCode(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        let indent1 = indentation.deeper.value
        var lines: [String] = []
        switch self {
        case let .object(_, dictionary, keys):
            let arguments = keys.map({ "\($0.propertyName(meta: meta)): \(dictionary[$0]!.type)" }).joined(separator: ", ")
            lines.append("\(indent)\(meta.publicCode)init(\(arguments)) {")
            for key in keys {
                let propertyName = key.propertyName(meta: meta)
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
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [Any]")
        case .null(let optionalValue):
            if let value = optionalValue {
                if case .object = value {
                    let propertyName = name.propertyName(meta: meta)
                    let jsonArray = "\(propertyName)JSONArray"
                    lines.append("\(indent)let \(jsonArray) = json[\"\(name)\"] as? [\(meta.jsonDictionaryName)?]")
                    lines.append("\(indent)let \(propertyName) = \(jsonArray).flatMap({ $0.flatMap({ \(name.singularForm(meta: meta).type)(json: $0) }) })")
                } else {
                    lines.append("\(indent)let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(self.type)]")
                }
            } else {
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(self.type)]")
            }
        case .bool, .number, .string:
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(self.type)]")
        case .object:
            let jsonArray = "\(name.propertyName(meta: meta))JSONArray"
            lines.append("\(indent)let \(jsonArray) = json[\"\(name)\"] as? [\(meta.jsonDictionaryName)]")
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(jsonArray).flatMap({ \(name.singularForm(meta: meta).type)(json: $0) }).flatMap({ $0 })")
        case .array:
            lines.append("* Unsupported array in array!")
        case .url:
            let urlStrings = "\(name.propertyName(meta: meta))Strings"
            lines.append("\(indent)let \(urlStrings) = json[\"\(name)\"] as? [String]")
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(urlStrings).flatMap({ URL(string: $0)! })")
        case .date(let type):
            switch type {
            case .iso8601:
                let dateStrings = "\(name.propertyName(meta: meta))Strings"
                lines.append("\(indent)let \(dateStrings) = json[\"\(name)\"] as? [String]")
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(dateStrings).flatMap({ DateFormatter.iso8601.date(from: $0) })")
            case .dateOnly:
                let dateStrings = "\(name.propertyName(meta: meta))Strings"
                lines.append("\(indent)let \(dateStrings) = json[\"\(name)\"] as? [String]")
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(dateStrings).flatMap({ DateFormatter.dateOnly.date(from: $0) })")
            case .secondsSince1970:
                let dateTimeIntervals = "\(name.propertyName(meta: meta))TimeIntervals"
                lines.append("\(indent)let \(dateTimeIntervals) = json[\"\(name)\"] as? [TimeInterval]")
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(dateTimeIntervals).flatMap({ Date(timeIntervalSince1970: $0) })")
            }
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func optionalInitialCode(indentation: Indentation, meta: Meta, key: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case .empty:
            lines.append("\(indent)let \(key.propertyName(meta: meta)) = json[\"\(key)\"]")
        case .null:
            lines.append("\(indent)let \(key.propertyName(meta: meta)) = json[\"\(key)\"]")
        case .bool, .number, .string:
            lines.append("\(indent)let \(key.propertyName(meta: meta)) = json[\"\(key)\"] as? \(self.type)")
        case let .object(name, _, _):
            let jsonDictionary = "\(name.propertyName(meta: meta))JSONDictionary"
            lines.append("\(indent)let \(jsonDictionary) = json[\"\(name)\"] as? \(meta.jsonDictionaryName)")
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(jsonDictionary).flatMap({ \(name.type)(json: $0) })")
        case let .array(name, values):
            if let value = values.first {
                lines.append(value.optionalInitialCodeInArray(indentation: indentation, meta: meta, name: name))
            } else {
                lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [Any] else { return nil }")
            }
        case .url:
            let urlString = "\(key.propertyName(meta: meta))String"
            lines.append("\(indent)let \(urlString) = json[\"\(key)\"] as? String")
            lines.append("\(indent)let \(key.propertyName(meta: meta)) = \(urlString).flatMap({ URL(string: $0) })")
        case .date(let type):
            switch type {
            case .iso8601:
                let dateString = "\(key.propertyName(meta: meta))String"
                lines.append("\(indent)let \(dateString) = json[\"\(key)\"] as? String")
                lines.append("\(indent)let \(key.propertyName(meta: meta)) = \(dateString).flatMap({ DateFormatter.iso8601.date(from: $0) })")
            case .dateOnly:
                let dateString = "\(key.propertyName(meta: meta))String"
                lines.append("\(indent)let \(dateString) = json[\"\(key)\"] as? String")
                lines.append("\(indent)let \(key.propertyName(meta: meta)) = \(dateString).flatMap({ DateFormatter.dateOnly.date(from: $0) })")
            case .secondsSince1970:
                let dateTimeInterval = "\(key.propertyName(meta: meta))TimeInterval"
                lines.append("\(indent)let \(dateTimeInterval) = json[\"\(key)\"] as? TimeInterval")
                lines.append("\(indent)let \(key.propertyName(meta: meta)) = \(dateTimeInterval).flatMap({ Date(timeIntervalSince1970: $0) })")
            }
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func initialCodeInArray(indentation: Indentation, meta: Meta, name: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case let .null(optionalValue):
            if let value = optionalValue {
                if case .object = value {
                    let propertyName = name.propertyName(meta: meta)
                    let jsonArray = "\(propertyName)JSONArray"
                    lines.append("\(indent)guard let \(jsonArray) = json[\"\(name)\"] as? [\(meta.jsonDictionaryName)?] else { return nil }")
                    lines.append("\(indent)let \(propertyName) = \(jsonArray).map({ $0.flatMap({ \(name.singularForm(meta: meta).type)(json: $0) }) })")
                } else {
                    lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(self.type)] else { return nil }")
                }
            } else {
                lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(self.type)] else { return nil }")
            }
        case .empty, .bool, .number, .string:
            lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(self.type)] else { return nil }")
        case .object:
            let jsonArray = "\(name.propertyName(meta: meta))JSONArray"
            lines.append("\(indent)guard let \(jsonArray) = json[\"\(name)\"] as? [\(meta.jsonDictionaryName)] else { return nil }")
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(jsonArray).map({ \(name.singularForm(meta: meta).type)(json: $0) }).flatMap({ $0 })")
        case .array:
            lines.append("* Unsupported array in array!")
        case .url:
            let urlStrings = "\(name.propertyName(meta: meta))Strings"
            lines.append("\(indent)guard let \(urlStrings) = json[\"\(name)\"] as? [String] else { return nil }")
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(urlStrings).map({ URL(string: $0) }).flatMap({ $0 })")
        case .date(let type):
            switch type {
            case .iso8601:
                let dateStrings = "\(name.propertyName(meta: meta))Strings"
                lines.append("\(indent)guard let \(dateStrings) = json[\"\(name)\"] as? [String] else { return nil }")
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(dateStrings).flatMap({ DateFormatter.iso8601.date(from: $0) })")
            case .dateOnly:
                let dateStrings = "\(name.propertyName(meta: meta))Strings"
                lines.append("\(indent)guard let \(dateStrings) = json[\"\(name)\"] as? [String] else { return nil }")
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(dateStrings).flatMap({ DateFormatter.dateOnly.date(from: $0) })")
            case .secondsSince1970:
                let dateTimeIntervals = "\(name.propertyName(meta: meta))TimeIntervals"
                lines.append("\(indent)guard let \(dateTimeIntervals) = json[\"\(name)\"] as? [TimeInterval] else { return nil }")
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(dateTimeIntervals).map({ Date(timeIntervalSince1970: $0) })")
            }
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func initialCode(indentation: Indentation, meta: Meta, key: String) -> String {
        let indent = indentation.value
        var lines: [String] = []
        switch self {
        case .empty:
            lines.append("\(indent)guard let \(key.propertyName(meta: meta)) = json[\"\(key)\"] else { return nil }")
        case let .null(optionalValue):
            if let value = optionalValue {
                lines.append(value.optionalInitialCode(indentation: indentation, meta: meta, key: key))
            } else {
                lines.append("\(indent)let \(key.propertyName(meta: meta)) = json[\"\(key)\"]")
            }
        case .bool, .number, .string:
            lines.append("\(indent)guard let \(key.propertyName(meta: meta)) = json[\"\(key)\"] as? \(self.type) else { return nil }")
        case let .object(name, _, _):
            let jsonDictionary = "\(name.propertyName(meta: meta))JSONDictionary"
            lines.append("\(indent)guard let \(jsonDictionary) = json[\"\(name)\"] as? \(meta.jsonDictionaryName) else { return nil }")
            lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = \(name.type)(json: \(jsonDictionary)) else { return nil }")
        case let .array(name, values):
            if let value = values.first {
                lines.append(value.initialCodeInArray(indentation: indentation, meta: meta, name: name))
            } else {
                lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [Any] else { return nil }")
            }
        case .url:
            let urlString = "\(key.propertyName(meta: meta))String"
            lines.append("\(indent)guard let \(urlString) = json[\"\(key)\"] as? String else { return nil }")
            lines.append("\(indent)guard let \(key.propertyName(meta: meta)) = URL(string: \(urlString)) else { return nil }")
        case .date(let type):
            switch type {
            case .iso8601:
                let dateString = "\(key.propertyName(meta: meta))String"
                lines.append("\(indent)guard let \(dateString) = json[\"\(key)\"] as? String else { return nil }")
                lines.append("\(indent)guard let \(key.propertyName(meta: meta)) = DateFormatter.iso8601.date(from: \(dateString)) else { return nil }")
            case .dateOnly:
                let dateString = "\(key.propertyName(meta: meta))String"
                lines.append("\(indent)guard let \(dateString) = json[\"\(key)\"] as? String else { return nil }")
                lines.append("\(indent)guard let \(key.propertyName(meta: meta)) = DateFormatter.dateOnly.date(from: \(dateString)) else { return nil }")
            case .secondsSince1970:
                let dateTimeInterval = "\(key.propertyName(meta: meta))TimeInterval"
                lines.append("\(indent)guard let \(dateTimeInterval) = json[\"\(key)\"] as? TimeInterval else { return nil }")
                lines.append("\(indent)let \(key.propertyName(meta: meta)) = Date(timeIntervalSince1970: \(dateTimeInterval))")
            }
        }
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    private func failableInitializerCode(indentation: Indentation, meta: Meta) -> String {
        let indent = indentation.value
        let indent1 = indentation.deeper.value
        var lines: [String] = []
        switch self {
        case let .object(_, dictionary, keys):
            lines.append("\(indent)\(meta.publicCode)init?(json: \(meta.jsonDictionaryName)) {")
            for key in keys {
                let value = dictionary[key]!
                lines.append(value.initialCode(indentation: indentation.deeper, meta: meta, key: key))
            }
            let arguments = keys.map({ "\($0.propertyName(meta: meta)): \($0.propertyName(meta: meta))" }).joined(separator: ", ")
            lines.append("\(indent1)self.init(\(arguments))")
        default:
            break
        }
        lines.append("\(indent)}")
        return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
    }

    public func swiftCode(indentation: Indentation = Indentation.default, meta: Meta = Meta.default) -> String {
        let indent = indentation.value
        let indent1 = indentation.deeper.value
        let indent2 = indentation.deeper.deeper.value
        switch self {
        case let .null(optionalValue):
            return optionalValue?.swiftCode(indentation: indentation, meta: meta) ?? ""
        case let .object(name, dictionary, keys):
            var lines: [String] = []
            if meta.codable {
                lines.append("\(indent)\(meta.publicCode)\(meta.modelType) \(name.type): Codable {")
            } else {
                lines.append("\(indent)\(meta.publicCode)\(meta.modelType) \(name.type) {")
            }
            for key in keys {
                let value = dictionary[key]!
                lines.append(value.swiftCode(indentation: indentation.deeper, meta: meta))
                lines.append("\(indent1)\(meta.publicCode)\(meta.declareKeyword) \(key.propertyName(meta: meta)): \(value.type)")
            }
            if meta.codable {
                func needCodingKeys(with dictionary: [String: Any]) -> Bool {
                    for key in keys {
                        let propertyName = key.propertyName(meta: meta)
                        if propertyName != key {
                            return true
                        }
                    }
                    return false
                }
                if needCodingKeys(with: dictionary) {
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
                }
            } else {
                lines.append(self.initializerCode(indentation: indentation.deeper, meta: meta))
                lines.append(self.failableInitializerCode(indentation: indentation.deeper, meta: meta))
            }
            lines.append("\(indent)}")
            return lines.filter({ !$0.isEmpty }).joined(separator: "\n")
        case let .array(_, values):
            return values.first?.swiftCode(indentation: indentation, meta: meta) ?? ""
        default:
            return ""
        }
    }
}
