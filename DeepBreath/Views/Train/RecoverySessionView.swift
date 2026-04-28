import SwiftUI
import SwiftData

struct RecoverySessionView: View {
    var onComplete: ((Bool) -> Void)? = nil

    @AppStorage("personalBest") private var personalBest: Double = 60
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showCO2Session = false

    private var rounds: [TableRound] {
        TableCalculator.recoveryTable(pb: personalBest)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                            .staggeredAppear(delay: 0.05)
                        infoCard
                            .staggeredAppear(delay: 0.12)
                        tablePreview
                            .staggeredAppear(delay: 0.20)
                        startButton
                            .staggeredAppear(delay: 0.28)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Recovery Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.cyan)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(isPresented: $showCO2Session) {
                ActiveSessionView(
                    rounds: rounds,
                    sessionType: .recovery,
                    difficulty: .easy,
                    pbAtTime: personalBest,
                    onSessionSaved: { completed, _ in
                        onComplete?(completed >= rounds.count)
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "heart.fill")
                .font(.title)
                .foregroundStyle(.green)
                .symbolEffect(.pulse)
            VStack(alignment: .leading, spacing: 2) {
                Text("Easy CO2 table at 40% PB")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text("8 rounds · Light holds · Gradual rest reduction")
                    .font(.caption2)
                    .foregroundStyle(.gray.opacity(0.7))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.2), lineWidth: 1))
    }

    private var infoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.green)
            Text("Recovery sessions rebuild confidence without stress. Don't push hard — the goal is showing up.")
                .font(.caption)
                .foregroundStyle(.gray)
                .lineSpacing(4)
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tablePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Preview")
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
                            .foregroundStyle(.green)
                        Spacer()
                        Text(round.restDuration.mmss)
                            .frame(width: 60, alignment: .center)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.gray)
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
        Button { showCO2Session = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Begin Recovery")
                    .font(.headline)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .glow(color: .green, radius: 14)
        }
        .buttonStyle(PressButtonStyle(scale: 0.97))
    }
}
