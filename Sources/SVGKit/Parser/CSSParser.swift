//
//  CSSParser.swift
//  SVGKit
//
//  Created by maralla on 2025/4/8.
//

import Foundation

// MARK: - CSS Parser Models

// Represents a CSS declaration (property: value)
struct CSSDeclaration {
    let property: String
    let value: String
}

// Represents a CSS rule with selectors and declarations
struct CSSRule {
    let selector: CSSSelector
    let declarations: [CSSDeclaration]

    var properties: [String: String] {
        var ret: [String: String] = [:]
        for declaration in declarations {
            ret[declaration.property] = declaration.value
        }
        return ret
    }
}

struct CSSSelector {
    var value: String
    var specificity: (Int, Int, Int)

    init(_ selector: String) {
        self.value = selector
        self.specificity = Self.specificity(for: selector)
    }

    private static func specificity(for selector: String) -> (Int, Int, Int) {
        var a = 0, b = 0, c = 0
        var i = selector.startIndex

        while i < selector.endIndex {
            let ch = selector[i]

            switch ch {
            case "#":
                a += 1
                i = skipIdentifier(from: selector.index(after: i), in: selector)
            case ".":
                b += 1
                i = skipIdentifier(from: selector.index(after: i), in: selector)
            case "[":
                b += 1
                i = skipUntil("]", from: i, in: selector)
            case ":":
                let next = selector.index(after: i)
                if next < selector.endIndex && selector[next] == ":" {
                    // Pseudo-element
                    c += 1
                    i = skipIdentifier(from: selector.index(next, offsetBy: 1), in: selector)
                } else {
                    // Pseudo-class
                    b += 1
                    i = skipIdentifier(from: next, in: selector)
                }
            case "*", " ", ">", "+", "~", ",":
                i = selector.index(after: i)
            default:
                if ch.isLetter {
                    c += 1
                    i = skipIdentifier(from: i, in: selector)
                } else {
                    i = selector.index(after: i)
                }
            }
        }

        return (a, b, c)
    }

    private static func skipIdentifier(from index: String.Index, in str: String) -> String.Index {
        var i = index
        while i < str.endIndex && (str[i].isLetter || str[i].isNumber || str[i] == "-" || str[i] == "_") {
            i = str.index(after: i)
        }
        return i
    }

    private static func skipUntil(_ char: Character, from index: String.Index, in str: String) -> String.Index {
        var i = str.index(after: index)
        while i < str.endIndex && str[i] != char {
            i = str.index(after: i)
        }
        return i < str.endIndex ? str.index(after: i) : i
    }
}

// Represents a CSS keyframe rule
struct CSSKeyframeRule {
    let name: String
    let keyframes: [CSSKeyframe]
}

// Represents a keyframe in a keyframe animation
struct CSSKeyframe {
    let selector: String  // e.g., "from", "to", "50%"
    let declarations: [CSSDeclaration]
}

// Represents a parsed CSS stylesheet
struct CSSStylesheet {
    let rules: [CSSRule]
    let keyframeRules: [CSSKeyframeRule]
}

enum CSSCombinator: String {
    case descendant = " "
    case child = ">"
    case adjacentSibling = "+"
    case generalSibling = "~"
}

struct CSSCompoundSelector {
    var tag: String?
    var id: String?
    var classes: [String]
    var attributes: [String: String?]
    var pseudoClasses: [String]
    var pseudoElement: String?
}

struct CSSSelectorComponent {
    var combinator: CSSCombinator?
    var selector: CSSCompoundSelector
}

struct CSSSelectorGroup {
    var components: [CSSSelectorComponent] = []

    init(_ input: String) {
        components = parseSelectorChain(input.trimmingCharacters(in: .whitespaces))
    }

    private func parseSelectorChain(_ input: String) -> [CSSSelectorComponent] {
        var components: [CSSSelectorComponent] = []
        var current = CSSCompoundSelector(
            tag: nil,
            id: nil,
            classes: [],
            attributes: [:],
            pseudoClasses: [],
            pseudoElement: nil
        )
        var combinator: CSSCombinator? = nil
        var buffer = ""
        var i = input.startIndex
        let end = input.endIndex

        func flushBufferAsTag() {
            let trimmed = buffer.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty && current.tag == nil {
                current.tag = trimmed
            }
            buffer = ""
        }

        while i < end {
            let char = input[i]
            let next = input.index(after: i)

            switch char {
            case " ", ">", "+", "~":
                flushBufferAsTag()
                if !currentIsEmpty(current) {
                    components.append(.init(combinator: combinator, selector: current))
                    current = CSSCompoundSelector(
                        tag: nil,
                        id: nil,
                        classes: [],
                        attributes: [:],
                        pseudoClasses: [],
                        pseudoElement: nil
                    )
                }

                combinator =
                    (char == " "
                        ? .descendant : char == ">" ? .child : char == "+" ? .adjacentSibling : .generalSibling)

                // Skip over any extra whitespace
                i = next
                while i < end && input[i] == " " {
                    i = input.index(after: i)
                }
                continue

            case "#":
                flushBufferAsTag()
                i = input.index(after: i)
                let (value, newI) = consumeWhile(from: i, in: input) {
                    $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_"
                }
                current.id = value
                i = newI
                continue

            case ".":
                flushBufferAsTag()
                i = input.index(after: i)
                let (value, newI) = consumeWhile(from: i, in: input) {
                    $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_"
                }
                current.classes.append(value)
                i = newI
                continue

            case ":":
                flushBufferAsTag()
                i = input.index(after: i)
                if i < end && input[i] == ":" {
                    i = input.index(after: i)
                    let (value, newI) = consumeWhile(from: i, in: input) {
                        $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_"
                    }
                    current.pseudoElement = value
                    i = newI
                } else {
                    let (value, newI) = consumeWhile(from: i, in: input) {
                        $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_"
                    }
                    current.pseudoClasses.append(value)
                    i = newI
                }
                continue

            case "[":
                flushBufferAsTag()
                i = input.index(after: i)
                let (name, midI) = consumeWhile(from: i, in: input) { $0 != "=" && $0 != "]" && !$0.isWhitespace }
                var attrValue: String? = nil
                var j = midI

                // Skip whitespace
                while j < end && input[j].isWhitespace { j = input.index(after: j) }

                if j < end && input[j] == "=" {
                    j = input.index(after: j)

                    // Skip whitespace
                    while j < end && input[j].isWhitespace { j = input.index(after: j) }

                    if j < end && input[j] == "\"" {
                        j = input.index(after: j)
                        let (value, valueEnd) = consumeWhile(from: j, in: input) { $0 != "\"" }
                        attrValue = value
                        j = valueEnd
                        if j < end && input[j] == "\"" {
                            j = input.index(after: j)
                        }
                    }
                }

                // Move j to after the closing ']'
                while j < end && input[j] != "]" {
                    j = input.index(after: j)
                }
                if j < end && input[j] == "]" {
                    j = input.index(after: j)
                }

                current.attributes[name] = attrValue
                i = j
                continue

            default:
                buffer.append(char)
                i = next
            }
        }

        flushBufferAsTag()
        if !currentIsEmpty(current) {
            components.append(.init(combinator: combinator, selector: current))
        }

        return components
    }

    private func currentIsEmpty(_ selector: CSSCompoundSelector) -> Bool {
        return selector.tag == nil && selector.id == nil && selector.classes.isEmpty && selector.attributes.isEmpty
            && selector.pseudoClasses.isEmpty && selector.pseudoElement == nil
    }

    private func consumeWhile(
        from index: String.Index,
        in input: String,
        condition: (Character) -> Bool
    ) -> (String, String.Index) {
        var i = index
        var result = ""
        while i < input.endIndex && condition(input[i]) {
            result.append(input[i])
            i = input.index(after: i)
        }
        return (result, i)
    }
}

// MARK: - CSS Parser

enum CSSParserError: Error {
    case invalidCSS(message: String)
    case unexpectedCharacter(character: Character, position: Int)
    case unexpectedEndOfInput
}

public class CSSParser {
    private let input: String
    private var position: String.Index

    init(input: String) {
        self.input = input
        self.position = input.startIndex
    }

    // MARK: - Public Methods

    func parse() throws -> CSSStylesheet {
        var rules: [CSSRule] = []
        var keyframeRules: [CSSKeyframeRule] = []

        skipWhitespace()

        while !isAtEnd() {
            // Check if it's a keyframe rule
            if peekString(4) == "@key" {
                let keyframeRule = try parseKeyframeRule()
                keyframeRules.append(keyframeRule)
            } else {
                let items = try parseRule()
                rules.append(contentsOf: items)
            }

            skipWhitespace()
        }

        rules.sort(by: { $0.selector.specificity < $1.selector.specificity })

        return CSSStylesheet(rules: rules, keyframeRules: keyframeRules)
    }

    // MARK: - Private Parsing Methods

    private func parseRule() throws -> [CSSRule] {
        // Parse selectors
        let selectors = try parseSelectors()
        skipWhitespace()

        // Expect opening brace
        guard !isAtEnd() && currentChar() == "{" else {
            throw CSSParserError.invalidCSS(message: "Expected '{' after selectors")
        }
        advance()

        // Parse declarations
        let declarations = try parseDeclarations()

        // Expect closing brace
        guard !isAtEnd() && currentChar() == "}" else {
            throw CSSParserError.invalidCSS(message: "Expected '}' after declarations")
        }
        advance()

        var ret: [CSSRule] = []
        for selector in selectors {
            ret.append(.init(selector: .init(selector), declarations: declarations))
        }

        return ret
    }

    private func parseKeyframeRule() throws -> CSSKeyframeRule {
        // Parse @keyframes directive
        guard consume(string: "@keyframes") else {
            throw CSSParserError.invalidCSS(message: "Expected @keyframes")
        }

        skipWhitespace()

        // Parse keyframe name
        let name = try parseIdentifier()
        skipWhitespace()

        // Expect opening brace
        guard !isAtEnd() && currentChar() == "{" else {
            throw CSSParserError.invalidCSS(message: "Expected '{' after keyframe name")
        }
        advance()
        skipWhitespace()

        // Parse keyframes
        var keyframes: [CSSKeyframe] = []

        while !isAtEnd() && currentChar() != "}" {
            let keyframe = try parseKeyframe()
            keyframes.append(keyframe)
            skipWhitespace()
        }

        // Expect closing brace
        guard !isAtEnd() && currentChar() == "}" else {
            throw CSSParserError.invalidCSS(message: "Expected '}' after keyframe declarations")
        }
        advance()

        return CSSKeyframeRule(name: name, keyframes: keyframes)
    }

    private func parseKeyframe() throws -> CSSKeyframe {
        // Parse keyframe selector (from, to, or percentage)
        let selector = try parseKeyframeSelector()
        skipWhitespace()

        // Expect opening brace
        guard !isAtEnd() && currentChar() == "{" else {
            throw CSSParserError.invalidCSS(message: "Expected '{' after keyframe selector")
        }
        advance()

        // Parse declarations
        let declarations = try parseDeclarations()

        // Expect closing brace
        guard !isAtEnd() && currentChar() == "}" else {
            throw CSSParserError.invalidCSS(message: "Expected '}' after keyframe declarations")
        }
        advance()

        return CSSKeyframe(selector: selector, declarations: declarations)
    }

    private func parseKeyframeSelector() throws -> String {
        if consume(string: "from") {
            return "from"
        } else if consume(string: "to") {
            return "to"
        } else {
            // Should be a percentage
            let start = position

            // Parse digits
            while !isAtEnd() && (currentChar().isNumber || currentChar() == ".") {
                advance()
            }

            // Expect % character
            guard !isAtEnd() && currentChar() == "%" else {
                throw CSSParserError.invalidCSS(message: "Expected percentage in keyframe selector")
            }
            advance()

            return String(input[start..<position])
        }
    }

    private func parseSelectors() throws -> [String] {
        var selectors: [String] = []

        while !isAtEnd() && currentChar() != "{" {
            // Find the end of the current selector
            let start = position

            while !isAtEnd() && currentChar() != "," && currentChar() != "{" {
                advance()
            }

            let selector = input[start..<position].trimmingCharacters(in: .whitespacesAndNewlines)
            if !selector.isEmpty {
                selectors.append(selector)
            }

            // If we hit a comma, skip it and continue parsing selectors
            if !isAtEnd() && currentChar() == "," {
                advance()
                skipWhitespace()
            }
        }

        if selectors.isEmpty {
            throw CSSParserError.invalidCSS(message: "Expected at least one selector")
        }

        return selectors
    }

    private func parseDeclarations() throws -> [CSSDeclaration] {
        var declarations: [CSSDeclaration] = []

        skipWhitespace()

        while !isAtEnd() && currentChar() != "}" {
            let declaration = try parseDeclaration()
            declarations.append(declaration)

            // Skip semicolon and whitespace
            if !isAtEnd() && currentChar() == ";" {
                advance()
            }
            skipWhitespace()
        }

        return declarations
    }

    private func parseDeclaration() throws -> CSSDeclaration {
        // Parse property name
        let property = try parseIdentifier()
        skipWhitespace()

        // Expect colon
        guard !isAtEnd() && currentChar() == ":" else {
            throw CSSParserError.invalidCSS(message: "Expected ':' after property name")
        }
        advance()
        skipWhitespace()

        // Parse value
        let value = try parseDeclarationValue()

        return CSSDeclaration(property: property, value: value)
    }

    private func parseIdentifier() throws -> String {
        guard !isAtEnd() else {
            throw CSSParserError.unexpectedEndOfInput
        }

        let start = position

        // First character must be a letter, underscore, or hyphen
        if !(currentChar().isLetter || currentChar() == "_" || currentChar() == "-") {
            throw CSSParserError.invalidCSS(message: "Identifier must start with a letter, underscore, or hyphen")
        }

        advance()

        // Subsequent characters can be letters, digits, underscores, or hyphens
        while !isAtEnd()
            && (currentChar().isLetter || currentChar().isNumber || currentChar() == "_" || currentChar() == "-")
        {
            advance()
        }

        return String(input[start..<position])
    }

    private func parseDeclarationValue() throws -> String {
        let start = position

        var depth = 0
        var inQuotes = false
        var quoteChar: Character? = nil

        while !isAtEnd() {
            let char = currentChar()

            if (char == ";" || char == "}") && depth == 0 && !inQuotes {
                break
            }

            if (char == "\"" || char == "'") && (quoteChar == nil || quoteChar == char) {
                inQuotes = !inQuotes
                if inQuotes {
                    quoteChar = char
                } else {
                    quoteChar = nil
                }
            }

            if char == "(" && !inQuotes {
                depth += 1
            } else if char == ")" && !inQuotes {
                depth -= 1
                if depth < 0 {
                    throw CSSParserError.unexpectedCharacter(
                        character: char,
                        position: input.distance(from: input.startIndex, to: position)
                    )
                }
            }

            advance()
        }

        return String(input[start..<position]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Helper Methods

    private func isAtEnd() -> Bool {
        return position >= input.endIndex
    }

    private func currentChar() -> Character {
        return input[position]
    }

    private func advance() {
        position = input.index(after: position)
    }

    private func skipWhitespace() {
        while !isAtEnd()
            && (currentChar().isWhitespace || currentChar() == "\n" || currentChar() == "\r" || currentChar() == "\t")
        {
            advance()
        }
    }

    private func consume(string: String) -> Bool {
        var tempPosition = position

        for char in string {
            if tempPosition >= input.endIndex || input[tempPosition] != char {
                return false
            }
            tempPosition = input.index(after: tempPosition)
        }

        position = tempPosition
        return true
    }

    private func peekString(_ length: Int) -> String {
        var result = ""
        var tempPosition = position
        var count = 0

        while count < length && tempPosition < input.endIndex {
            result.append(input[tempPosition])
            tempPosition = input.index(after: tempPosition)
            count += 1
        }

        return result
    }
}
