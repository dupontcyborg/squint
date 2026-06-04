import Foundation
import Cocoa

public class SessionManager: ObservableObject {
    public static let shared = SessionManager()

    public enum SessionState: Equatable {
        case inactive
        case timed(endTime: Date, remaining: TimeInterval)
        case indefinite
    }

    // Internal Sentinel Codable Structures
    private enum SessionType: Codable, Equatable {
        case inactive
        case timed(endTime: Date)
        case indefinite
        case paused(remaining: TimeInterval)
    }

    private struct Sentinel: Codable {
        let type: SessionType
        let originalState: Bool
    }

    @Published public var state: SessionState = .inactive
    @Published public var isAutoBrightnessEnabledInSystem: Bool = true

    private var timer: Timer?
    private var originalAutoBrightnessState: Bool = true
    private let sentinelURL: URL

    // Test hooks for dependency injection
    internal var getAmbientLightCompensation: () -> Bool = {
        DisplayServices.isAmbientLightCompensationEnabled()
    }
    internal var setAmbientLightCompensation: (Bool) -> Bool = { enabled in
        DisplayServices.setAmbientLightCompensation(enabled: enabled)
    }

    // Internal initializer for dependency injection in unit tests
    internal init(
        sentinelURL: URL? = nil,
        getBrightness: (() -> Bool)? = nil,
        setBrightness: ((Bool) -> Bool)? = nil
    ) {
        let fileManager = FileManager.default
        if let customURL = sentinelURL {
            self.sentinelURL = customURL
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let squintDir = appSupport.appendingPathComponent("Squint", isDirectory: true)
            self.sentinelURL = squintDir.appendingPathComponent("sentinel.json")
            try? fileManager.createDirectory(at: squintDir, withIntermediateDirectories: true)
        }

        if let getBrightness = getBrightness {
            self.getAmbientLightCompensation = getBrightness
        }
        if let setBrightness = setBrightness {
            self.setAmbientLightCompensation = setBrightness
        }

        // Fetch current system state
        updateAutoBrightnessStatus()

        // Perform startup recovery
        checkSentinelOnStartup()

        // Listen to sleep/wake notifications
        setupSleepWakeObservers()
    }

    /// Queries the display service for the current auto-brightness state and updates the local state.
    public func updateAutoBrightnessStatus() {
        self.isAutoBrightnessEnabledInSystem = getAmbientLightCompensation()
    }

    /// Re-enables system auto-brightness directly, without starting a suppression session.
    /// Used to recover when auto-brightness is off and no Squint session is active (e.g. an
    /// orphaned off-state left by a shutdown, or a state the user set themselves).
    /// - Returns: `true` if auto-brightness is enabled afterwards.
    @discardableResult
    public func enableAutoBrightness() -> Bool {
        _ = setAmbientLightCompensation(true)
        updateAutoBrightnessStatus()
        return isAutoBrightnessEnabledInSystem
    }

    /// Starts a new auto-brightness suppression session.
    /// - Parameter duration: Optional time interval. If `nil`, the session runs indefinitely.
    public func startSession(duration: TimeInterval?) {
        // Query the state before disabling. If we are already active, keep the original originalState.
        let currentSystemState = getAmbientLightCompensation()
        if case .inactive = self.state {
            self.originalAutoBrightnessState = currentSystemState
        }

        // Turn off auto-brightness
        _ = setAmbientLightCompensation(false)

        if let duration = duration {
            let endTime = Date().addingTimeInterval(duration)
            startTimer(endTime: endTime)
            saveSentinel(type: .timed(endTime: endTime))
        } else {
            stopTimer()
            self.state = .indefinite
            saveSentinel(type: .indefinite)
        }

        updateAutoBrightnessStatus()
    }

    /// Cancels the active session and restores the original auto-brightness state.
    public func cancelSession() {
        stopTimer()
        _ = setAmbientLightCompensation(originalAutoBrightnessState)
        deleteSentinel()
        self.state = .inactive
        updateAutoBrightnessStatus()
    }

    /// Called when the application terminates gracefully.
    public func cleanupOnQuit() {
        if case .inactive = self.state {
            return
        }
        // Revert settings
        _ = setAmbientLightCompensation(originalAutoBrightnessState)
        deleteSentinel()
    }

    private func handleSessionExpiry() {
        cancelSession()
    }

    private func startTimer(endTime: Date) {
        timer?.invalidate()

        let remaining = max(0, endTime.timeIntervalSince(Date()))
        self.state = .timed(endTime: endTime, remaining: remaining)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = Date()
            if now >= endTime {
                self.handleSessionExpiry()
            } else {
                let remaining = endTime.timeIntervalSince(now)
                self.state = .timed(endTime: endTime, remaining: remaining)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Sleep & Wake Logic

    private func setupSleepWakeObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleSleep() {
        // If we are currently in a timed session, pause it
        if case .timed(let endTime, _) = self.state {
            let remaining = max(0, endTime.timeIntervalSince(Date()))
            stopTimer()
            saveSentinel(type: .paused(remaining: remaining))
        }
    }

    @objc private func handleWake() {
        // Check if we have a paused session to resume
        if let sentinel = loadSentinel(), case .paused(let remaining) = sentinel.type {
            let newEndTime = Date().addingTimeInterval(remaining)
            startTimer(endTime: newEndTime)
            saveSentinel(type: .timed(endTime: newEndTime))
        } else {
            updateAutoBrightnessStatus()
        }
    }

    // MARK: - Sentinel Operations

    private func checkSentinelOnStartup() {
        guard let sentinel = loadSentinel() else { return }

        self.originalAutoBrightnessState = sentinel.originalState

        switch sentinel.type {
        case .indefinite:
            _ = setAmbientLightCompensation(false)
            self.state = .indefinite

        case .timed(let endTime):
            let now = Date()
            if now >= endTime {
                // Expired while app was dead
                _ = setAmbientLightCompensation(sentinel.originalState)
                deleteSentinel()
                self.state = .inactive
            } else {
                // Resume session with remaining time
                _ = setAmbientLightCompensation(false)
                startTimer(endTime: endTime)
            }

        case .paused(let remaining):
            // If the app crashed or was closed while the system was asleep
            _ = setAmbientLightCompensation(false)
            let endTime = Date().addingTimeInterval(remaining)
            startTimer(endTime: endTime)
            saveSentinel(type: .timed(endTime: endTime))

        case .inactive:
            deleteSentinel()
            self.state = .inactive
        }
    }

    private func saveSentinel(type: SessionType) {
        let sentinel = Sentinel(type: type, originalState: originalAutoBrightnessState)
        if let data = try? JSONEncoder().encode(sentinel) {
            try? data.write(to: sentinelURL)
        }
    }

    private func loadSentinel() -> Sentinel? {
        guard let data = try? Data(contentsOf: sentinelURL) else { return nil }
        return try? JSONDecoder().decode(Sentinel.self, from: data)
    }

    private func deleteSentinel() {
        try? FileManager.default.removeItem(at: sentinelURL)
    }
}
