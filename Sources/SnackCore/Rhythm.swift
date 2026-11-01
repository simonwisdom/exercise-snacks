import Foundation

/// What the Mac looks like right now, as far as timing a snack goes.
public struct Signals {
    /// Seconds since the last key press, click or mouse move.
    public var idle: TimeInterval
    /// The microphone is in use: probably a call.
    public var micInUse: Bool
    /// The front app fills the screen: a film, a talk, a focused full-screen window.
    public var fullScreen: Bool

    public init(idle: TimeInterval, micInUse: Bool = false, fullScreen: Bool = false) {
        self.idle = idle
        self.micInUse = micInUse
        self.fullScreen = fullScreen
    }
}

/// Counts time spent using the Mac and says when a snack should show.
///
/// A snack is due after `every` seconds of use. It then waits for a pause (no input for
/// `pauseAfter` seconds), and never shows during a call or a full-screen app. Stepping away for
/// `awayAfter` seconds counts as a break, so the count starts again.
public struct Rhythm {
    public var every: TimeInterval
    public var awayAfter: TimeInterval
    public var pauseAfter: TimeInterval
    public var snoozeFor: TimeInterval

    /// Seconds of use since the last snack or break.
    public private(set) var used: TimeInterval = 0

    public init(every: TimeInterval = 30 * 60, awayAfter: TimeInterval = 5 * 60,
                pauseAfter: TimeInterval = 4, snoozeFor: TimeInterval = 10 * 60) {
        self.every = every
        self.awayAfter = awayAfter
        self.pauseAfter = pauseAfter
        self.snoozeFor = snoozeFor
    }

    public var isDue: Bool { used >= every }

    /// Minutes of use left before a snack is due.
    public var minutesLeft: Int { max(0, Int(((every - used) / 60).rounded(.up))) }

    /// Moves time on by `dt` seconds. Returns true when the snack should show now.
    /// `dt` is capped at 5 s, so a Mac waking from sleep doesn't count the sleep as use.
    public mutating func tick(_ dt: TimeInterval, _ s: Signals) -> Bool {
        if s.idle >= awayAfter {
            used = 0
            return false
        }
        used += min(max(dt, 0), 5)
        return isDue && s.idle >= pauseAfter && !s.micInUse && !s.fullScreen
    }

    /// Whether being away this long should close a snack nobody answered.
    public func wasAway(_ s: Signals) -> Bool { s.idle >= awayAfter }

    /// The snack was done (or skipped by stepping away): start counting again.
    public mutating func reset() { used = 0 }

    /// "Later": come back after `seconds` more seconds of use (default `snoozeFor`).
    public mutating func snooze(_ seconds: TimeInterval? = nil) { used = max(0, every - (seconds ?? snoozeFor)) }
}
