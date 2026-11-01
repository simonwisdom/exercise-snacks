import XCTest
@testable import SnackCore

final class RhythmTests: XCTestCase {
    private let typing = Signals(idle: 0.5)
    private let paused = Signals(idle: 6)

    private func use(_ r: inout Rhythm, seconds: Int, _ s: Signals) -> Bool {
        var shown = false
        for _ in 0..<seconds { shown = r.tick(1, s) || shown }
        return shown
    }

    func testNotDueBeforeThirtyMinutesOfUse() {
        var r = Rhythm()
        XCTAssertFalse(use(&r, seconds: 29 * 60, paused))
        XCTAssertEqual(r.minutesLeft, 1)
    }

    func testWaitsForAPauseInTyping() {
        var r = Rhythm()
        XCTAssertFalse(use(&r, seconds: 31 * 60, typing))
        XCTAssertTrue(r.isDue)
        XCTAssertTrue(r.tick(1, paused))
    }

    func testNeverDuringACallOrFullScreen() {
        var r = Rhythm()
        _ = use(&r, seconds: 30 * 60, typing)
        XCTAssertFalse(r.tick(1, Signals(idle: 6, micInUse: true)))
        XCTAssertFalse(r.tick(1, Signals(idle: 6, fullScreen: true)))
        XCTAssertTrue(r.tick(1, paused))
    }

    func testSteppingAwayCountsAsABreak() {
        var r = Rhythm()
        _ = use(&r, seconds: 20 * 60, typing)
        XCTAssertFalse(r.tick(1, Signals(idle: 5 * 60)))
        XCTAssertEqual(r.used, 0)
        XCTAssertTrue(r.wasAway(Signals(idle: 5 * 60)))
    }

    func testSleepDoesNotCountAsUse() {
        var r = Rhythm()
        XCTAssertFalse(r.tick(3 * 3600, typing))
        XCTAssertEqual(r.used, 5)
    }

    func testLaterComesBackAfterTenMinutesOfUse() {
        var r = Rhythm()
        _ = use(&r, seconds: 30 * 60, typing)
        r.snooze()
        XCTAssertFalse(use(&r, seconds: 9 * 60, paused))
        XCTAssertTrue(use(&r, seconds: 61, paused))
    }

    func testLaterChipsComeBackAfterFiveOrFifteenMinutes() {
        var r = Rhythm()
        _ = use(&r, seconds: 30 * 60, typing)
        r.snooze(5 * 60)
        XCTAssertFalse(use(&r, seconds: 4 * 60, paused))
        XCTAssertTrue(use(&r, seconds: 61, paused))
        r.snooze(15 * 60)
        XCTAssertFalse(use(&r, seconds: 14 * 60, paused))
        XCTAssertTrue(use(&r, seconds: 61, paused))
    }

    func testHoldsOffForMeetingsFocusAndQuietHours() {
        var r = Rhythm()
        _ = use(&r, seconds: 30 * 60, typing)
        XCTAssertFalse(r.tick(1, Signals(idle: 6, meetingSoon: true)))
        XCTAssertFalse(r.tick(1, Signals(idle: 6, focusOn: true)))
        XCTAssertFalse(r.tick(1, Signals(idle: 6, quiet: true)))
        XCTAssertTrue(r.tick(1, paused))
    }

    func testEndOfMeetingBringsASnackForward() {
        var r = Rhythm()
        _ = use(&r, seconds: 15 * 60, typing)
        XCTAssertFalse(r.tick(1, Signals(idle: 0.5, meetingJustEnded: true)))  // too early
        _ = use(&r, seconds: 6 * 60, typing)
        XCTAssertTrue(r.tick(1, Signals(idle: 0.5, meetingJustEnded: true)))   // within 10 min of due
    }

    func testLunchBreakBringsAWalkForward() {
        var r = Rhythm()
        _ = use(&r, seconds: 5 * 60, typing)
        XCTAssertFalse(r.tick(1, Signals(idle: 25 * 60, hour: 13)))
        XCTAssertFalse(r.tick(1, Signals(idle: 0.5, hour: 13.4)))
        XCTAssertTrue(r.afterLunch)
        XCTAssertEqual(r.minutesLeft, 10)
        r.reset()
        XCTAssertFalse(r.afterLunch)
    }

    func testShortOrEveningBreaksAreNotLunch() {
        var r = Rhythm()
        _ = r.tick(1, Signals(idle: 10 * 60, hour: 13))
        _ = r.tick(1, Signals(idle: 0.5, hour: 13.2))
        XCTAssertFalse(r.afterLunch)
        _ = r.tick(1, Signals(idle: 40 * 60, hour: 18))
        _ = r.tick(1, Signals(idle: 0.5, hour: 18.7))
        XCTAssertFalse(r.afterLunch)
        XCTAssertEqual(r.minutesLeft, 30)
    }

    func testResetStartsAgain() {
        var r = Rhythm()
        _ = use(&r, seconds: 30 * 60, typing)
        r.reset()
        XCTAssertFalse(r.isDue)
        XCTAssertEqual(r.minutesLeft, 30)
    }
}

final class MovesTests: XCTestCase {
    func testSeedParsesEveryMove() {
        let moves = Moves.parse(Moves.seed)
        XCTAssertEqual(moves.count, 14)
        XCTAssertEqual(moves.first?.title, "Brisk walk")
        XCTAssertEqual(moves.first?.seconds, 180)
        XCTAssertEqual(moves.first?.kind, "walk")
        XCTAssertEqual(moves.filter { $0.kind == "vigorous" }.count, 3)
        XCTAssertTrue(moves.allSatisfy { !$0.text.isEmpty && $0.seconds >= 45 })
    }

    func testDefaultsAndSkipsUntitled() {
        let moves = Moves.parse("just words\n---\n# Plank\n\nHold it.\n---\n\n")
        XCTAssertEqual(moves, [Move(title: "Plank", seconds: 45, figure: "stand", text: "Hold it.")])
    }

    func testPickAvoidsRecent() {
        let moves = Moves.parse("# A\n---\n# B\n---\n# C")
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            XCTAssertEqual(Moves.pick(moves, avoiding: ["A", "B"], using: &rng)?.title, "C")
        }
        XCTAssertNotNil(Moves.pick(moves, avoiding: ["A", "B", "C"], using: &rng))
    }

    func testPickLeavesOutMovesTurnedOff() {
        let moves = Moves.parse("# A\n---\n# B")
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<20 { XCTAssertEqual(Moves.pick(moves, avoiding: [], off: ["A"], using: &rng)?.title, "B") }
        // All turned off: still picks something rather than nothing.
        XCTAssertNotNil(Moves.pick(moves, avoiding: [], off: ["A", "B"], using: &rng))
    }

    func testPickPrefersAKindWhenAsked() {
        let moves = Moves.parse("# A\n---\n# B\nkind: vigorous\n---\n# C")
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<20 { XCTAssertEqual(Moves.pick(moves, avoiding: ["B"], kind: "vigorous", using: &rng)?.title, "B") }
        XCTAssertNotNil(Moves.pick(moves, avoiding: [], kind: "walk", using: &rng))
    }

    func testEveryThirdSnackIsVigorous() {
        XCTAssertEqual((1...9).map { Moves.kind(forSnack: $0) },
                       [nil, nil, "vigorous", nil, nil, "vigorous", nil, nil, "vigorous"])
    }
}
