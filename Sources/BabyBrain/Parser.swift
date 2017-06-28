
/*
 * @nixzhu (zhuhongxu@gmail.com)
 */

private typealias Stream = String.CharacterView
private typealias Parser<A> = (Stream) -> (A, Stream)?

private func map<A, B>(_ parser: @escaping Parser<A>, _ transform: @escaping (A) -> B) -> Parser<B> {
    return { stream in
        guard let (result, remainder) = parser(stream) else { return nil }
        return (transform(result), remainder)
    }
}

private func optional<A>(_ parser: @escaping Parser<A>) -> Parser<A?> {
    return { stream in
        if let (result, remainder) = parser(stream) {
            return (result, remainder)
        } else {
            return (nil, stream)
        }
    }
}

private func or<A>(_ leftParser: @escaping Parser<A>, _ rightParser: @escaping Parser<A>) -> Parser<A> {
    return { stream in
        return leftParser(stream) ?? rightParser(stream)
    }
}

private func one<A>(of parsers: [Parser<A>]) -> Parser<A> {
    return { stream in
        for parser in parsers {
            if let x = parser(stream) {
                return x
            }
        }
        return nil
    }
}

private func many<A>(_ parser: @escaping Parser<A>) -> Parser<[A]> {
    return { stream in
        var result = [A]()
        var remainder = stream
        while let (element, newRemainder) = parser(remainder) {
            result.append(element)
            remainder = newRemainder
        }
        return (result, remainder)
    }
}

private func many1<A>(_ parser: @escaping Parser<A>) -> Parser<[A]> {
    return { stream in
        guard let (element, remainder1) = parser(stream) else { return nil }
        if let (array, remainder2) = many(parser)(remainder1) {
            return ([element] + array, remainder2)
        } else {
            return ([element], remainder1)
        }
    }
}

private func between<A, B, C>(_ a: @escaping Parser<A>, _ b: @escaping Parser<B>, _ c: @escaping Parser<C>) -> Parser<B> {
    return { stream in
        guard let (_, remainder1) = a(stream) else { return nil }
        guard let (result2, remainder2) = b(remainder1) else { return nil }
        guard let (_, remainder3) = c(remainder2) else { return nil }
        return (result2, remainder3)
    }
}

private func and<A, B>(_ left: @escaping Parser<A>, _ right: @escaping Parser<B>) -> Parser<(A, B)> {
    return { stream in
        guard let (result1, remainder1) = left(stream) else { return nil }
        guard let (result2, remainder2) = right(remainder1) else { return nil }
        return ((result1, result2), remainder2)
    }
}

private func eatLeft<A, B>(_ left: @escaping Parser<A>, _ right: @escaping Parser<B>) -> Parser<B> {
    return { stream in
        guard let (_, remainder1) = left(stream) else { return nil }
        guard let (result2, remainder2) = right(remainder1) else { return nil }
        return (result2, remainder2)
    }
}

private func eatRight<A, B>(_ left: @escaping Parser<A>, _ right: @escaping Parser<B>) -> Parser<A> {
    return { stream in
        guard let (result1, remainder1) = left(stream) else { return nil }
        guard let (_, remainder2) = right(remainder1) else { return nil }
        return (result1, remainder2)
    }
}

private func list<A, B>(_ parser: @escaping Parser<A>, _ separator: @escaping Parser<B>) -> Parser<[A]> {
    return { stream in
        let separatorThenParser = and(separator, parser)
        let parser = and(parser, many(separatorThenParser))
        guard let (result, remainder) = parser(stream) else { return nil }
        let finalResult = [result.0] + result.1.map({ $0.1 })
        return (finalResult, remainder)
    }
}

private func satisfy(_ condition: @escaping (Character) -> Bool) -> Parser<Character> {
    return { stream in
        guard let firstCharacter = stream.first, condition(firstCharacter) else { return nil }
        return (firstCharacter, stream.dropFirst())
    }
}

private func character(_ character: Character) -> Parser<Character> {
    return { stream in
        guard let firstCharacter = stream.first, firstCharacter == character else { return nil }
        return (firstCharacter, stream.dropFirst())
    }
}

private func word(_ string: String) -> Parser<String> {
    let parsers = string.characters.map({ character($0) })
    return { stream in
        var characters: [Character] = []
        var remainder = stream
        for parser in parsers {
            guard let (character, newRemainder) = parser(remainder) else { return nil }
            characters.append(character)
            remainder = newRemainder
        }
        return (String(characters), remainder)
    }
}

// Helpers

private let spaces: Parser<String> = {
    let space = one(of: [
        character(" "),
        character("\0"),
        character("\t"),
        character("\r"),
        character("\n"),
        ]
    )
    let spaceString = map(space) { String($0) }
    return map(many(or(spaceString, word("\r\n")))) { $0.joined() }
}()

// Parsers

private let null: Parser<Value> = {
    return map(eatRight(word("null"), spaces)) { _ in Value.null(optionalValue: nil) }
}()

private let bool: Parser<Value> = {
    let `true` = map(eatRight(word("true"), spaces)) { _ in true }
    let `false` = map(eatRight(word("false"), spaces)) { _ in false }
    return map(or(`true`, `false`)) { bool in Value.bool(value: bool) }
}()

private let number: Parser<Value> = {
    let optionalSign = optional(character("-"))
    let zero = word("0")
    let digitOneNine = one(of: "123456789".characters.map({ $0 }).map({ character($0) }))
    let digit = one(of: "0123456789".characters.map({ $0 }).map({ character($0) }))
    let point = character(".")
    let e = or(character("e"), character("E"))
    let optionalPlusMinus = optional(or(character("+"), character("-")))
    let nonZeroInt = map(and(digitOneNine, many(digit))) { String($0) + String($1) }
    let intPart = or(zero, nonZeroInt)
    let fractionPart = map(eatLeft(point, many1(digit))) { String($0) }
    let exponentPart = map(and(eatLeft(e, optionalPlusMinus), many1(digit))) {
        ($0.flatMap({ String($0) }) ?? "") + String($1)
    }
    let numberString: Parser<String> = map(and(and(and(optionalSign, intPart), optional(fractionPart)), optional(exponentPart))) {
        let sign = ($0.0.0.0).flatMap({ String($0) }) ?? ""
        let int = $0.0.0.1
        let fraction = ($0.0.1).flatMap({ "." + String($0) }) ?? ""
        let exponent = ($0.1).flatMap({ "e" + String($0) }) ?? ""
        return sign + int + fraction + exponent
    }
    return map(eatRight(numberString, spaces)) { string in
        if let int = Int(string) {
            return Value.number(value: .int(int))
        } else {
            let double = Double(string)!
            return Value.number(value: .double(double))
        }
    }
}()

private let quotedString: Parser<String> = {
    let unescapedCharacter = satisfy({ $0 != "\\" && $0 != "\"" })
    let escapedCharacter = one(of: [
        map(word("\\\"")) { _ in Character("\"") },
        map(word("\\\\")) { _ in Character("\\") },
        map(word("\\/")) { _ in Character("/") },
        map(word("\\n")) { _ in Character("\n") },
        map(word("\\r")) { _ in Character("\r") },
        map(word("\\t")) { _ in Character("\t") },
        ]
    )
    let unicodeString: Parser<String> = {
        let hexDigit = one(of: "0123456789ABCDEFabcdef".characters.map({ character($0) }))
        return { stream in
            guard let (_, remainder1) = character("\\")(stream) else { return nil }
            guard let (_, remainder2) = character("u")(remainder1) else { return nil }
            guard let (a, remainder3) = hexDigit(remainder2) else { return nil }
            guard let (b, remainder4) = hexDigit(remainder3) else { return nil }
            guard let (c, remainder5) = hexDigit(remainder4) else { return nil }
            guard let (d, remainder6) = hexDigit(remainder5) else { return nil }
            return (String([a, b, c, d]), remainder6)
        }
    }()
    let unicodeCharacter = map(unicodeString) { Character(UnicodeScalar(UInt32($0, radix: 16)!)!) }
    let letter = one(of: [unescapedCharacter, escapedCharacter, unicodeCharacter])
    let _string = map(many(letter)) { String($0) }
    let quote = character("\"")
    return between(quote, _string, quote)
}()

private let string: Parser<Value> = {
    return map(eatRight(quotedString, spaces)) { Value.string(value: $0) }
}()

private var _value: Parser<Value>?
private let value: Parser<Value> = { stream in
    if let parser = _value {
        return eatLeft(spaces, parser)(stream)
    }
    return nil
}

private let object: Parser<Value> = {
    let beginObject = eatRight(character("{"), spaces)
    let endObject = eatRight(character("}"), spaces)
    let colon = eatRight(character(":"), spaces)
    let comma = eatRight(character(","), spaces)
    let keyValue = and(eatRight(eatRight(quotedString, spaces), colon), eatRight(value, spaces))
    let keyValues = list(keyValue, comma)
    return map(between(beginObject, optional(keyValues), endObject)) {
        var dictionary: [String: Value] = [:]
        let keyValues = $0 ?? []
        for (key, value) in keyValues {
            dictionary[key] = value
        }
        return Value.object(name: "Object", dictionary: dictionary, keys: keyValues.map({ $0.0 }))
    }
}()

private let array: Parser<Value> = {
    let beginArray = eatRight(character("["), spaces)
    let endArray = eatRight(character("]"), spaces)
    let comma = eatRight(character(","), spaces)
    let values = list(eatRight(value, spaces), comma)
    return map(between(beginArray, optional(values), endArray)) { Value.array(name: "Array", values: $0 ?? []) }
}()

public func parse(_ input: String) -> (Value, String)? {
    if _value == nil {
        _value = one(of: [null, bool, number, string, array, object])
    }
    guard let (result, remainder) = value(input.characters) else { return nil }
    return (result, String(remainder))
}

// Map

private let pair: Parser<(String, String)> = {
    let letter = satisfy({ $0 != "," && $0 != ":" })
    let colon = character(":")
    let string = map(many1(letter)) { String($0) }
    let word = eatRight(eatLeft(spaces, string), spaces)
    return map(and(and(word, colon), word)) { ($0.0, $1) }
}()

private let pairs: Parser<[(String, String)]> = {
    return list(pair, character(","))
}()

public func map(of input: String) -> [String: String] {
    guard let (result, _) = pairs(input.characters) else { return [:] }
    var map: [String: String] = [:]
    result.forEach { key, value in
        map[key] = value
    }
    return map
}
