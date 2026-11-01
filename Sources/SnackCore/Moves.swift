import Foundation

public struct Move: Equatable {
    public var title: String
    public var seconds: Int
    /// Which looping figure shows it: squat, calf, wallpush, march, lunge, jacks, armcircle,
    /// reach, twist, neck, chest. Anything else shows a standing figure.
    public var figure: String
    public var text: String
    /// `vigorous` (gets you out of breath), `walk`, or empty for anything else.
    public var kind: String

    public init(title: String, seconds: Int, figure: String, text: String, kind: String = "") {
        self.title = title
        self.seconds = seconds
        self.figure = figure
        self.text = text
        self.kind = kind
    }
}

public enum Moves {
    /// Reads `# Title` entries split by `---` lines, each with optional `seconds:`, `figure:` and
    /// `kind:` lines; the rest of the entry is the instruction. Entries with no title are skipped.
    public static func parse(_ source: String) -> [Move] {
        var moves: [Move] = []
        var lines: [String] = []
        func flush() {
            defer { lines = [] }
            var title = "", seconds = 45, figure = "stand", kind = "", text: [String] = []
            for line in lines {
                let t = line.trimmingCharacters(in: .whitespaces)
                if t.hasPrefix("# ") {
                    title = String(t.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                } else if t.lowercased().hasPrefix("seconds:") {
                    seconds = Int(t.dropFirst(8).trimmingCharacters(in: .whitespaces)) ?? seconds
                } else if t.lowercased().hasPrefix("figure:") {
                    figure = t.dropFirst(7).trimmingCharacters(in: .whitespaces).lowercased()
                } else if t.lowercased().hasPrefix("kind:") {
                    kind = t.dropFirst(5).trimmingCharacters(in: .whitespaces).lowercased()
                } else if !t.isEmpty {
                    text.append(t)
                }
            }
            if !title.isEmpty {
                moves.append(Move(title: title, seconds: max(5, seconds), figure: figure,
                                  text: text.joined(separator: " "), kind: kind))
            }
        }
        for line in source.components(separatedBy: .newlines) {
            if line.trimmingCharacters(in: .whitespaces) == "---" { flush() } else { lines.append(line) }
        }
        flush()
        return moves
    }

    /// Picks a move at random, leaving out the titles in `off` and avoiding those in `recent`
    /// while others are left. With a `kind`, picks one of that kind if there is one.
    public static func pick(_ moves: [Move], avoiding recent: [String], off: Set<String> = [],
                            kind: String? = nil, using rng: inout some RandomNumberGenerator) -> Move? {
        var pool = moves.filter { !off.contains($0.title) }
        if pool.isEmpty { pool = moves }
        if let kind, pool.contains(where: { $0.kind == kind }) { pool = pool.filter { $0.kind == kind } }
        let fresh = pool.filter { !recent.contains($0.title) }
        return (fresh.isEmpty ? pool : fresh).randomElement(using: &rng)
    }

    /// Which kind the day's `n`th snack (from 1) should be: every third one gets you out of breath.
    public static func kind(forSnack n: Int) -> String? { n % 3 == 0 ? "vigorous" : nil }

    /// The moves a new install starts with, written to the moves file once.
    public static let seed = """
    # Brisk walk
    seconds: 180
    figure: march
    kind: walk

    Get up and walk: round the house, down the corridor, out to the door and back. Brisk enough to feel it. Three minutes.

    ---

    # Stairs
    seconds: 90
    figure: march
    kind: vigorous

    Up and down a flight of stairs, briskly, until you're puffing. No stairs nearby: march fast on the spot instead.

    ---

    # Fast march
    seconds: 60
    figure: march
    kind: vigorous

    Knees up to hip height, arms pumping. Speed up until you're out of breath, and hold it for the last twenty seconds.

    ---

    # Star jumps
    seconds: 60
    figure: jacks
    kind: vigorous

    Jump your feet wide as your arms go up, then back together. Keep going until you're puffing, or step it out if jumping isn't right just now.

    ---

    # Squats
    seconds: 60
    figure: squat

    Feet shoulder-width apart. Sit back as if into a chair, chest up, then stand. Fifteen to twenty, at a steady pace.

    ---

    # Sit to stand
    seconds: 60
    figure: squat

    From your chair: stand up without using your hands, sit back down slowly. Fifteen times.

    ---

    # Calf raises
    seconds: 60
    figure: calf

    Rise onto your toes, pause at the top, lower slowly. Twenty-five. Hold the desk if you like.

    ---

    # Wall push-ups
    seconds: 60
    figure: wallpush

    Hands on the wall at shoulder height, step your feet back. Lower your chest to the wall and push away. Twenty.

    ---

    # Lunges
    seconds: 60
    figure: lunge

    Step forward and lower your back knee towards the floor, then push back. Alternate legs, twelve each.

    ---

    # Arm circles
    seconds: 45
    figure: armcircle

    Arms straight out to the sides. Small circles forward for twenty seconds, then backward.

    ---

    # Stand and reach
    seconds: 45
    figure: reach

    Stand up, reach both arms overhead and stretch tall. Hold, breathe out, and reach again.

    ---

    # Standing twist
    seconds: 45
    figure: twist

    Arms folded at your chest, hips facing forward. Turn your shoulders slowly left, then right.

    ---

    # Neck half-circles
    seconds: 45
    figure: neck

    Drop your chin to your chest and roll your head slowly from shoulder to shoulder. Five each way. Never roll it back.

    ---

    # Doorway chest stretch
    seconds: 45
    figure: chest

    Forearms on a door frame, elbows at shoulder height. Step through until you feel your chest open.
    """
}
