
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
    indirect case array(value: [Value], isRequired: Bool)
}
