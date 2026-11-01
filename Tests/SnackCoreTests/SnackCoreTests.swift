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
        XCTAssertEqual(moves.count, 13)
        XCTAssertEqual(moves.first, Move(title: "Squats", seconds: 45, figure: "squat",
            text: "Feet shoulder-width apart. Sit back as if into a chair, chest up, then stand. Ten to fifteen."))
        XCTAssertTrue(moves.allSatisfy { !$0.text.isEmpty })
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
}
