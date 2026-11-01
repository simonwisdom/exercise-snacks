import SnackCore
import SwiftUI

/// How a snack ended.
enum Outcome: String {
    case done, stopped, later, away
}

/// The look, after Endel's calm screens: deep night blue, faint rings, thin light type.
enum Night {
    static let bg = Color(red: 0.043, green: 0.051, blue: 0.094)
    static let ink = Color(red: 0.91, green: 0.92, blue: 1.0)
    static let soft = Color(red: 0.78, green: 0.80, blue: 0.87)
    static let muted = Color(red: 0.48, green: 0.50, blue: 0.63)
    static let line = Color(red: 0.81, green: 0.84, blue: 1.0)
    static let edge = Color(red: 0.29, green: 0.31, blue: 0.44)
}

/// "45 sec", or "3 min" for whole minutes.
func length(_ seconds: Int) -> String { seconds >= 60 && seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds) sec" }

/// "0:32" for 32 seconds.
func clock(_ seconds: Int) -> String { String(format: "%d:%02d", seconds / 60, seconds % 60) }

final class CardModel: ObservableObject {
    enum Stage { case offer, running, finished }

    @Published var move: Move
    @Published var stage: Stage = .offer
    @Published var remaining: Int = 0
    /// How long "Later" puts the next snack off.
    var laterMinutes = 5

    /// Swaps in another move; set by whoever shows the card.
    var another: () -> Move? = { nil }
    /// Turns the current move off for good and gives another; set by whoever shows the card.
    var notForMe: () -> Move? = { nil }
    /// Called once when the snack should go.
    var onEnd: (Outcome) -> Void = { _ in }
    /// Called when Yes is pressed on the small card.
    var onYes: () -> Void = {}

    private var timer: Timer?
    private var endsAt = Date()

    init(move: Move) {
        self.move = move
        remaining = move.seconds
    }

    func yes() { onYes() }

    /// Starts (or restarts) the countdown for the current move.
    func start() {
        timer?.invalidate()
        stage = .running
        remaining = move.seconds
        endsAt = Date().addingTimeInterval(TimeInterval(move.seconds))
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in self?.tickDown() }
    }

    private func tickDown() {
        remaining = max(0, Int(endsAt.timeIntervalSinceNow.rounded(.up)))
        guard remaining == 0 else { return }
        timer?.invalidate()
        stage = .finished
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.onEnd(.done) }
    }

    func stop() {
        timer?.invalidate()
        onEnd(.stopped)
    }
    func later(_ minutes: Int) {
        laterMinutes = minutes
        onEnd(.later)
    }

    func swap() { use(another()) }
    func dropMove() { use(notForMe()) }

    private func use(_ next: Move?) {
        guard let next else { return }
        move = next
        if stage == .running { start() } else { remaining = next.seconds }
    }

    deinit { timer?.invalidate() }
}

/// Faint rings around a centre that breathe slowly; still when `at` is set.
struct Rings: View {
    var count = 4
    var at: Double? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let at = at ?? (reduceMotion ? 0 : nil) {
            draw(at)
        } else {
            TimelineView(.animation) { tl in draw(tl.date.timeIntervalSinceReferenceDate) }
        }
    }

    private func draw(_ t: Double) -> some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let step = max(size.width, size.height) / CGFloat(2 * count + 2)
            for i in 0..<count {
                let breathe = 1 + 0.04 * sin(t * 2 * .pi / 8 - Double(i) * 0.6)
                let r = step * CGFloat(i + 1) * 1.2 * breathe
                let ring = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
                ctx.stroke(ring, with: .color(Night.line.opacity(0.5 - 0.11 * Double(i))), lineWidth: 1)
            }
        }
    }
}

/// A small text button for the dark card and screen.
struct QuietButton: View {
    let title: String
    var outlined = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: outlined ? .regular : .light))
                .foregroundStyle(outlined ? Night.ink : Night.muted)
                .padding(.horizontal, outlined ? 14 : 6).padding(.vertical, 5)
                .overlay(Capsule().strokeBorder(outlined ? Night.edge : .clear))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// The small card at the top of the screen that asks first.
struct PromptView: View {
    @ObservedObject var model: CardModel
    var figureAt: Double? = nil

    var body: some View {
        HStack(spacing: 12) {
            Rings(count: 3, at: figureAt).frame(width: 26, height: 26).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("A short pause").font(.system(size: 13, weight: .light)).foregroundStyle(Night.ink)
                Text("\(model.move.title.lowercased()) · \(length(model.move.seconds))")
                    .font(.system(size: 11, weight: .light)).foregroundStyle(Night.muted)
            }
            Spacer(minLength: 12)
            QuietButton(title: "+5") { model.later(5) }.accessibilityLabel("Later, in 5 minutes")
            QuietButton(title: "+15") { model.later(15) }.accessibilityLabel("Later, in 15 minutes")
            QuietButton(title: "Begin", outlined: true, action: model.yes)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(width: 380)
        .background(Night.bg, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Night.edge.opacity(0.6)))
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Snack: \(model.move.title), \(model.move.seconds) seconds")
    }
}

/// The full-screen snack: faint rings, a thin figure, the name and the time.
struct SnackView: View {
    @ObservedObject var model: CardModel
    var figureAt: Double? = nil

    private var progress: Double {
        model.stage == .finished ? 1 : Double(model.move.seconds - model.remaining) / Double(max(1, model.move.seconds))
    }

    var body: some View {
        GeometryReader { geo in screen(ring: min(420, geo.size.height * 0.4)) }
            .environment(\.colorScheme, .dark)
    }

    private func screen(ring: CGFloat) -> some View {
        ZStack {
            Night.bg.ignoresSafeArea()
            Rings(at: figureAt).ignoresSafeArea().accessibilityHidden(true)
            Circle().trim(from: 0, to: progress)
                .stroke(Night.line.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.25), value: progress)
                .frame(width: ring, height: ring)
                .accessibilityHidden(true)
            FigureView(figure: model.move.figure, at: figureAt, color: Night.ink, thin: true)
                .frame(width: ring * 0.4, height: ring * 0.62)
                .accessibilityLabel(model.move.title)
            VStack(spacing: 10) {
                Text(model.move.title.lowercased())
                    .font(.system(size: 22, weight: .light)).tracking(1.5)
                    .foregroundStyle(Night.soft)
                Text(model.move.text)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Night.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
                Spacer()
                Text(model.stage == .finished ? "done. back to it." : clock(model.remaining))
                    .font(.system(size: model.stage == .finished ? 22 : 44, weight: .ultraLight).monospacedDigit())
                    .tracking(3)
                    .foregroundStyle(Night.soft)
                    .accessibilityLabel(model.stage == .finished ? "Done" : "\(model.remaining) seconds left")
                HStack(spacing: 20) {
                    QuietButton(title: "another move  →", action: model.swap).keyboardShortcut(
                        .rightArrow, modifiers: [])
                    QuietButton(title: "not for me", action: model.dropMove)
                        .accessibilityHint("Turns this move off. Turn moves back on from the menu.")
                    Button(action: model.stop) {
                        Text("stop  esc").font(.system(size: 12, weight: .light)).foregroundStyle(Night.muted)
                    }
                    .buttonStyle(.plain).keyboardShortcut(.cancelAction)
                }
                .opacity(model.stage == .finished ? 0 : 1)
            }
            .padding(.vertical, 50)
        }
    }
}
