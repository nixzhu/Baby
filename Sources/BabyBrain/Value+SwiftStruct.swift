
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
            let arguments = keys.map({
                let propertyType = dictionary[$0]!.propertyType(key: $0, meta: meta)
                return "\($0.propertyName(meta: meta)): \(propertyType.propertyType)"
            }).joined(separator: ", ")
            lines.append("\(indent)\(meta.publicCode)init(\(arguments)) {")
            for key in keys {
                let propertyName = key.propertyName(meta: meta)
                lines.append("\(indent1)self.\(propertyName.removedQuotationMark()) = \(propertyName)")
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
        let selfType = self.type(key: name, meta: meta)
        switch self {
        case .empty:
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [Any]")
        case .null(let optionalValue):
            if let value = optionalValue {
                if case .object = value {
                    let propertyName = name.propertyName(meta: meta)
                    let jsonArray = "\(propertyName)JSONArray"
                    lines.append("\(indent)let \(jsonArray) = json[\"\(name)\"] as? [\(meta.jsonDictionaryName)?]")
                    lines.append("\(indent)let \(propertyName) = \(jsonArray).flatMap({ $0.flatMap({ \(name.type(meta: meta, needSingularForm: true))(json: $0) }) })")
                } else {
                    lines.append("\(indent)let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(selfType)]")
                }
            } else {
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(selfType)]")
            }
        case .bool:
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(selfType)]")
        case .number, .string:
            let propertyType = self.propertyType(key: name, meta: meta)
            switch propertyType {
            case .normal:
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(propertyType.name)]")
            case .enum:
                lines.append("\(indent)let \(name.propertyName(meta: meta))RawValues = json[\"\(name)\"] as? [\(selfType)]")
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(name.propertyName(meta: meta))RawValues.flatMap({ \(propertyType.name.removedQuotationMark())(rawValue: $0) }).flatMap({ $0 })")
            }
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(selfType)]")
        case .object:
            let jsonArray = "\(name.propertyName(meta: meta))JSONArray"
            lines.append("\(indent)let \(jsonArray) = json[\"\(name)\"] as? [\(meta.jsonDictionaryName)]")
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(jsonArray).flatMap({ \(name.type(meta: meta, needSingularForm: true))(json: $0) }).flatMap({ $0 })")
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
        let selfType = self.type(key: key, meta: meta)
        switch self {
        case .empty:
            lines.append("\(indent)let \(key.propertyName(meta: meta)) = json[\"\(key)\"]")
        case .null:
            lines.append("\(indent)let \(key.propertyName(meta: meta)) = json[\"\(key)\"]")
        case .bool:
            lines.append("\(indent)let \(key.propertyName(meta: meta)) = json[\"\(key)\"] as? \(selfType)")
        case .number, .string:
            let propertyType = self.propertyType(key: key, meta: meta)
            switch propertyType {
            case .normal:
                lines.append("\(indent)let \(key.propertyName(meta: meta)) = json[\"\(key)\"] as? \(propertyType.name)")
            case .enum:
                lines.append("\(indent)let \(key.propertyName(meta: meta))RawValue = json[\"\(key)\"] as? \(selfType)")
                lines.append("\(indent)let \(key.propertyName(meta: meta)) = \(key.propertyName(meta: meta))RawValue.flatMap{( \(propertyType.name.removedQuotationMark())(rawValue: $0) )}")
            }
        case let .object(name, _, _):
            let jsonDictionary = "\(name.propertyName(meta: meta))JSONDictionary"
            lines.append("\(indent)let \(jsonDictionary) = json[\"\(name)\"] as? \(meta.jsonDictionaryName)")
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(jsonDictionary).flatMap({ \(name.type(meta: meta))(json: $0) })")
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
        let selfType = self.type(key: name, meta: meta)
        switch self {
        case let .null(optionalValue):
            if let value = optionalValue {
                if case .object = value {
                    let propertyName = name.propertyName(meta: meta)
                    let jsonArray = "\(propertyName)JSONArray"
                    lines.append("\(indent)guard let \(jsonArray) = json[\"\(name)\"] as? [\(meta.jsonDictionaryName)?] else { return nil }")
                    lines.append("\(indent)let \(propertyName) = \(jsonArray).map({ $0.flatMap({ \(name.type(meta: meta, needSingularForm: true))(json: $0) }) })")
                } else {
                    let propertyType = value.propertyType(key: name, meta: meta)
                    switch propertyType {
                    case .normal:
                        lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(propertyType.name)] else { return nil }")
                    case .enum:
                        lines.append("\(indent)guard let \(name.propertyName(meta: meta))RawValue = json[\"\(name)\"] as? [\(selfType)])] else { return nil }")
                        lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = \(propertyType.name.removedQuotationMark())(rawValue: \(name.propertyName(meta: meta))RawValue) else { return nil }")
                    }
                }
            } else {
                let propertyType = self.propertyType(key: name, meta: meta)
                switch propertyType {
                case .normal:
                    lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(propertyType.name)] else { return nil }")
                case .enum:
                    lines.append("\(indent)guard let \(name.propertyName(meta: meta))RawValue = json[\"\(name)\"] as? [\(selfType)])] else { return nil }")
                    lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = \(propertyType.name.removedQuotationMark())(rawValue: \(name.propertyName(meta: meta))RawValue) else { return nil }")
                }
            }
        case .empty, .bool:
            lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(selfType)] else { return nil }")
        case .number, .string:
            let propertyType = self.propertyType(key: name, meta: meta, inArray: true)
            switch propertyType {
            case .normal:
                lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = json[\"\(name)\"] as? [\(propertyType.name)] else { return nil }")
            case .enum:
                lines.append("\(indent)guard let \(name.propertyName(meta: meta))RawValues = json[\"\(name)\"] as? [\(selfType)] else { return nil }")
                lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(name.propertyName(meta: meta))RawValues.map({ \(propertyType.name.removedQuotationMark())(rawValue: $0) }).flatMap({ $0 })")
            }
        case .object:
            let jsonArray = "\(name.propertyName(meta: meta))JSONArray"
            lines.append("\(indent)guard let \(jsonArray) = json[\"\(name)\"] as? [\(meta.jsonDictionaryName)] else { return nil }")
            lines.append("\(indent)let \(name.propertyName(meta: meta)) = \(jsonArray).map({ \(name.type(meta: meta, needSingularForm: true))(json: $0) }).flatMap({ $0 })")
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
        let selfType = self.type(key: key, meta: meta)
        switch self {
        case .empty:
            lines.append("\(indent)guard let \(key.propertyName(meta: meta)) = json[\"\(key)\"] else { return nil }")
        case let .null(optionalValue):
            if let value = optionalValue {
                lines.append(value.optionalInitialCode(indentation: indentation, meta: meta, key: key))
            } else {
                lines.append("\(indent)let \(key.propertyName(meta: meta)) = json[\"\(key)\"]")
            }
        case .bool:
            lines.append("\(indent)guard let \(key.propertyName(meta: meta)) = json[\"\(key)\"] as? \(selfType) else { return nil }")
        case .number, .string:
            let propertyType = self.propertyType(key: key, meta: meta)
            switch propertyType {
            case .normal:
                lines.append("\(indent)guard let \(key.propertyName(meta: meta)) = json[\"\(key)\"] as? \(propertyType.name) else { return nil }")
            case .enum:
                lines.append("\(indent)guard let \(key.propertyName(meta: meta))RawValue = json[\"\(key)\"] as? \(selfType) else { return nil }")
                lines.append("\(indent)guard let \(key.propertyName(meta: meta)) = \(propertyType.name.removedQuotationMark())(rawValue: \(key.propertyName(meta: meta))RawValue) else { return nil }")
            }
        case let .object(name, _, _):
            let jsonDictionary = "\(name.propertyName(meta: meta))JSONDictionary"
            lines.append("\(indent)guard let \(jsonDictionary) = json[\"\(name)\"] as? \(meta.jsonDictionaryName) else { return nil }")
            lines.append("\(indent)guard let \(name.propertyName(meta: meta)) = \(name.type(meta: meta))(json: \(jsonDictionary)) else { return nil }")
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
            lines.append("\(indent)\(meta.publicCode)convenience init?(json: \(meta.jsonDictionaryName)) {")
            for key in keys {
                let value = dictionary[key]!
                lines.append(value.initialCode(indentation: indentation.deeper, meta: meta, key: key))
            }
            let arguments = keys.map({ "\($0.propertyName(meta: meta).removedQuotationMark()): \($0.propertyName(meta: meta))" }).joined(separator: ", ")
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
                lines.append("\(indent)\(meta.publicCode)\(meta.modelType) \(name.type(meta: meta)): Codable {")
            } else {
                lines.append("\(indent)\(meta.publicCode)\(meta.modelType) \(name.type(meta: meta)) {")
            }
            for key in keys {
                let value = dictionary[key]!
                lines.append(value.swiftCode(indentation: indentation.deeper, meta: meta))
                let propertyType = value.propertyType(key: key, meta: meta)
                if case .enum(_, _, let rawType, let rawValues) = propertyType {
                    if meta.codable {
                        lines.append("\(indent1)\(meta.publicCode)enum \(propertyType.name): \(propertyType.enumRawType), Codable {")
                    } else {
                        lines.append("\(indent1)\(meta.publicCode)enum \(propertyType.name): \(propertyType.enumRawType) {")
                    }
                    func appendCase(name: String, rawValue: String) {
                        if name.removedQuotationMark() == rawValue {
                            lines.append("\(indent2)case \(name)")
                        } else {
                            switch rawType {
                            case .string:
                                lines.append("\(indent2)case \(name) = \"\(rawValue)\"")
                            case .int, .double:
                                lines.append("\(indent2)case \(name) = \(rawValue)")
                            }
                        }
                    }
                    if let enumCases = meta.enumCases(key: key) {
                        for enumCase in enumCases {
                            let caseName = enumCase.name
                            let caseRawValue = enumCase.rawValue ?? enumCase.name
                            appendCase(name: caseName, rawValue: caseRawValue)
                        }
                    } else {
                        if !rawValues.isEmpty {
                            let allRawValues = rawValues.components(separatedBy: Meta.enumRawValueSeparator)
                            var validCaseRawValues: [String] = []
                            for rawValue in allRawValues {
                                if !validCaseRawValues.contains(rawValue) {
                                    validCaseRawValues.append(rawValue)
                                }
                            }
                            for rawValue in validCaseRawValues {
                                let caseName = rawValue.propertyName(meta: meta)
                                let caseRawValue = rawValue
                                appendCase(name: caseName, rawValue: caseRawValue)
                            }
                        }
                    }
                    lines.append("\(indent1)}")
                    lines.append("\(indent1)\(meta.publicCode)\(meta.declareKeyword) \(key.propertyName(meta: meta)): \(propertyType.propertyType)")
                } else {
                    lines.append("\(indent1)\(meta.publicCode)\(meta.declareKeyword) \(key.propertyName(meta: meta)): \(value.type(key: key, meta: meta))")
                }
            }
            if meta.codable {
                func needCodingKeys(with dictionary: [String: Any]) -> Bool {
                    for key in keys {
                        let propertyName = key.propertyName(meta: meta).removedQuotationMark()
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
