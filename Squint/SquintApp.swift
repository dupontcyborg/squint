import SwiftUI
import Cocoa

@main
struct SquintApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var session = SessionManager.shared
    
    var body: some Scene {
        MenuBarExtra(content: {
            MenuView()
        }, label: {
            Image(systemName: session.state == .inactive ? "sun.max" : "sun.max.fill")
        })
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
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
    @ObservedObject var session = SessionManager.shared
    @State private var launchAtLoginEnabled = LaunchAtLogin.isEnabled
    
    var body: some View {
        Group {
            // 1. Status Section
            switch session.state {
            case .inactive:
                if !session.isAutoBrightnessEnabledInSystem {
                    Text("You don't have auto-brightness enabled")
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
            }) {
                HStack {
                    if launchAtLoginEnabled {
                        Text("✓ Launch at Login")
                    } else {
                        Text("  Launch at Login")
                    }
                }
            }
            
            Divider()
            
            Button("Quit Squint") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onAppear {
            session.updateAutoBrightnessStatus()
            launchAtLoginEnabled = LaunchAtLogin.isEnabled
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        if m > 0 {
            return String(format: "%d min %02d sec", m, s)
        } else {
            return String(format: "%d sec", s)
        }
    }
}
