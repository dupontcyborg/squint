import Foundation
import CoreGraphics

public struct DisplayServices {
    private static let frameworkPath = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"

    // Private API Function Signatures
    // void DisplayServicesEnableAmbientLightCompensation(CGDirectDisplayID display, boolean_t enable)
    private typealias EnableCompFunc = @convention(c) (CGDirectDisplayID, Int32) -> Void
    // boolean_t DisplayServicesAmbientLightCompensationEnabled(CGDirectDisplayID display, boolean_t *enabled)
    private typealias GetCompFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Int32>) -> Int32

    private static var enableFunc: EnableCompFunc?
    private static var getFunc: GetCompFunc?

    private static var isInitialized: Bool = {
        guard let handle = dlopen(frameworkPath, RTLD_NOW) else {
            let reason = String(cString: dlerror())
            Log.display.warning("Failed to load DisplayServices framework: \(reason, privacy: .public)")
            return false
        }

        if let enableSym = dlsym(handle, "DisplayServicesEnableAmbientLightCompensation") {
            enableFunc = unsafeBitCast(enableSym, to: EnableCompFunc.self)
        } else {
            Log.display.warning("Symbol DisplayServicesEnableAmbientLightCompensation not found.")
        }

        if let getSym = dlsym(handle, "DisplayServicesAmbientLightCompensationEnabled") {
            getFunc = unsafeBitCast(getSym, to: GetCompFunc.self)
        } else {
            Log.display.warning("Symbol DisplayServicesAmbientLightCompensationEnabled not found.")
        }

        return enableFunc != nil && getFunc != nil
    }()

    /// Set ambient light compensation (auto-brightness) state for the main display.
    /// - Parameter enabled: `true` to enable auto-brightness, `false` to disable it.
    /// - Returns: `true` if the state was applied and reads back as requested, `false` otherwise.
    @discardableResult
    public static func setAmbientLightCompensation(enabled: Bool) -> Bool {
        _ = isInitialized
        guard let enableFunc = enableFunc else {
            Log.display.error("Cannot set ambient light compensation; private API not available.")
            return false
        }
        let mainDisplay = CGMainDisplayID()
        enableFunc(mainDisplay, enabled ? 1 : 0)
        // The private setter returns no status, so verify by reading the value back.
        // This catches silent no-ops (e.g. during display teardown at shutdown).
        return isAmbientLightCompensationEnabled() == enabled
    }

    /// Query ambient light compensation (auto-brightness) state for the main display.
    /// - Returns: `true` if auto-brightness is enabled, `false` if disabled or if the API call fails.
    public static func isAmbientLightCompensationEnabled() -> Bool {
        _ = isInitialized
        guard let getFunc = getFunc else {
            Log.display.error("Cannot query ambient light compensation; private API not available.")
            return false
        }
        let mainDisplay = CGMainDisplayID()
        var enabledVal: Int32 = 0
        let result = getFunc(mainDisplay, &enabledVal)

        // In the private API, the return value or the pointer value indicates state.
        // Usually, the return value is boolean_t indicating if it succeeded or the state itself,
        // and enabledVal is filled with the boolean state.
        // We check both values to be robust against Apple Silicon/Intel framework differences.
        return enabledVal != 0 || result != 0
    }
}
