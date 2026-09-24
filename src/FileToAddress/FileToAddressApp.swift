import AppKit
import Carbon.HIToolbox
import SwiftUI

@main
struct FileToAddressApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate
    @StateObject private var controller = Controller.shared

    var body: some Scene {
        MenuBarExtra("File to Address", systemImage: "doc.on.clipboard") {
            Button("Insert Finder Selection Path   ⌃⌥⌘V") { controller.insertSelection() }
            Button("Copy Finder Selection Path") { controller.copySelection() }
            Divider()
            Toggle("Launch at Login", isOn: $controller.launchAtLogin)
            if !controller.isTrusted {
                Button("Grant Accessibility Permission…") { controller.requestTrust() }
            }
            Divider()
            Button("Quit File to Address") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: HotKey?

    func applicationDidFinishLaunching(_ notification: Notification) {
        KeepAlive.resolveDuplicates { [self] in
            // Registered only once other copies have quit, since they hold the hot key.
            hotKey = HotKey(keyCode: kVK_ANSI_V, modifiers: controlKey | optionKey | cmdKey) {
                Controller.shared.insertSelection()
            }
            if !TextInserter.isTrusted { TextInserter.requestTrust() }
            KeepAlive.enableByDefaultOnce()
        }
    }
}

@MainActor
final class Controller: ObservableObject {
    static let shared = Controller()

    @Published var isTrusted = TextInserter.isTrusted

    var launchAtLogin: Bool {
        get { KeepAlive.isEnabled }
        set {
            do {
                try KeepAlive.setEnabled(newValue)
            } catch {
                showAlert("Could not change Launch at Login", error.localizedDescription)
            }
            objectWillChange.send()
        }
    }

    private init() {
        // Refresh the permission state whenever the menu might be reopened.
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            Task { @MainActor in
                let trusted = TextInserter.isTrusted
                if trusted != Controller.shared.isTrusted { Controller.shared.isTrusted = trusted }
            }
        }
    }

    func insertSelection() {
        guard let text = selectionText() else { return }
        guard TextInserter.isTrusted else {
            TextInserter.copy(text)
            requestTrust()
            return
        }
        // Let the menu finish closing so the paste lands in the frontmost app.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            TextInserter.insert(text)
        }
    }

    func copySelection() {
        guard let text = selectionText() else { return }
        TextInserter.copy(text)
    }

    func requestTrust() {
        TextInserter.requestTrust()
    }

    private func selectionText() -> String? {
        switch FinderSelection.paths() {
        case .success(let paths) where paths.isEmpty:
            NSSound.beep()
            return nil
        case .success(let paths):
            return AddressFormatter.format(paths)
        case .failure(.scriptError(let message)):
            showAlert(
                "Could not read the Finder selection",
                "\(message)\n\nAllow File to Address to control Finder in System Settings › Privacy & Security › Automation."
            )
            return nil
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
