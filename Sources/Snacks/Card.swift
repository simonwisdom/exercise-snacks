import SwiftUI
import SnackCore

/// How a snack card ended.
enum Outcome: String {
    case done, stopped, later, away
}

final class CardModel: ObservableObject {
    enum Stage { case offer, running, finished }

    @Published var move: Move
    @Published var stage: Stage = .offer
    @Published var remaining: Int = 0

    /// Swaps in another move; set by whoever shows the card.
    var another: () -> Move? = { nil }
    /// Called once when the card should go.
    var onEnd: (Outcome) -> Void = { _ in }
    /// Called when Start is pressed.
    var onStart: () -> Void = {}

    private var timer: Timer?
    private var endsAt = Date()

    init(move: Move) {
        self.move = move
        remaining = move.seconds
    }

    func start() {
        stage = .running
        remaining = move.seconds
        endsAt = Date().addingTimeInterval(TimeInterval(move.seconds))
        onStart()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in self?.tickDown() }
    }

    private func tickDown() {
        remaining = max(0, Int(endsAt.timeIntervalSinceNow.rounded(.up)))
        guard remaining == 0 else { return }
        timer?.invalidate()
        stage = .finished
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in self?.onEnd(.done) }
    }

    func stop() { timer?.invalidate(); onEnd(.stopped) }
    func later() { onEnd(.later) }

    func swap() {
        if let next = another() {
            move = next
            remaining = next.seconds
        }
    }

    deinit { timer?.invalidate() }
}

/// The card in the corner: the figure doing the move, what to do, and one button.
struct CardView: View {
    @ObservedObject var model: CardModel
    /// A fixed time for the figure (snapshots); nil animates.
    var figureAt: Double? = nil

    private let green = Color(red: 0.25, green: 0.55, blue: 0.42)

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            FigureView(figure: model.move.figure, at: figureAt, color: green)
                .frame(width: 78, height: 118)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(model.move.title).font(.headline)
                    Spacer()
                    if model.stage == .offer {
                        Text("\(model.move.seconds) s").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text(model.move.text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(4)
                Spacer(minLength: 4)
                controls
            }
        }
        .padding(14)
        .frame(width: 360, height: 150)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.quaternary))
    }

    @ViewBuilder private var controls: some View {
        switch model.stage {
        case .offer:
            HStack {
                // Drawn by hand: macOS greys a prominent button in a panel that isn't focused.
                Button(action: model.start) {
                    Text("Start").font(.callout.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 4)
                        .background(green, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                Button("Later", action: model.later)
                Spacer()
                Button("Another", action: model.swap)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .running:
            HStack(spacing: 10) {
                ProgressView(value: Double(model.move.seconds - model.remaining), total: Double(model.move.seconds))
                    .tint(green)
                Text("\(model.remaining) s").font(.callout.monospacedDigit())
                Button("Stop", action: model.stop).buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
            }
        case .finished:
            Label("Done. Back to it.", systemImage: "checkmark.circle.fill")
                .foregroundStyle(green)
                .font(.callout.weight(.medium))
        }
    }
}
