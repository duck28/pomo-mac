import Foundation

func XCTAssertTrue(_ value: Bool) { precondition(value) }
func XCTAssertFalse(_ value: Bool) { precondition(!value) }
func XCTAssertNil<T>(_ value: T?) { precondition(value == nil) }
func XCTAssertEqual<T: Equatable>(_ actual: T, _ expected: T) { precondition(actual == expected, "Expected \(expected), got \(actual)") }

@main struct FocusStateTests {
    static func main() throws {
        let tests = FocusStateTests()
        tests.testCompletionAwardsOnceAfterSleep()
        tests.testPauseResumeAndResetDoNotAwardTreats()
        tests.testFourthFocusGetsLongBreakAndBreakDoesNotReward()
        tests.testFeedingAndGrowth()
        tests.testReactionPhases()
        try tests.testTimeBasedRewards()
        try tests.testFocusDurationChanges()
        try tests.testSwitchKeepsProgress()
        try tests.testAllCompanionsAndRunningTimerRoundTrip()
        print("Passed 9 checks (including companion switching and reaction timing): completion, pause/reset, breaks, growth, and all-companion persistence.")
    }
    let start = Date(timeIntervalSince1970: 1_000_000)

    func testTimeBasedRewards() throws {
        for (minutes, reward) in [(1, 0), (10, 2), (15, 3), (25, 5), (30, 6), (45, 9), (60, 12), (180, 36)] {
            var state = FocusState()
            state.selectFocusMinutes(minutes)
            state.start(at: start)
            state.advance(to: start.addingTimeInterval(Double(minutes * 60)))
            XCTAssertEqual(state.treats, reward)
        }
        var state = FocusState()
        state.selectFocusMinutes(3)
        state.start(at: start)
        state.advance(to: start.addingTimeInterval(180))
        XCTAssertEqual(state.treats, 0)
        XCTAssertEqual(state.minutesTowardNextTreat, 3)
        state = try JSONDecoder().decode(FocusState.self, from: JSONEncoder().encode(state))
        state.changeCompanion(to: .ember)
        state.start(at: start.addingTimeInterval(180))
        state.advance(to: start.addingTimeInterval(480))
        state.selectFocusMinutes(4)
        state.start(at: start.addingTimeInterval(480))
        state.advance(to: start.addingTimeInterval(720))
        XCTAssertEqual(state.treats, 1)
        XCTAssertEqual(state.minutesTowardNextTreat, 2)
        state.reset()
        XCTAssertEqual(state.minutesTowardNextTreat, 2)
        XCTAssertTrue(state.feed())
        XCTAssertEqual(state.minutesTowardNextTreat, 2)
        var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as! [String: Any]
        legacy.removeValue(forKey: "rewardMinutesRemainder")
        let restored = try JSONDecoder().decode(FocusState.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(restored.treats, state.treats)
        XCTAssertEqual(restored.fedTreats, state.fedTreats)
        XCTAssertEqual(restored.minutesTowardNextTreat, 0)
    }

    func testFocusDurationChanges() throws {
        var state = FocusState()
        XCTAssertTrue(state.selectFocusMinutes(10))
        XCTAssertEqual(state.remaining, 600)
        state.start(at: start)
        let deadline = state.deadline
        XCTAssertTrue(state.selectFocusMinutes(45))
        XCTAssertEqual(state.deadline, deadline)
        XCTAssertEqual(state.focusMinutes, 10)
        state.pause(at: start.addingTimeInterval(60))
        XCTAssertTrue(state.selectFocusMinutes(60))
        XCTAssertEqual(state.remaining, 540)
        state = try JSONDecoder().decode(FocusState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(state.nextFocusMinutes, 60)
        state.start(at: start.addingTimeInterval(60))
        state.advance(to: start.addingTimeInterval(600))
        XCTAssertEqual(state.focusedMinutes, 10)
        XCTAssertEqual(state.treats, 2)
        XCTAssertEqual(state.focusMinutes, 60)
        XCTAssertEqual(state.remaining, 300)
        XCTAssertTrue(state.selectFocusMinutes(30))
        XCTAssertEqual(state.remaining, 300)
        state.start(at: start.addingTimeInterval(600))
        state.advance(to: start.addingTimeInterval(900))
        XCTAssertEqual(state.remaining, 1800)
        XCTAssertFalse(state.selectFocusMinutes(0))
        XCTAssertFalse(state.selectFocusMinutes(181))
        XCTAssertFalse(state.setFocusPresets([10, 10]))
        XCTAssertFalse(state.setFocusPresets([]))
        XCTAssertFalse(state.setFocusPresets([0]))
        XCTAssertTrue(state.setFocusPresets([40, 12, 25]))
        XCTAssertEqual(state.focusPresets, [12, 25, 40])
        var oldSave = try JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as! [String: Any]
        oldSave.removeValue(forKey: "nextFocusMinutes")
        oldSave.removeValue(forKey: "customFocusPresets")
        let restored = try JSONDecoder().decode(FocusState.self, from: JSONSerialization.data(withJSONObject: oldSave))
        XCTAssertEqual(restored.focusPresets, FocusState.defaultFocusPresets)
        XCTAssertEqual(restored.focusedMinutes, 10)
    }

    func testReactionPhases() {
        let fed = CompanionReaction(startedAt: start, grew: false)
        XCTAssertEqual(fed.phase(at: start), .eating)
        XCTAssertEqual(fed.phase(at: start.addingTimeInterval(1.2)), .happy)
        XCTAssertEqual(fed.phase(at: start.addingTimeInterval(2.6)), .idle)
        let grew = CompanionReaction(startedAt: start, grew: true)
        XCTAssertEqual(grew.phase(at: start), .eating)
        XCTAssertEqual(grew.phase(at: start.addingTimeInterval(1.2)), .growing)
        XCTAssertEqual(grew.phase(at: start.addingTimeInterval(4.6)), .idle)
        XCTAssertEqual(grew.phase(at: start.addingTimeInterval(-1)), .idle)
    }

    func testSwitchKeepsProgress() throws {
        var state = FocusState()
        state.companion = .pomo
        state.nickname = "Buddy"
        state.fedTreats = 11
        state.treats = 3
        state.completedSessions = 14
        state.focusedMinutes = 350
        state.start(at: start)
        let originalDeadline = state.deadline
        for companion in Companion.allCases {
            state.changeCompanion(to: companion)
            state = try JSONDecoder().decode(FocusState.self, from: JSONEncoder().encode(state))
            XCTAssertEqual(state.companion, companion)
            XCTAssertEqual(state.level, 3)
            XCTAssertEqual(state.fedTreats, 11)
            XCTAssertEqual(state.treats, 3)
            XCTAssertEqual(state.completedSessions, 14)
            XCTAssertEqual(state.focusedMinutes, 350)
            XCTAssertEqual(state.nickname, "Buddy")
            XCTAssertEqual(state.deadline, originalDeadline)
            XCTAssertEqual(state.remaining, 1500)
        }
    }

    func testCompletionAwardsOnceAfterSleep() {
        var state = FocusState()
        state.start(at: start)
        XCTAssertTrue(state.advance(to: start.addingTimeInterval(7200)))
        XCTAssertEqual(state.treats, 5)
        XCTAssertEqual(state.completedSessions, 1)
        XCTAssertEqual(state.focusedMinutes, 25)
        XCTAssertEqual(state.phase, .shortBreak)
        XCTAssertNil(state.deadline)
        XCTAssertFalse(state.advance(to: start.addingTimeInterval(7300)))
        XCTAssertEqual(state.treats, 5)
    }

    func testPauseResumeAndResetDoNotAwardTreats() {
        var state = FocusState()
        state.start(at: start)
        state.pause(at: start.addingTimeInterval(60))
        XCTAssertEqual(state.remaining, 1440)
        state.start(at: start.addingTimeInterval(100))
        XCTAssertEqual(state.deadline, start.addingTimeInterval(1540))
        state.reset()
        XCTAssertEqual(state.remaining, 1500)
        XCTAssertEqual(state.treats, 0)
    }

    func testFourthFocusGetsLongBreakAndBreakDoesNotReward() {
        var state = FocusState()
        state.completedSessions = 3
        state.start(at: start)
        state.advance(to: start.addingTimeInterval(1500))
        XCTAssertEqual(state.phase, .longBreak)
        XCTAssertEqual(state.remaining, 900)
        state.start(at: start.addingTimeInterval(1500))
        state.advance(to: start.addingTimeInterval(2400))
        XCTAssertEqual(state.phase, .focus)
        XCTAssertEqual(state.treats, 5)
    }

    func testFeedingAndGrowth() {
        var state = FocusState()
        XCTAssertFalse(state.feed())
        state.treats = 4
        for _ in 0..<4 { XCTAssertTrue(state.feed()) }
        XCTAssertEqual(state.level, 2)
        XCTAssertEqual(state.treats, 0)
        XCTAssertFalse(state.feed())
    }

    func testAllCompanionsAndRunningTimerRoundTrip() throws {
        for companion in Companion.allCases {
            var state = FocusState()
            state.companion = companion
            state.nickname = "Little friend"
            state.start(at: start)
            var restored = try JSONDecoder().decode(FocusState.self, from: JSONEncoder().encode(state))
            XCTAssertEqual(restored.companion, companion)
            XCTAssertEqual(restored.displayName, "Little friend")
            XCTAssertTrue(restored.advance(to: start.addingTimeInterval(1500)))
            XCTAssertEqual(restored.treats, 5)
        }
    }
}
