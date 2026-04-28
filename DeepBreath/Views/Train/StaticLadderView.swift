import SwiftUI
import SwiftData

struct StaticLadderView: View {
    let difficulty: DifficultyLevel
    var onComplete: ((Bool) -> Void)? = nil

    @AppStorage("personalBest") private var personalBest: Double = 60
    @Environment(\.dismiss) private var dismiss
    @State private var showSession = false

    private var rounds: [TableRound] {
        TableCalculator.staticLadder(pb: personalBest, difficulty: difficulty)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                            .staggeredAppear(delay: 0.05)
                        tablePreview
                            .staggeredAppear(delay: 0.15)
                        startButton
                            .staggeredAppear(delay: 0.25)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Static Ladder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.cyan)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(isPresented: $showSession) {
                ActiveSessionView(
                    rounds: rounds,
                    sessionType: .staticLadder,
                    difficulty: difficulty,
                    pbAtTime: personalBest,
                    onSessionSaved: { completed, total in
                        onComplete?(completed >= rounds.count)
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "stairs")
                .font(.title)
                .foregroundStyle(.indigo)
                .symbolEffect(.pulse)
            VStack(alignment: .leading, spacing: 2) {
                Text("Hold confidence & mental ceiling training")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text("Ascends then descends — the easy downhill builds belief.")
                    .font(.caption2)
                    .foregroundStyle(.gray.opacity(0.7))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.indigo.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.indigo.opacity(0.2), lineWidth: 1))
    }

    private var tablePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ladder Preview")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            VStack(spacing: 0) {
                HStack {
                    Text("Round").frame(width: 55, alignment: .leading)
                    Spacer()
                    Text("Hold").frame(width: 60, alignment: .center)
                    Spacer()
                    Text("Rest").frame(width: 60, alignment: .center)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                Divider().background(Color.white.opacity(0.1))
                ForEach(Array(rounds.enumerated()), id: \.element.id) { i, round in
                    HStack {
                        Text("Round \(round.roundNumber)")
                            .frame(width: 55, alignment: .leading)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text(round.holdDuration.mmss)
                            .frame(width: 60, alignment: .center)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.indigo)
                        Spacer()
                        Text(round.restDuration.mmss)
                            .frame(width: 60, alignment: .center)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    if i < rounds.count - 1 {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var startButton: some View {
        Button { showSession = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Begin Ladder")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.indigo)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .glow(color: .indigo, radius: 14)
        }
        .buttonStyle(PressButtonStyle(scale: 0.97))
    }
}
