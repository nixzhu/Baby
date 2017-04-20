
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

public struct SwiftMeta {
    let isPublic: Bool

    public init(isPublic: Bool) {
        self.isPublic = isPublic
    }

    static var `default`: SwiftMeta {
        return SwiftMeta(isPublic: false)
    }

    var publicCode: String {
        return isPublic ? "public " : ""
    }
}
