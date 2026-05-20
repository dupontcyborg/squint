import XCTest
@testable import Squint

final class SessionManagerTests: XCTestCase {
    var tempSentinelURL: URL!

    override func setUp() {
        super.setUp()
        // Define a unique temporary file path for the sentinel during testing
        let tempDir = FileManager.default.temporaryDirectory
        tempSentinelURL = tempDir.appendingPathComponent("squint-test-sentinel-\(UUID().uuidString).json")
    }

    override func tearDown() {
        // Clean up the temporary sentinel file
        try? FileManager.default.removeItem(at: tempSentinelURL)
        super.tearDown()
    }

    func testSessionStartAndCancel() {
        var isMockEnabled = true
        var setCallCount = 0
        var lastSetValue: Bool?

        let manager = SessionManager(
            sentinelURL: tempSentinelURL,
            getBrightness: { isMockEnabled },
            setBrightness: { val in
                setCallCount += 1
                lastSetValue = val
                isMockEnabled = val
                return true
            }
        )

        // Initial state should be inactive
        XCTAssertEqual(manager.state, .inactive)
        XCTAssertTrue(manager.isAutoBrightnessEnabledInSystem)

        // Start an indefinite session
        manager.startSession(duration: nil)

        // State should transition to indefinite
        XCTAssertEqual(manager.state, .indefinite)
        XCTAssertFalse(manager.isAutoBrightnessEnabledInSystem)
        XCTAssertEqual(setCallCount, 1)
        XCTAssertEqual(lastSetValue, false)

        // Cancel the session
        manager.cancelSession()

        // State should return to inactive, restoring original brightness state (true)
        XCTAssertEqual(manager.state, .inactive)
        XCTAssertTrue(manager.isAutoBrightnessEnabledInSystem)
        XCTAssertEqual(setCallCount, 2)
        XCTAssertEqual(lastSetValue, true)
    }

    func testSentinelCrashRecoveryTimedExpired() {
        // Pre-populate the sentinel file to simulate an expired timed session crash
        let expiredDate = Date().addingTimeInterval(-100) // 100 seconds ago

        // JSON structure matching sentinel
        let sentinelJson = """
        {
            "type": {
                "timed": {
                    "endTime": \(expiredDate.timeIntervalSinceReferenceDate)
                }
            },
            "originalState": true
        }
        """
        let sentinelData = Data(sentinelJson.utf8)

        do {
            try sentinelData.write(to: tempSentinelURL)
        } catch {
            XCTFail("Failed to write mock sentinel: \(error)")
        }

        var isMockEnabled = false
        var setCallCount = 0
        var lastSetValue: Bool?

        let manager = SessionManager(
            sentinelURL: tempSentinelURL,
            getBrightness: { isMockEnabled },
            setBrightness: { val in
                setCallCount += 1
                lastSetValue = val
                isMockEnabled = val
                return true
            }
        )

        // Manager should detect the expired sentinel, restore state,
        // delete sentinel, and transition to inactive
        XCTAssertEqual(manager.state, .inactive)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempSentinelURL.path))
        XCTAssertEqual(setCallCount, 1)
        XCTAssertEqual(lastSetValue, true)
    }

    func testSentinelCrashRecoveryIndefinite() {
        // Pre-populate the sentinel file to simulate an active indefinite session
        let sentinelJson = """
        {
            "type": {
                "indefinite": {}
            },
            "originalState": true
        }
        """
        let sentinelData = Data(sentinelJson.utf8)

        do {
            try sentinelData.write(to: tempSentinelURL)
        } catch {
            XCTFail("Failed to write mock sentinel: \(error)")
        }

        var isMockEnabled = true
        var setCallCount = 0
        var lastSetValue: Bool?

        let manager = SessionManager(
            sentinelURL: tempSentinelURL,
            getBrightness: { isMockEnabled },
            setBrightness: { val in
                setCallCount += 1
                lastSetValue = val
                isMockEnabled = val
                return true
            }
        )

        // Manager should load sentinel, keep setting disabled, and transition to .indefinite
        XCTAssertEqual(manager.state, .indefinite)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempSentinelURL.path))
        XCTAssertEqual(setCallCount, 1)
        XCTAssertEqual(lastSetValue, false)
    }
}
