import Foundation

/// What the Mac looks like right now, as far as timing a snack goes.
public struct Signals {
    /// Seconds since the last key press, click or mouse move.
    public var idle: TimeInterval
    /// The microphone is in use: probably a call.
    public var micInUse: Bool
    /// The front app fills the screen: a film, a talk, a focused full-screen window.
    public var fullScreen: Bool
    /// A calendar event starts within the next few minutes.
    public var meetingSoon: Bool
    /// A calendar event ended in the last few minutes: a natural break.
    public var meetingJustEnded: Bool
    /// A macOS Focus is on.
    public var focusOn: Bool
    /// Quiet hours, or the day's snacks are used up.
    public var quiet: Bool
    /// The time of day, in hours (13.5 is half past one).
    public var hour: Double

    public init(
        idle: TimeInterval, micInUse: Bool = false, fullScreen: Bool = false,
        meetingSoon: Bool = false, meetingJustEnded: Bool = false, focusOn: Bool = false,
        quiet: Bool = false, hour: Double = 10
    ) {
        self.idle = idle
        self.micInUse = micInUse
        self.fullScreen = fullScreen
        self.meetingSoon = meetingSoon
        self.meetingJustEnded = meetingJustEnded
        self.focusOn = focusOn
        self.quiet = quiet
        self.hour = hour
    }

    /// Something says not now: a call, full screen, a meeting about to start, Focus, quiet hours.
    public var holdOff: Bool { micInUse || fullScreen || meetingSoon || focusOn || quiet }
}

/// Counts time spent using the Mac and says when a snack should show.
///
/// A snack is due after `every` seconds of use. It then waits for a pause (no input for
/// `pauseAfter` seconds), and never shows during a call or a full-screen app. Stepping away for
/// `awayAfter` seconds counts as a break, so the count starts again.
///
/// The end of a meeting is a natural break, so a snack due within `earlyBy` shows then. Coming
/// back from a long break around lunch brings the next snack forward, as a walk: moving soon
/// after a meal does the most good.
public struct Rhythm {
    public var every: TimeInterval
    public var awayAfter: TimeInterval
    public var pauseAfter: TimeInterval
    public var snoozeFor: TimeInterval
    /// How early a snack may show at the end of a meeting.
    public var earlyBy: TimeInterval = 10 * 60
    /// A break at least this long, ending between `lunch` hours, counts as a meal.
    public var mealBreak: TimeInterval = 20 * 60
    public var lunch: ClosedRange<Double> = 11.5...15
    /// After a meal, how many seconds of use until the walk.
    public var afterMeal: TimeInterval = 10 * 60

    /// Seconds of use since the last snack or break.
    public private(set) var used: TimeInterval = 0
    /// The next snack follows a meal break, so it should be a walk.
    public private(set) var afterLunch = false
    /// How long the current (or last) time away has lasted.
    private var awayFor: TimeInterval = 0

    public init(
        every: TimeInterval = 30 * 60, awayAfter: TimeInterval = 5 * 60,
        pauseAfter: TimeInterval = 4, snoozeFor: TimeInterval = 10 * 60
    ) {
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
            awayFor = s.idle
            return false
        }
        if awayFor > 0 {
            if awayFor >= mealBreak, lunch.contains(s.hour) {
                used = every - afterMeal
                afterLunch = true
            }
            awayFor = 0
        }
        used += min(max(dt, 0), 5)
        if s.holdOff { return false }
        if s.meetingJustEnded, used >= every - earlyBy { return true }
        return isDue && s.idle >= pauseAfter
    }

    /// Whether being away this long should close a snack nobody answered.
    public func wasAway(_ s: Signals) -> Bool { s.idle >= awayAfter }

    /// The snack was done (or skipped by stepping away): start counting again.
    public mutating func reset() {
        used = 0
        afterLunch = false
    }

    /// "Later": come back after `seconds` more seconds of use (default `snoozeFor`).
    public mutating func snooze(_ seconds: TimeInterval? = nil) { used = max(0, every - (seconds ?? snoozeFor)) }
}
