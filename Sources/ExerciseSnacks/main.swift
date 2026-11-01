import AppKit
import ServiceManagement
import SnackCore
import SwiftUI

/// Where the moves file and the log live.
enum Store {
    static let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Exercise Snacks", isDirectory: true)
    static let movesFile = folder.appendingPathComponent("moves.md")
    static let logFile = folder.appendingPathComponent("log.jsonl")
    /// Moves turned off with "not for me", one title a line.
    static let offFile = folder.appendingPathComponent("off.txt")

    static func off() -> Set<String> {
        let text = (try? String(contentsOf: offFile, encoding: .utf8)) ?? ""
        return Set(
            text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty })
    }

    static func turnOff(_ title: String) {
        let lines = (off().union([title])).sorted().joined(separator: "\n") + "\n"
        try? lines.write(to: offFile, atomically: true, encoding: .utf8)
    }

    static func turnAllOn() { try? "".write(to: offFile, atomically: true, encoding: .utf8) }

    /// The logged events since `since`, as (event, move title) pairs.
    static func events(since: Date) -> [(event: String, move: String)] {
        let text = (try? String(contentsOf: logFile, encoding: .utf8)) ?? ""
        let iso = ISO8601DateFormatter()
        return text.split(separator: "\n").compactMap { line in
            guard let data = line.data(using: .utf8),
                let row = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                let at = row["at"].flatMap(iso.date(from:)), at >= since
            else { return nil }
            return (row["event"] ?? "", row["move"] ?? "")
        }
    }

    /// One plain sentence about the last seven days, to send to someone if you like.
    static func weekSummary() -> String {
        let events = Store.events(since: Date().addingTimeInterval(-7 * 86400)).filter { $0.event == "done" }
        let moves = Dictionary(Store.moves().map { ($0.title, $0) }, uniquingKeysWith: { a, _ in a })
        let hard = events.filter { moves[$0.move]?.kind == "vigorous" }.count
        let minutes = events.compactMap { moves[$0.move]?.seconds }.reduce(0, +) / 60
        return "My movement snacks this week: \(events.count) done, \(hard) of them out of breath, "
            + "about \(minutes) minutes of moving between bits of work."
    }

    /// The moves from the file, which is written from the seed the first time.
    static func moves() -> [Move] {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: movesFile.path) {
            try? Moves.seed.write(to: movesFile, atomically: true, encoding: .utf8)
        }
        let parsed = Moves.parse((try? String(contentsOf: movesFile, encoding: .utf8)) ?? "")
        return parsed.isEmpty ? Moves.parse(Moves.seed) : parsed
    }

    /// One line per event, so we can later see which snacks get done and which get skipped.
    static func log(_ event: String, _ move: Move?) {
        let line: [String: String] = [
            "at": ISO8601DateFormatter().string(from: Date()), "event": event,
            "move": move?.title ?? "",
        ]
        guard var data = try? JSONSerialization.data(withJSONObject: line, options: [.sortedKeys]) else { return }
        data.append(0x0A)
        if let h = try? FileHandle(forWritingTo: logFile) {
            h.seekToEndOfFile()
            h.write(data)
            try? h.close()
        } else {
            try? data.write(to: logFile)
        }
    }
}

/// The small panel at the top that floats over other windows without taking keyboard focus.
final class CardPanel: NSPanel {
    override var canBecomeMain: Bool { false }
}

/// The full-screen snack. Borderless windows can't take the keyboard unless told they can (for esc).
final class SnackWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var rhythm = Rhythm()
    private var timer: Timer?
    private let meetings = Meetings()
    /// Snack cards shown today, for the daily cap and to make every third one vigorous.
    private var shownToday = 0
    private var today = Calendar.current.startOfDay(for: Date())
    private var lastTick = Date()
    private var pausedUntil: Date?
    private var recent: [String] = []
    private var rng = SystemRandomNumberGenerator()
    private var panel: CardPanel?
    private var full: SnackWindow?
    private var card: CardModel?
    /// The app you were in before the full-screen snack, to hand focus back to.
    private var previousApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "figure.walk", accessibilityDescription: "Exercise Snacks")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        Settings.register()
        shownToday = Store.events(since: today).filter { $0.event == "shown" }.count
        meetings.ask()
        Focus.ask()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer!, forMode: .common)
        // `--open-at-login` turns on Open at login once, for installing from the command line.
        if CommandLine.arguments.contains("--open-at-login"), SMAppService.mainApp.status != .enabled {
            toggleLogin()
        }
        if CommandLine.arguments.contains("--demo") { showCard() }
        if CommandLine.arguments.contains("--demo-full") {
            showCard()
            goFull()
        }
    }

    private var isPaused: Bool {
        if let until = pausedUntil, until > Date() { return true }
        pausedUntil = nil
        return false
    }

    private func tick() {
        let now = Date()
        let dt = now.timeIntervalSince(lastTick)
        lastTick = now
        let day = Calendar.current.startOfDay(for: now)
        if day != today {
            today = day
            shownToday = 0
        }
        let hour = Calendar.current.component(.hour, from: now)
        let quiet = Settings.isQuiet(hour: hour) || shownToday >= Settings.dailyCap
        let signals = Mac.signals(meetings: meetings, quiet: quiet)
        if card != nil {
            // Nobody answered and they've stepped away: that was a break of its own.
            if rhythm.wasAway(signals), card?.stage == .offer { closeCard(.away) }
            return
        }
        if rhythm.tick(dt, signals), !isPaused { showCard() }
    }

    private func nextMove(kind: String? = nil) -> Move? {
        guard let move = Moves.pick(Store.moves(), avoiding: recent, off: Store.off(), kind: kind, using: &rng)
        else { return nil }
        recent = Array((recent + [move.title]).suffix(4))
        return move
    }

    private func showCard() {
        let kind = rhythm.afterLunch ? "walk" : Moves.kind(forSnack: shownToday + 1)
        guard card == nil, let move = nextMove(kind: kind) else { return }
        shownToday += 1
        let model = CardModel(move: move)
        model.another = { [weak self] in
            let next = self?.nextMove()
            Store.log("another", next)
            return next
        }
        model.notForMe = { [weak self] in
            guard let self, let model = self.card else { return nil }
            Store.turnOff(model.move.title)
            Store.log("off", model.move)
            return self.nextMove()
        }
        model.onYes = { [weak self] in self?.goFull() }
        model.onEnd = { [weak self] outcome in self?.closeCard(outcome) }
        card = model
        Store.log("shown", move)

        let host = NSHostingView(rootView: PromptView(model: model))
        let size = host.fittingSize
        let panel = CardPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.sharingType = sharing
        panel.contentView = host
        // Top centre, just under the menu bar.
        if let screen = NSScreen.main {
            let v = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: v.midX - size.width / 2, y: v.maxY - size.height - 12))
        }
        fadeIn(panel)
        self.panel = panel
    }

    /// Left out of screen shares and recordings; the --demo flags let a screenshot see it.
    private var sharing: NSWindow.SharingType {
        CommandLine.arguments.contains(where: { $0.hasPrefix("--demo") }) ? .readOnly : .none
    }

    private func fadeIn(_ w: NSWindow) {
        w.alphaValue = 0
        w.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup {
            $0.duration = 0.35
            w.animator().alphaValue = 1
        }
    }

    private func fadeOut(_ w: NSWindow?) {
        NSAnimationContext.runAnimationGroup(
            {
                $0.duration = 0.3
                w?.animator().alphaValue = 0
            },
            completionHandler: { w?.orderOut(nil) })
    }

    /// Yes: the small card goes and the snack fills the screen, countdown running.
    private func goFull() {
        guard let model = card, full == nil, let screen = NSScreen.main else { return }
        Store.log("start", model.move)
        fadeOut(panel)
        panel = nil

        let window = SnackWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.level = .screenSaver  // over the menu bar, the Dock and full-screen apps
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.sharingType = sharing
        window.contentView = NSHostingView(rootView: SnackView(model: model))
        window.setFrame(screen.frame, display: true)
        previousApp = NSWorkspace.shared.frontmostApplication
        fadeIn(window)
        window.makeKey()
        NSApp.activate(ignoringOtherApps: true)
        full = window
        model.start()
    }

    private func closeCard(_ outcome: Outcome) {
        guard let model = card else { return }
        Store.log(outcome.rawValue, model.move)
        if outcome == .later { rhythm.snooze(TimeInterval(model.laterMinutes * 60)) } else { rhythm.reset() }
        card = nil
        fadeOut(panel)
        panel = nil
        if let window = full {
            fadeOut(window)
            full = nil
            previousApp?.activate()
            previousApp = nil
        }
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let status: String
        if let until = pausedUntil, isPaused {
            status = "Paused until \(until.formatted(date: .omitted, time: .shortened))"
        } else if card != nil {
            status = "Snack on screen"
        } else if rhythm.isDue {
            status = "Snack due: waiting for a pause"
        } else {
            status = "Next snack after \(rhythm.minutesLeft) min of use"
        }
        let header = NSMenuItem(title: status, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())
        menu.addItem(item("Snack now", #selector(snackNow), key: "s"))
        menu.addItem(isPaused ? item("Resume", #selector(resume)) : item("Pause for an hour", #selector(pauseHour)))
        menu.addItem(item("Edit moves…", #selector(editMoves)))
        let off = Store.off().count
        if off > 0 { menu.addItem(item("Turn moves back on (\(off) off)", #selector(turnAllOn))) }
        menu.addItem(item("Share this week…", #selector(shareWeek)))
        let login = item("Open at login", #selector(toggleLogin))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        menu.addItem(item("Quit", #selector(quit), key: "q"))
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        return i
    }

    @objc private func snackNow() { showCard() }
    @objc private func pauseHour() {
        pausedUntil = Date().addingTimeInterval(3600)
        Store.log("pause", nil)
    }
    @objc private func resume() { pausedUntil = nil }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func editMoves() {
        _ = Store.moves()  // makes sure the file exists
        NSWorkspace.shared.open(Store.movesFile)
    }

    @objc private func turnAllOn() { Store.turnAllOn() }

    @objc private func shareWeek() {
        guard let button = statusItem.button else { return }
        NSSharingServicePicker(items: [Store.weekSummary()]).show(
            relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func toggleLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            NSLog("Open at login failed: \(error)")
        }
    }
}

// `ExerciseSnacks --snapshot out.png` draws cards and every figure to a PNG without opening a window.
if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--snapshot" {
    MainActor.assumeIsolated {
        let moves = Moves.parse(Moves.seed)
        let running = CardModel(move: moves[3])
        running.stage = .running
        running.remaining = 17
        let finished = CardModel(move: moves[0])
        finished.stage = .finished
        let figures = [
            "squat", "calf", "wallpush", "march", "lunge", "jacks", "armcircle", "reach", "twist", "neck", "chest",
        ]
        let view = VStack(alignment: .leading, spacing: 16) {
            PromptView(model: CardModel(move: moves[0]), figureAt: 0.6)
            HStack(spacing: 16) {
                SnackView(model: running, figureAt: 0.5).frame(width: 1200, height: 750).clipped()
                SnackView(model: finished, figureAt: 0).frame(width: 1200, height: 750).clipped()
            }
            ForEach([0.0, 0.5], id: \.self) { phase in
                HStack(spacing: 10) {
                    ForEach(figures, id: \.self) { name in
                        VStack {
                            FigureView(
                                figure: name, at: phase * FigureMove.named(name).period,
                                color: Night.bg, thin: true
                            )
                            .frame(width: 80, height: 120)
                            Text(name).font(.caption)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        guard let image = renderer.cgImage else { fatalError("could not draw") }
        let rep = NSBitmapImageRep(cgImage: image)
        try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
    }
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
