import SwiftUI

/// A stick figure's joints, in a 100 × 160 box with y going up from the floor.
struct Pose {
    var head, neck, hip: CGPoint
    var lElbow, lHand, rElbow, rHand: CGPoint
    var lKnee, lFoot, rKnee, rFoot: CGPoint

    static func lerp(_ a: Pose, _ b: Pose, _ t: CGFloat) -> Pose {
        func m(_ p: CGPoint, _ q: CGPoint) -> CGPoint { CGPoint(x: p.x + (q.x - p.x) * t, y: p.y + (q.y - p.y) * t) }
        return Pose(head: m(a.head, b.head), neck: m(a.neck, b.neck), hip: m(a.hip, b.hip),
                    lElbow: m(a.lElbow, b.lElbow), lHand: m(a.lHand, b.lHand),
                    rElbow: m(a.rElbow, b.rElbow), rHand: m(a.rHand, b.rHand),
                    lKnee: m(a.lKnee, b.lKnee), lFoot: m(a.lFoot, b.lFoot),
                    rKnee: m(a.rKnee, b.rKnee), rFoot: m(a.rFoot, b.rFoot))
    }

    func moved(_ dx: CGFloat, _ dy: CGFloat, keepFeet: Bool = false) -> Pose {
        func s(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x + dx, y: p.y + dy) }
        return Pose(head: s(head), neck: s(neck), hip: s(hip), lElbow: s(lElbow), lHand: s(lHand),
                    rElbow: s(rElbow), rHand: s(rHand), lKnee: s(lKnee),
                    lFoot: keepFeet ? lFoot : s(lFoot), rKnee: s(rKnee), rFoot: keepFeet ? rFoot : s(rFoot))
    }
}

private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

/// Standing, seen from the front.
private let front = Pose(head: p(50, 122), neck: p(50, 108), hip: p(50, 70),
                         lElbow: p(39, 90), lHand: p(36, 72), rElbow: p(61, 90), rHand: p(64, 72),
                         lKnee: p(45, 38), lFoot: p(43, 6), rKnee: p(55, 38), rFoot: p(57, 6))

/// Standing, seen from the side, facing right.
private let side = Pose(head: p(50, 122), neck: p(50, 108), hip: p(50, 70),
                        lElbow: p(48, 89), lHand: p(50, 71), rElbow: p(52, 89), rHand: p(54, 71),
                        lKnee: p(50, 38), lFoot: p(52, 6), rKnee: p(49, 38), rFoot: p(51, 6))

/// One looping move: the pose at time `t` seconds, plus what else to draw (a wall, a door frame).
struct FigureMove {
    var period: Double = 2
    var wallX: CGFloat? = nil
    var pose: (Double) -> Pose

    /// Goes from a to b and back, easing at both ends.
    static func swing(_ a: Pose, _ b: Pose, period: Double = 2, wallX: CGFloat? = nil) -> FigureMove {
        FigureMove(period: period, wallX: wallX) { t in
            Pose.lerp(a, b, CGFloat((1 - cos(2 * .pi * t / period)) / 2))
        }
    }

    static func named(_ name: String) -> FigureMove {
        switch name {
        case "squat":
            var down = side
            down.head = p(62, 94); down.neck = p(58, 81); down.hip = p(36, 44)
            down.lElbow = p(72, 82); down.lHand = p(86, 82); down.rElbow = p(71, 80); down.rHand = p(85, 80)
            down.lKnee = p(62, 40); down.rKnee = p(60, 39)
            var up = side
            up.lElbow = p(64, 106); up.lHand = p(78, 106); up.rElbow = p(63, 104); up.rHand = p(77, 104)
            return .swing(up, down, period: 2.4)
        case "calf":
            return .swing(front, front.moved(0, 9, keepFeet: true), period: 1.6)
        case "wallpush":
            let lean = Pose(head: p(73, 119), neck: p(69, 106), hip: p(55, 66),
                            lElbow: p(78, 103), lHand: p(87, 101), rElbow: p(77, 101), rHand: p(87, 99),
                            lKnee: p(47, 36), lFoot: p(40, 6), rKnee: p(46, 36), rFoot: p(39, 6))
            var near = lean
            near.head = p(81, 112); near.neck = p(76, 100); near.hip = p(58, 64)
            near.lElbow = p(75, 88); near.rElbow = p(74, 86)
            return .swing(lean, near, period: 2, wallX: 90)
        case "march":
            var left = front
            left.lKnee = p(42, 62); left.lFoot = p(44, 30)
            left.rElbow = p(63, 96); left.rHand = p(58, 108); left.lElbow = p(37, 86); left.lHand = p(36, 68)
            var right = front
            right.rKnee = p(58, 62); right.rFoot = p(56, 30)
            right.lElbow = p(37, 96); right.lHand = p(42, 108); right.rElbow = p(63, 86); right.rHand = p(64, 68)
            return .swing(left, right, period: 1.2)
        case "lunge":
            var down = side
            down.head = p(48, 100); down.neck = p(48, 86); down.hip = p(48, 48)
            down.lElbow = p(40, 70); down.lHand = p(48, 52); down.rElbow = p(42, 70); down.rHand = p(50, 52)
            down.lKnee = p(70, 40); down.lFoot = p(72, 6); down.rKnee = p(32, 12); down.rFoot = p(20, 6)
            var up = side
            up.lElbow = p(40, 90); up.lHand = p(48, 72); up.rElbow = p(42, 90); up.rHand = p(50, 72)
            return .swing(up, down, period: 2.4)
        case "jacks":
            var star = front
            star.lElbow = p(34, 124); star.lHand = p(24, 140); star.rElbow = p(66, 124); star.rHand = p(76, 140)
            star.lKnee = p(39, 38); star.lFoot = p(28, 6); star.rKnee = p(61, 38); star.rFoot = p(72, 6)
            return .swing(front, star.moved(0, 4), period: 1)
        case "armcircle":
            return FigureMove(period: 1.2) { t in
                let a = 2 * .pi * t / 1.2
                var pose = front
                let dx = 7 * CGFloat(cos(a)), dy = 7 * CGFloat(sin(a))
                pose.lElbow = p(33, 106); pose.lHand = p(16 + dx, 106 + dy)
                pose.rElbow = p(67, 106); pose.rHand = p(84 - dx, 106 + dy)
                return pose
            }
        case "reach":
            var up = front.moved(0, 3, keepFeet: true)
            up.lElbow = p(44, 132); up.lHand = p(47, 150); up.rElbow = p(56, 132); up.rHand = p(53, 150)
            return .swing(front, up, period: 3)
        case "twist":
            var left = front
            left.lElbow = p(34, 98); left.lHand = p(46, 100); left.rElbow = p(58, 98); left.rHand = p(42, 100)
            left.head = p(47, 122)
            var right = front
            right.lElbow = p(42, 98); right.lHand = p(58, 100); right.rElbow = p(66, 98); right.rHand = p(54, 100)
            right.head = p(53, 122)
            return .swing(left, right, period: 3)
        case "neck":
            return FigureMove(period: 4) { t in
                // The head rolls from one shoulder, down past the chest, to the other, and back.
                let a = Double.pi * (1 - cos(2 * .pi * t / 4)) / 2
                var pose = front
                pose.head = p(50 + 11 * CGFloat(cos(a)), 113 - 3 * CGFloat(sin(a)))
                return pose
            }
        case "chest":
            var back = side
            back.lElbow = p(60, 108); back.lHand = p(60, 124); back.rElbow = p(60, 107); back.rHand = p(60, 123)
            var through = back
            through.head = p(68, 121); through.neck = p(66, 108); through.hip = p(60, 70)
            through.lKnee = p(68, 38); through.lFoot = p(72, 6)
            return .swing(back, through, period: 3, wallX: 60)
        default:
            return FigureMove { _ in front }
        }
    }
}

/// Draws a move's figure looping, with a floor shadow and, for some moves, a wall.
struct FigureView: View {
    let figure: String
    /// A fixed time to draw at (for snapshots); nil animates.
    var at: Double? = nil
    var color: Color = .accentColor
    /// Fine lines and an outlined head, with no floor shadow.
    var thin = false

    var body: some View {
        let move = FigureMove.named(figure)
        if let at {
            canvas(move, at)
        } else {
            TimelineView(.animation) { tl in
                canvas(move, tl.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func canvas(_ move: FigureMove, _ t: Double) -> some View {
        Canvas { ctx, size in
            let scale = min(size.width / 100, size.height / 160)
            let ox = (size.width - 100 * scale) / 2
            func pt(_ q: CGPoint) -> CGPoint { CGPoint(x: ox + q.x * scale, y: size.height - q.y * scale) }

            if !thin {
                let shadow = CGRect(x: ox + 25 * scale, y: size.height - 5 * scale, width: 50 * scale, height: 8 * scale)
                ctx.fill(Path(ellipseIn: shadow), with: .color(color.opacity(0.15)))
            }
            let line = (thin ? 1.6 : 6) * scale

            if let x = move.wallX {
                var wall = Path()
                wall.move(to: pt(p(x, 0)))
                wall.addLine(to: pt(p(x, 150)))
                ctx.stroke(wall, with: .color(color.opacity(0.3)), style: StrokeStyle(lineWidth: line / 2))
            }

            let pose = move.pose(t)
            var body = Path()
            for limb in [[pose.neck, pose.hip], [pose.neck, pose.lElbow, pose.lHand],
                         [pose.neck, pose.rElbow, pose.rHand], [pose.hip, pose.lKnee, pose.lFoot],
                         [pose.hip, pose.rKnee, pose.rFoot]] {
                body.move(to: pt(limb[0]))
                for q in limb.dropFirst() { body.addLine(to: pt(q)) }
            }
            ctx.stroke(body, with: .color(color),
                       style: StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round))
            let r = 9 * scale, h = pt(pose.head)
            let head = Path(ellipseIn: CGRect(x: h.x - r, y: h.y - r, width: 2 * r, height: 2 * r))
            if thin { ctx.stroke(head, with: .color(color), lineWidth: line) } else { ctx.fill(head, with: .color(color)) }
        }
    }
}
