
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

public struct Meta {
    let isPublic: Bool
    let jsonDictionaryName: String

    public init(isPublic: Bool, jsonDictionaryName: String) {
        self.isPublic = isPublic
        self.jsonDictionaryName = jsonDictionaryName
    }

    static var `default`: Meta {
        return Meta(isPublic: false, jsonDictionaryName: "[String: Any]")
    }

    var publicCode: String {
        return isPublic ? "public " : ""
    }
}
