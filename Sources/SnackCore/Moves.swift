import Foundation

public struct Move: Equatable {
    public var title: String
    public var seconds: Int
    /// Which looping figure shows it: squat, calf, wallpush, march, lunge, jacks, armcircle,
    /// reach, twist, neck, chest. Anything else shows a standing figure.
    public var figure: String
    public var text: String

    public init(title: String, seconds: Int, figure: String, text: String) {
        self.title = title
        self.seconds = seconds
        self.figure = figure
        self.text = text
    }
}

public enum Moves {
    /// Reads `# Title` entries split by `---` lines, each with optional `seconds:` and `figure:`
    /// lines; the rest of the entry is the instruction. Entries with no title are skipped.
    public static func parse(_ source: String) -> [Move] {
        var moves: [Move] = []
        var lines: [String] = []
        func flush() {
            defer { lines = [] }
            var title = "", seconds = 45, figure = "stand", text: [String] = []
            for line in lines {
                let t = line.trimmingCharacters(in: .whitespaces)
                if t.hasPrefix("# ") {
                    title = String(t.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                } else if t.lowercased().hasPrefix("seconds:") {
                    seconds = Int(t.dropFirst(8).trimmingCharacters(in: .whitespaces)) ?? seconds
                } else if t.lowercased().hasPrefix("figure:") {
                    figure = t.dropFirst(7).trimmingCharacters(in: .whitespaces).lowercased()
                } else if !t.isEmpty {
                    text.append(t)
                }
            }
            if !title.isEmpty {
                moves.append(Move(title: title, seconds: max(5, seconds), figure: figure,
                                  text: text.joined(separator: " ")))
            }
        }
        for line in source.components(separatedBy: .newlines) {
            if line.trimmingCharacters(in: .whitespaces) == "---" { flush() } else { lines.append(line) }
        }
        flush()
        return moves
    }

    /// Picks a move at random, avoiding the titles in `recent` while others are left.
    public static func pick(_ moves: [Move], avoiding recent: [String],
                            using rng: inout some RandomNumberGenerator) -> Move? {
        let fresh = moves.filter { !recent.contains($0.title) }
        return (fresh.isEmpty ? moves : fresh).randomElement(using: &rng)
    }

    /// The moves a new install starts with, written to the moves file once.
    public static let seed = """
    # Squats
    seconds: 45
    figure: squat

    Feet shoulder-width apart. Sit back as if into a chair, chest up, then stand. Ten to fifteen.

    ---

    # Sit to stand
    seconds: 45
    figure: squat

    From your chair: stand up without using your hands, sit back down slowly. Ten times.

    ---

    # Calf raises
    seconds: 40
    figure: calf

    Rise onto your toes, pause at the top, lower slowly. Twenty. Hold the desk if you like.

    ---

    # Wall push-ups
    seconds: 45
    figure: wallpush

    Hands on the wall at shoulder height, step your feet back. Lower your chest to the wall and push away. Fifteen.

    ---

    # March on the spot
    seconds: 60
    figure: march

    Knees up to hip height, arms swinging. Keep going for a minute, faster for the last ten seconds.

    ---

    # Stairs
    seconds: 60
    figure: march

    Up and down a flight of stairs, briskly, twice. No stairs nearby: march on the spot instead.

    ---

    # Lunges
    seconds: 45
    figure: lunge

    Step forward and lower your back knee towards the floor, then push back. Alternate legs, ten each.

    ---

    # Star jumps
    seconds: 30
    figure: jacks

    Jump your feet wide as your arms go up, then back together. Thirty seconds, or step it out if jumping isn't right just now.

    ---

    # Arm circles
    seconds: 30
    figure: armcircle

    Arms straight out to the sides. Small circles forward for fifteen seconds, then backward.

    ---

    # Stand and reach
    seconds: 30
    figure: reach

    Stand up, reach both arms overhead and stretch tall. Hold, breathe out, and reach again.

    ---

    # Standing twist
    seconds: 30
    figure: twist

    Arms folded at your chest, hips facing forward. Turn your shoulders slowly left, then right.

    ---

    # Neck half-circles
    seconds: 30
    figure: neck

    Drop your chin to your chest and roll your head slowly from shoulder to shoulder. Five each way. Never roll it back.

    ---

    # Doorway chest stretch
    seconds: 40
    figure: chest

    Forearms on a door frame, elbows at shoulder height. Step through until you feel your chest open.
    """
}
