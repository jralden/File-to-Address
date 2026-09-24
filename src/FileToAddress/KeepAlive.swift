import AppKit
import ServiceManagement

/// Runs the app as a launchd agent (bundled in Contents/Library/LaunchAgents)
/// that starts it at login and relaunches it if it crashes. Quitting from the
/// menu exits cleanly, which launchd leaves alone.
enum KeepAlive {
    static let agent = SMAppService.agent(plistName: "com.johnalden.FileToAddress.agent.plist")

    /// Set by the agent plist, so an instance knows launchd is supervising it.
    static let isAgentInstance = ProcessInfo.processInfo.environment["FILE_TO_ADDRESS_AGENT"] == "1"

    private static let didEnableByDefaultKey = "didEnableKeepAliveByDefault"

    static var isEnabled: Bool { agent.status == .enabled }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled { try agent.register() } else { try agent.unregister() }
    }

    /// Turns the agent on the first time the app runs, since the app is meant
    /// to be always available. Turning it off later from the menu sticks.
    static func enableByDefaultOnce() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: didEnableByDefaultKey) else { return }
        defaults.set(true, forKey: didEnableByDefaultKey)
        try? agent.register()
    }

    /// Ensures only one copy runs. The launchd-supervised copy wins: it asks
    /// any other copy to quit. Any other copy quits if one is already running.
    /// Calls `ready` once this copy is the only one.
    static func resolveDuplicates(then ready: @escaping () -> Void) {
        let others = NSRunningApplication
            .runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
            .filter { $0 != .current }
        guard !others.isEmpty else { return ready() }
        guard isAgentInstance else {
            // Exit status 0 so launchd does not treat this as a crash.
            exit(0)
        }
        others.forEach { $0.terminate() }
        waitForExit(of: others, attempt: 0, then: ready)
    }

    private static func waitForExit(of apps: [NSRunningApplication], attempt: Int, then ready: @escaping () -> Void) {
        if apps.allSatisfy(\.isTerminated) || attempt >= 40 {
            apps.filter { !$0.isTerminated }.forEach { $0.forceTerminate() }
            ready()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                waitForExit(of: apps, attempt: attempt + 1, then: ready)
            }
        }
    }
}
