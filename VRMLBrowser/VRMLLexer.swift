import Foundation

enum VRMLToken: Equatable, CustomStringConvertible {
    case openBrace
    case closeBrace
    case openBracket
    case closeBracket
    case identifier(String)
    case number(Double)
    case string(String)
    case keyword(String) // DEF, USE, etc.
    case comma
    case eof
    
    var description: String {
        switch self {
        case .openBrace: return "{"
        case .closeBrace: return "}"
        case .openBracket: return "["
        case .closeBracket: return "]"
        case .identifier(let s): return "ID(\(s))"
        case .number(let n): return "NUM(\(n))"
        case .string(let s): return "STR(\"\(s)\")"
        case .keyword(let k): return "KW(\(k))"
        case .comma: return ","
        case .eof: return "EOF"
        }
    }
}

class VRMLLexer {
    private let input: String
    private var index: String.Index
    
    init(input: String) {
        self.input = input
        self.index = input.startIndex
    }
    
    func nextToken() -> VRMLToken {
        skipWhitespaceAndComments()
        
        guard index < input.endIndex else { return .eof }
        
        let char = input[index]
        
        switch char {
        case "{":
            advance()
            return .openBrace
        case "}":
            advance()
            return .closeBrace
        case "[":
            advance()
            return .openBracket
        case "]":
            advance()
            return .closeBracket
        case ",":
            advance()
            return .comma
        case "\"":
            return readString()
        case _ where char.isNumber || char == "-" || char == "+" || char == ".":
            return readNumber()
        case _ where isIdentifierStart(char):
            return readIdentifier()
        default:
            // Unknown character, skip it
            advance()
            return nextToken()
        }
    }
    
    private func advance() {
        index = input.index(after: index)
    }
    
    private func skipWhitespaceAndComments() {
        while index < input.endIndex {
            let char = input[index]
            if char.isWhitespace || char == "," {
                advance()
            } else if char == "#" {
                // Skip comment until newline
                while index < input.endIndex && !input[index].isNewline {
                    advance()
                }
            } else {
                break
            }
        }
    }
    
    private func readString() -> VRMLToken {
        advance() // Skip opening quote
        var str = ""
        while index < input.endIndex {
            let char = input[index]
            if char == "\"" {
                advance() // Skip closing quote
                return .string(str)
            }
            str.append(char)
            advance()
        }
        return .string(str) // Unterminated string
    }
    
    private func readNumber() -> VRMLToken {
        var numStr = ""
        while index < input.endIndex {
            let char = input[index]
            if char.isNumber || char == "." || char == "-" || char == "+" || char == "e" || char == "E" {
                numStr.append(char)
                advance()
            } else {
                break
            }
        }
        if let num = Double(numStr) {
            return .number(num)
        }
        return .identifier(numStr) // Fallback if invalid number
    }
    
    private func readIdentifier() -> VRMLToken {
        var idStr = ""
        while index < input.endIndex {
            let char = input[index]
            if isIdentifierChar(char) {
                idStr.append(char)
                advance()
            } else {
                break
            }
        }
        
        if idStr == "DEF" || idStr == "USE" {
            return .keyword(idStr)
        }
        
        return .identifier(idStr)
    }
    
    private func isIdentifierStart(_ char: Character) -> Bool {
        return char.isLetter || char == "_"
    }
    
    private func isIdentifierChar(_ char: Character) -> Bool {
        return char.isLetter || char.isNumber || char == "_" || char == "-"
    }
}
