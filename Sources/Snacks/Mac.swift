import AppKit
import CoreAudio
import SnackCore

/// Reads what the Mac is doing right now. The calendar and Focus need permission; without it
/// they simply never hold a snack back.
enum Mac {
    static func signals(meetings: Meetings, quiet: Bool) -> Signals {
        let now = Date()
        let parts = Calendar.current.dateComponents([.hour, .minute], from: now)
        let meeting = meetings.state(now)
        return Signals(idle: idleSeconds(), micInUse: micInUse(), fullScreen: frontAppFillsScreen(),
                       meetingSoon: meeting.soon, meetingJustEnded: meeting.justEnded, focusOn: Focus.isOn,
                       quiet: quiet, hour: Double(parts.hour ?? 10) + Double(parts.minute ?? 0) / 60)
    }

    /// Seconds since the last key press, click or mouse move, from any app.
    static func idleSeconds() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }

    /// Whether some app is recording from the default microphone (a call, usually).
    static func micInUse() -> Bool {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device) == noErr,
              device != 0 else { return false }
        var running: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        address.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &running) == noErr else { return false }
        return running != 0
    }

    /// Whether the front app has a window covering a whole screen (full screen, a film, a slideshow).
    static func frontAppFillsScreen() -> Bool {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
              let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]] else { return false }
        let screens = NSScreen.screens.map(\.frame.size)
        for w in windows where (w[kCGWindowOwnerPID as String] as? pid_t) == pid
                              && (w[kCGWindowLayer as String] as? Int) == 0 {
            guard let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = b["Width"], let height = b["Height"] else { continue }
            if screens.contains(where: { $0.width == width && $0.height == height }) { return true }
        }
        return false
    }
}
