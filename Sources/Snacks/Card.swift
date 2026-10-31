import SwiftUI
import SnackCore

/// How a snack ended.
enum Outcome: String {
    case done, stopped, later, away
}

let sage = Color(red: 0.25, green: 0.55, blue: 0.42)

final class CardModel: ObservableObject {
    enum Stage { case offer, running, finished }

    @Published var move: Move
    @Published var stage: Stage = .offer
    @Published var remaining: Int = 0

    /// Swaps in another move; set by whoever shows the card.
    var another: () -> Move? = { nil }
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

    func stop() { timer?.invalidate(); onEnd(.stopped) }
    func later() { onEnd(.later) }

    func swap() {
        guard let next = another() else { return }
        move = next
        if stage == .running { start() } else { remaining = next.seconds }
    }

    deinit { timer?.invalidate() }
}

/// A button drawn by hand, so it keeps its colour in a window that isn't focused.
struct PillButton: View {
    let title: String
    var filled = true
    var big = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(big ? .title3.weight(.semibold) : .callout.weight(.semibold))
                .foregroundStyle(filled ? Color.white : Color.primary)
                .padding(.horizontal, big ? 22 : 14).padding(.vertical, big ? 8 : 4)
                .background(filled ? sage : Color.primary.opacity(0.08), in: Capsule())
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
            FigureView(figure: model.move.figure, at: figureAt, color: sage)
                .frame(width: 30, height: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text("Snack time?").font(.headline)
                Text("\(model.move.title) · \(model.move.seconds) s")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer(minLength: 16)
            PillButton(title: "Later", filled: false, action: model.later)
            PillButton(title: "Yes", action: model.yes)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(width: 380)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.quaternary))
    }
}

/// The full-screen snack: a big figure, what to do, and a countdown ring.
struct SnackView: View {
    @ObservedObject var model: CardModel
    var figureAt: Double? = nil

    private var progress: Double {
        model.stage == .finished ? 1 : Double(model.move.seconds - model.remaining) / Double(max(1, model.move.seconds))
    }

    var body: some View {
        ZStack {
            Color(red: 0.93, green: 0.96, blue: 0.93).ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                FigureView(figure: model.move.figure, at: figureAt, color: sage)
                    .frame(width: 220, height: 330)
                Text(model.move.title)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(white: 0.12))
                Text(model.move.text)
                    .font(.title2)
                    .foregroundStyle(Color(white: 0.3))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 620)
                ZStack {
                    Circle().stroke(sage.opacity(0.15), lineWidth: 10)
                    Circle().trim(from: 0, to: progress)
                        .stroke(sage, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.25), value: progress)
                    if model.stage == .finished {
                        Image(systemName: "checkmark").font(.system(size: 40, weight: .bold)).foregroundStyle(sage)
                    } else {
                        Text("\(model.remaining)")
                            .font(.system(size: 40, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(Color(white: 0.12))
                    }
                }
                .frame(width: 110, height: 110)
                Text(model.stage == .finished ? "Done. Back to it." : " ")
                    .font(.title3.weight(.medium)).foregroundStyle(sage)
                Spacer()
                HStack(spacing: 24) {
                    Button("Another move", action: model.swap)
                    Button("Stop  esc", action: model.stop).keyboardShortcut(.cancelAction)
                }
                .buttonStyle(.plain)
                .font(.callout)
                .foregroundStyle(Color(white: 0.45))
                .opacity(model.stage == .finished ? 0 : 1)
                .padding(.bottom, 40)
            }
            .padding(40)
        }
        .environment(\.colorScheme, .light)
    }
}
