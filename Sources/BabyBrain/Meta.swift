
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

public struct Meta {
    let isPublic: Bool
    let modelType: String
    let codable: Bool
    let declareVariableProperties: Bool
    let jsonDictionaryName: String
    let propertyMap: [String: String]
    let arrayObjectMap: [String: String]
    let propertyTypeMap: [String: String]
    public struct EnumProperty {
        public let name: String
        public struct Case {
            public let name: String
            public let rawValue: String?

            public init(name: String, rawValue: String?) {
                self.name = name
                self.rawValue = rawValue
            }

            public var string: String {
                if let rawValue = rawValue {
                    return "\(name): \(rawValue)"
                } else {
                    return name
                }
            }
        }
        public let cases: [Case]?

        public init(name: String, cases: [(String, String?)]?) {
            self.name = name
            if let cases = cases {
                self.cases = cases.map({ .init(name: $0, rawValue: $1) })
            } else {
                self.cases = nil
            }
        }

        public var string: String {
            var string = name
            if let cases = cases, !cases.isEmpty {
                string += "["
                string += cases.map({ $0.string }).joined(separator: ", ")
                string += "]"
            }
            return string
        }
    }
    let enumProperties: [EnumProperty]

    func contains(enumPropertyKey: String ) -> Bool {
        for enumProperty in enumProperties {
            if enumProperty.name == enumPropertyKey {
                return true
            }
        }
        return false
    }

    func enumCases(key: String) -> [EnumProperty.Case]? {
        for enumProperty in enumProperties {
            if enumProperty.name == key {
                return enumProperty.cases
            }
        }
        return nil
    }

    public init(isPublic: Bool, modelType: String, codable: Bool, declareVariableProperties: Bool, jsonDictionaryName: String, propertyMap: [String: String], arrayObjectMap: [String: String], propertyTypeMap: [String: String], enumProperties: [EnumProperty]) {
        self.isPublic = isPublic
        self.modelType = modelType
        self.codable = codable
        self.declareVariableProperties = declareVariableProperties
        self.jsonDictionaryName = jsonDictionaryName
        self.propertyMap = propertyMap
        self.arrayObjectMap = arrayObjectMap
        self.propertyTypeMap = propertyTypeMap
        self.enumProperties = enumProperties
    }

    public static var `default`: Meta {
        return Meta(
            isPublic: false,
            modelType: "struct",
            codable: false,
            declareVariableProperties: false,
            jsonDictionaryName: "[String: Any]",
            propertyMap: [:],
            arrayObjectMap: [:],
            propertyTypeMap: [:],
            enumProperties: []
        )
    }

    var publicCode: String {
        return isPublic ? "public " : ""
    }

    var declareKeyword: String {
        return declareVariableProperties ? "var" : "let"
    }
}

extension Meta {
    static let swiftKeywords: Set<String> = [
        "Any",
        "as",
        "associatedtype",
        "break",
        "case",
        "catch",
        "class",
        "continue",
        "default",
        "defer",
        "deinit",
        "do",
        "else",
        "enum",
        "extension",
        "fallthrough",
        "false",
        "fileprivate",
        "for",
        "func",
        "guard",
        "if",
        "import",
        "in",
        "init",
        "inout",
        "internal",
        "is",
        "let",
        "nil",
        "open",
        "operator",
        "private",
        "protocol",
        "public",
        "repeat",
        "rethrows",
        "return",
        "Self",
        "self",
        "static",
        "struct",
        "subscript",
        "super",
        "switch",
        "Type",
        "throw",
        "throws",
        "true",
        "try",
        "typealias",
        "var",
        "where",
        "while"
    ]
}

extension Meta {
    public static var enumRawValueSeparator: String = "<@_@>"
}
