import Foundation
import ServiceManagement

public struct LaunchAtLogin {
    /// Check if launch at login is currently registered/enabled for this app.
    public static var isEnabled: Bool {
        get {
            return SMAppService.mainApp.status == .enabled
        }
    }
    
    /// Toggle launch at login status.
    /// - Parameter enable: `true` to register, `false` to unregister.
    /// - Returns: `true` if the toggle succeeded, `false` if an error occurred.
    @discardableResult
    public static func setEnabled(_ enable: Bool) -> Bool {
        do {
            if enable {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            return true
        } catch {
            print("Squint Error: Failed to modify Launch at Login status: \(error)")
            return false
        }
    }
}
