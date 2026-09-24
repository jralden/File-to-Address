import Foundation

/// Reads the POSIX paths of the items selected in Finder (front window or Desktop).
enum FinderSelection {
    enum Failure: Error {
        case scriptError(String)
    }

    private static let source = """
    tell application "Finder"
        set out to {}
        repeat with anItem in (get selection)
            set end of out to POSIX path of (anItem as alias)
        end repeat
        return out
    end tell
    """

    /// Must be called on the main thread (NSAppleScript is not thread-safe).
    static func paths() -> Result<[String], Failure> {
        guard let script = NSAppleScript(source: source) else {
            return .failure(.scriptError("Could not compile the Finder script."))
        }
        var errorInfo: NSDictionary?
        let descriptor = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error."
            return .failure(.scriptError(message))
        }
        guard descriptor.numberOfItems > 0 else { return .success([]) }
        let paths = (1...descriptor.numberOfItems).compactMap { descriptor.atIndex($0)?.stringValue }
        return .success(paths)
    }
}
