import Foundation

public enum ShopNameValidationError: Error, Equatable, Sendable {
    case empty
    case tooShort
    case tooLong
    case containsControlCharacters
}

public enum ShopNameValidator {
    public static let minimumLength = 2
    public static let maximumLength = 24

    public static func normalized(_ rawValue: String) throws -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let collapsed = trimmed
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")

        guard !collapsed.isEmpty else {
            throw ShopNameValidationError.empty
        }

        guard collapsed.count >= minimumLength else {
            throw ShopNameValidationError.tooShort
        }

        guard collapsed.count <= maximumLength else {
            throw ShopNameValidationError.tooLong
        }

        guard collapsed.unicodeScalars.allSatisfy({
            !CharacterSet.controlCharacters.contains($0)
        }) else {
            throw ShopNameValidationError.containsControlCharacters
        }

        return collapsed
    }
}
