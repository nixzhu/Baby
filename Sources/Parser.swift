
private typealias Stream = String.CharacterView
private typealias Parser<A> = (Stream) -> (A, Stream)?

private func map<A, B>(_ parser: @escaping Parser<A>, _ transform: @escaping (A) -> B) -> Parser<B> {
    let newParser: Parser<B> = { stream in
        guard let (result, remainder) = parser(stream) else { return nil }
        return (transform(result), remainder)
    }
    return newParser
}

private func or<A>(_ leftParser: @escaping Parser<A>, _ rightParser: @escaping Parser<A>) -> Parser<A> {
    let parser: Parser<A> = { stream in
        return leftParser(stream) ?? rightParser(stream)
    }
    return parser
}

private func one<A>(of parsers: [Parser<A>]) -> Parser<A> {
    let parser: Parser<A> = { stream in
        for parser in parsers {
            if let x = parser(stream) {
                return x
            }
        }
        return nil
    }
    return parser
}

private func many<A>(_ parser: @escaping Parser<A>) -> Parser<[A]> {
    let parser: Parser<[A]> = { stream in
        var result = [A]()
        var remainder = stream
        while let (element, newRemainder) = parser(remainder) {
            result.append(element)
            remainder = newRemainder
        }
        return (result, remainder)
    }
    return parser
}

private func many1<A>(_ parser: @escaping Parser<A>) -> Parser<[A]> {
    let parser: Parser<[A]> = { stream in
        guard let (element, remainder1) = parser(stream) else { return nil }
        if let (array, remainder2) = many(parser)(remainder1) {
            return ([element] + array, remainder2)
        } else {
            return ([element], remainder1)
        }
    }
    return parser
}

private func between<A, B, C>(_ a: @escaping Parser<A>, _ b: @escaping Parser<B>, _ c: @escaping Parser<C>) -> Parser<B> {
    let parser: Parser<B> = { stream in
        guard let (_, remainder1) = a(stream) else { return nil }
        guard let (result2, remainder2) = b(remainder1) else { return nil }
        guard let (_, remainder3) = c(remainder2) else { return nil }
        return (result2, remainder3)
    }
    return parser
}

private func and<A, B>(_ left: @escaping Parser<A>, _ right: @escaping Parser<B>) -> Parser<(A, B)> {
    return { stream in
        guard let (result1, remainder1) = left(stream) else { return nil }
        guard let (result2, remainder2) = right(remainder1) else { return nil }
        return ((result1, result2), remainder2)
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
    let parser: Parser<Character> = { stream in
        guard let firstCharacter = stream.first, firstCharacter == character else { return nil }
        return (firstCharacter, stream.dropFirst())
    }
    return parser
}

private func word(_ string: String) -> Parser<String> {
    let parsers = string.characters.map({ character($0) })
    let parser: Parser<String> = { stream in
        var characters: [Character] = []
        var remainder = stream
        for parser in parsers {
            guard let (character, newRemainder) = parser(remainder) else { return nil }
            characters.append(character)
            remainder = newRemainder
        }
        return (String(characters), remainder)
    }
    return parser
}

// Parsers

private let null: Parser<Value> = map(word("null")) { _ in Value.null }

private let bool: Parser<Value> = {
    let `true` = map(word("true")) { _ in true }
    let `false` = map(word("false")) { _ in false }
    return map(or(`true`, `false`)) { bool in Value.bool(bool) }
}()

private let number: Parser<Value> = {
    let digitCharacters = "0123456789.-".characters.map { $0 }
    let digitParsers = digitCharacters.map { character($0) }
    let digit = one(of: digitParsers)
    return map(many1(digit)) {
        let numberString = String($0)
        if let int = Int(numberString) {
            return Value.number(.int(int))
        } else {
            let double = Double(numberString)!
            return Value.number(.double(double))
        }
    }
}()

private let quotedString: Parser<String> = {
    let unescapedCharacter = satisfy({ $0 != "\\" && $0 != "\"" })
    let escapedCharacter = one(of: [
        map(word("\\\"")) { _ in Character("\"") },
        map(word("\\\\")) { _ in Character("\\") },
        map(word("\\/")) { _ in Character("/") },
        /*
        map(word("\\b")) { _ in Character("\b") },
        map(word("\\f")) { _ in Character("\f") },
         */
        map(word("\\n")) { _ in Character("\n") },
        map(word("\\r")) { _ in Character("\r") },
        map(word("\\t")) { _ in Character("\t") },
        ]
    )
    let letter = one(of: [unescapedCharacter, escapedCharacter])
    let _string = map(many1(letter)) { String($0) }
    let quote = character("\"")
    return between(quote, _string, quote)
}()

private let string: Parser<Value> = map(quotedString) { Value.string($0) }

private var _value: Parser<Value>?
private let value: Parser<Value> = { stream in
    if let parser = _value {
        return parser(stream)
    }
    return nil
}

private let object: Parser<Value> = {
    let beginObject = character("{")
    let endObject = character("}")
    let colon = character(":")
    let comma = character(",")
    let keyValue = and(eatRight(quotedString, colon), value)
    let keyValues = list(keyValue, comma)
    return map(between(beginObject, keyValues, endObject)) {
        var dictionary: [String: Value] = [:]
        for (key, value) in $0 {
            dictionary[key] = value
        }
        return Value.object(dictionary)
    }
}()

private let array: Parser<Value> = {
    let beginArray = character("[")
    let endArray = character("]")
    let comma = character(",")
    let values = list(value, comma)
    return map(between(beginArray, values, endArray)) { Value.array($0) }
}()

public func parse(_ input: String) -> (Value, String)? {
    _value = one(of: [null, bool, number, string, array, object])
    guard let (result, remainder) = value(input.characters) else { return nil }
    return (result, String(remainder))
}
