
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

    public init(isPublic: Bool, modelType: String, codable: Bool, declareVariableProperties: Bool, jsonDictionaryName: String, propertyMap: [String: String], arrayObjectMap: [String: String]) {
        self.isPublic = isPublic
        self.modelType = modelType
        self.codable = codable
        self.declareVariableProperties = declareVariableProperties
        self.jsonDictionaryName = jsonDictionaryName
        self.propertyMap = propertyMap
        self.arrayObjectMap = arrayObjectMap
    }

    static var `default`: Meta {
        return Meta(
            isPublic: false,
            modelType: "struct",
            codable: false,
            declareVariableProperties: false,
            jsonDictionaryName: "[String: Any]",
            propertyMap: [:],
            arrayObjectMap: [:]
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
