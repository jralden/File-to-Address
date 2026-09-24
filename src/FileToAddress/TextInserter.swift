import AppKit
import ApplicationServices

/// Inserts text at the cursor of the frontmost app by pasting it, then restores
/// the clipboard. Pasting needs the Accessibility permission to post ⌘V.
enum TextInserter {
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system prompt that sends the user to Accessibility settings.
    static func requestTrust() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    static func insert(_ text: String) {
        let pasteboard = NSPasteboard.general
        let saved = snapshot(pasteboard)
        copy(text)
        let changeCount = pasteboard.changeCount

        waitForModifierRelease {
            postCommandV()
            // Give the target app time to read the pasteboard before restoring it.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard pasteboard.changeCount == changeCount else { return }
                pasteboard.clearContents()
                if !saved.isEmpty { pasteboard.writeObjects(saved) }
            }
        }
    }

    /// The hot key's own modifiers may still be held; a paste sent while
    /// ⌃ or ⌥ is down can be read as a different shortcut.
    private static func waitForModifierRelease(attempt: Int = 0, then action: @escaping () -> Void) {
        let held = CGEventSource.flagsState(.combinedSessionState)
            .intersection([.maskControl, .maskAlternate, .maskShift, .maskCommand])
        if held.isEmpty || attempt >= 40 {
            action()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.025) {
                waitForModifierRelease(attempt: attempt + 1, then: action)
            }
        }
    }

    private static func postCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)
        let vKey: CGKeyCode = 0x09
        for keyDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: keyDown)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
        }
    }

    private static func snapshot(_ pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        (pasteboard.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) { copy.setData(data, forType: type) }
            }
            return copy
        }
    }
}
