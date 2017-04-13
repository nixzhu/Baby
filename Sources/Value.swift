
public enum Value {
    case null
    case bool(Bool)
    public enum Number {
        case int(Int)
        case double(Double)
    }
    case number(Number)
    case string(String)
    indirect case object([String: Value])
    indirect case array([Value])
}
