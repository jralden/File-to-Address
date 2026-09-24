import Foundation

/// Turns a list of file paths into the text inserted at the cursor.
enum AddressFormatter {
    /// Paths containing whitespace are wrapped in double quotes so an LLM
    /// reads each one as a single path (macOS screenshot names contain spaces).
    /// Multiple paths are separated by a single space.
    static func format(_ paths: [String]) -> String {
        paths.map(quoteIfNeeded).joined(separator: " ")
    }

    static func quoteIfNeeded(_ path: String) -> String {
        guard path.unicodeScalars.contains(where: CharacterSet.whitespaces.contains) else {
            return path
        }
        return "\"\(path)\""
    }
}
