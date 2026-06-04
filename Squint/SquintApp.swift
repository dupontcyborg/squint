import SwiftUI
import Cocoa
import Sparkle

@main
struct SquintApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var session = SessionManager.shared

    var body: some Scene {
        MenuBarExtra(content: {
            MenuView(updater: appDelegate.updaterController.updater)
        }, label: {
            Image(systemName: session.state == .inactive ? "sun.max" : "sun.max.fill")
        })
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    // Sparkle's standard controller. `startingUpdater: true` lets it run scheduled
    // background checks per SUEnableAutomaticChecks in Info.plist.
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory (menu-bar only, no Dock icon or normal app windows)
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Restore original auto-brightness state and clear the sentinel file on quit
        SessionManager.shared.cleanupOnQuit()
    }
}

struct MenuView: View {
    let updater: SPUUpdater
    @ObservedObject var session = SessionManager.shared
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    @State private var canCheckForUpdates = true

    private var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    var body: some View {
        Group {
            // 1. Status Section
            switch session.state {
            case .inactive:
                if !session.isAutoBrightnessEnabledInSystem {
                    Text("Auto-Brightness: Off")
                    Button("Enable Auto-Brightness") {
                        session.enableAutoBrightness()
                    }
                    Divider()
                } else {
                    Text("Auto-Brightness: Enabled")
                    Divider()
                }
            case .timed(_, let remaining):
                Text("Auto-Brightness: Temporarily Disabled")
                Text("Remaining: \(formatTime(remaining))")
                Button("Cancel Session") {
                    session.cancelSession()
                }
                Divider()
            case .indefinite:
                Text("Auto-Brightness: Disabled Indefinitely")
                Button("Cancel Session") {
                    session.cancelSession()
                }
                Divider()
            }

            // 2. Durations Section (shown/enabled only if inactive and system auto-brightness is on)
            if session.state == .inactive {
                let isDisabled = !session.isAutoBrightnessEnabledInSystem

                Button("For 15 Minutes") {
                    session.startSession(duration: 15 * 60)
                }
                .disabled(isDisabled)

                Button("For 30 Minutes") {
                    session.startSession(duration: 30 * 60)
                }
                .disabled(isDisabled)

                Button("For 1 Hour") {
                    session.startSession(duration: 60 * 60)
                }
                .disabled(isDisabled)

                Button("For 2 Hours") {
                    session.startSession(duration: 2 * 60 * 60)
                }
                .disabled(isDisabled)

                Button("Indefinitely") {
                    session.startSession(duration: nil)
                }
                .disabled(isDisabled)

                Divider()
            }

            // 3. Settings
            Button(action: {
                let nextState = !launchAtLoginEnabled
                if LaunchAtLogin.setEnabled(nextState) {
                    launchAtLoginEnabled = nextState
                }
            }, label: {
                Text(launchAtLoginEnabled ? "✓ Launch at Login" : "Launch at Login")
            })

            Button("Check for Updates…") {
                updater.checkForUpdates()
            }
            .disabled(!canCheckForUpdates)
            .help("Squint v\(versionString)")

            Divider()

            Button("Quit Squint") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onAppear {
            session.updateAutoBrightnessStatus()
            launchAtLoginEnabled = LaunchAtLogin.isEnabled
        }
        .onReceive(updater.publisher(for: \.canCheckForUpdates)) { canCheckForUpdates = $0 }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        if minutes > 0 {
            return String(format: "%d min %02d sec", minutes, remainingSeconds)
        } else {
            return String(format: "%d sec", remainingSeconds)
        }
    }
}
