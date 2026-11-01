import EventKit
import Foundation
import Intents

/// Reads the calendar to keep snacks out of the minutes before a meeting and to use the end of one.
final class Meetings {
    private let store = EKEventStore()
    private var allowed = false
    private var checked = Date.distantPast
    private var cached = (soon: false, justEnded: false)

    /// How close a start counts as "about to start", and how recent an end counts as "just ended".
    let window: TimeInterval = 5 * 60

    func ask() {
        let done: (Bool, Error?) -> Void = { [weak self] ok, _ in self?.allowed = ok }
        if #available(macOS 14, *) { store.requestFullAccessToEvents(completion: done) }
        else { store.requestAccess(to: .event, completion: done) }
    }

    /// Whether a meeting is on or about to start, and whether one just ended. Looked up once a minute.
    func state(_ now: Date = Date()) -> (soon: Bool, justEnded: Bool) {
        guard allowed else { return (false, false) }
        if now.timeIntervalSince(checked) < 60 { return cached }
        checked = now
        let range = store.predicateForEvents(withStart: now.addingTimeInterval(-window),
                                             end: now.addingTimeInterval(window), calendars: nil)
        let events = store.events(matching: range).filter {
            !$0.isAllDay && $0.status != .canceled && $0.availability != .free
        }
        let soon = events.contains { $0.startDate <= now.addingTimeInterval(window) && $0.endDate > now }
        let ended = events.contains { $0.endDate <= now && $0.endDate > now.addingTimeInterval(-window) }
        cached = (soon, ended && !soon)
        return cached
    }
}

/// Whether a macOS Focus (Do Not Disturb, Work and so on) is on. Asks once for permission.
enum Focus {
    static func ask() { INFocusStatusCenter.default.requestAuthorization { _ in } }

    static var isOn: Bool {
        INFocusStatusCenter.default.authorizationStatus == .authorized
            && INFocusStatusCenter.default.focusStatus.isFocused == true
    }
}

/// Settings with no menu of their own; change them with `defaults write com.simonwisdom.snacks …`.
enum Settings {
    static func register() {
        UserDefaults.standard.register(defaults: ["quietFrom": 19, "quietUntil": 7, "dailyCap": 10])
    }
    /// No snacks from this hour…
    static var quietFrom: Int { UserDefaults.standard.integer(forKey: "quietFrom") }
    /// …until this hour.
    static var quietUntil: Int { UserDefaults.standard.integer(forKey: "quietUntil") }
    /// At most this many snack cards a day.
    static var dailyCap: Int { UserDefaults.standard.integer(forKey: "dailyCap") }

    static func isQuiet(hour: Int) -> Bool {
        quietFrom > quietUntil ? (hour >= quietFrom || hour < quietUntil)
                               : (hour >= quietFrom && hour < quietUntil)
    }
}
