import Foundation
import os

/// Shared unified-logging handles for Squint.
///
/// Logging via `os.Logger` (rather than `print`) means messages are captured by the
/// system log even when the app is launched normally (not from a terminal), so issues
/// like an orphaned auto-brightness state can be diagnosed after the fact with:
///
///     log show --predicate 'subsystem == "sh.squint.Squint"' --last 1d
enum Log {
    private static let subsystem = "sh.squint.Squint"

    /// Auto-brightness / DisplayServices private API.
    static let display = Logger(subsystem: subsystem, category: "display")
    /// Launch-at-login registration.
    static let launch = Logger(subsystem: subsystem, category: "launch")
}
