import SwiftUI
import SwiftData

struct TableSetupView: View {
    let sessionType: SessionType
    var presetDifficulty: DifficultyLevel? = nil
    var onSessionSaved: ((Int, TimeInterval) -> Void)? = nil
    @AppStorage("personalBest") private var personalBest: Double = 60
    @State private var difficulty: DifficultyLevel = .normal
    @State private var pbSeconds: String = ""
    @State private var showSession = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var pbFieldFocused: Bool
    @Namespace private var difficultyNS

    private var pb: TimeInterval {
        if let custom = Double(pbSeconds), custom > 0 { return custom }
        return personalBest
    }

    private var rounds: [TableRound] {
        switch sessionType {
        case .co2: return TableCalculator.co2Table(pb: pb, difficulty: difficulty)
        case .o2: return TableCalculator.o2Table(pb: pb, difficulty: difficulty)
        default: return []
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerCard
                            .staggeredAppear(delay: 0.05)
                        difficultyPicker
                            .staggeredAppear(delay: 0.12)
                        pbField
                            .staggeredAppear(delay: 0.19)
                        tablePreview
                            .staggeredAppear(delay: 0.26)
                        startButton
                            .staggeredAppear(delay: 0.33)
                    }
                    .padding(16)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle(sessionType.rawValue)
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
                    sessionType: sessionType,
                    difficulty: difficulty,
                    pbAtTime: pb,
                    onSessionSaved: onSessionSaved
                )
            }
            .onAppear {
                if let preset = presetDifficulty { difficulty = preset }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: sessionType == .co2 ? "bolt.fill" : "arrow.up.circle.fill")
                .font(.title)
                .foregroundStyle(sessionType == .co2 ? .cyan : .blue)
                .symbolEffect(.pulse)

            VStack(alignment: .leading, spacing: 2) {
                Text(sessionType == .co2 ? "8 rounds · Hold constant · Rest decreases" : "8 rounds · Rest constant · Hold increases")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var difficultyPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Difficulty")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            difficulty = level
                        }
                    } label: {
                        ZStack {
                            if difficulty == level {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(difficultyColor(level))
                                    .matchedGeometryEffect(id: "difficultyBG", in: difficultyNS)
                            }
                            Text(level.rawValue)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(difficulty == level ? .black : .gray)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                        }
                        .background(difficulty == level ? Color.clear : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(PressButtonStyle(scale: 0.97))
                }
            }
        }
    }

    private var pbField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Personal Best Override (optional)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            HStack {
                TextField("e.g. 90", text: $pbSeconds)
                    .keyboardType(.numberPad)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                pbFieldFocused ? Color.cyan.opacity(0.6) : Color.clear,
                                lineWidth: 1.5
                            )
                            .animation(.easeInOut(duration: 0.2), value: pbFieldFocused)
                    )
                    .focused($pbFieldFocused)

                Text("sec  →  Using \(Int(pb))s")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .fixedSize()
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: pb)
            }
        }
    }

    private var tablePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Table Preview")
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

                ForEach(Array(rounds.enumerated()), id: \.element.id) { index, round in
                    HStack {
                        Text("Round \(round.roundNumber)")
                            .frame(width: 55, alignment: .leading)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Spacer()
                        Text(round.holdDuration.mmss)
                            .frame(width: 60, alignment: .center)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.cyan)
                            .contentTransition(.numericText())
                        Spacer()
                        Text(round.restDuration.mmss)
                            .frame(width: 60, alignment: .center)
                            .font(.subheadline.monospaced())
                            .foregroundStyle(.green)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .animation(.easeOut(duration: 0.25).delay(Double(index) * 0.03), value: difficulty)

                    if round.roundNumber < rounds.count {
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .animation(.easeInOut(duration: 0.25), value: difficulty)
        }
    }

    private var startButton: some View {
        Button {
            showSession = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                Text("Begin Session")
                    .font(.headline)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(sessionType == .co2 ? Color.cyan : Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .glow(color: sessionType == .co2 ? .cyan : .blue, radius: 16)
        }
        .buttonStyle(PressButtonStyle(scale: 0.97))
    }

    private var startButtonColor: Color {
        sessionType == .co2 ? .cyan : .blue
    }

    private func difficultyColor(_ level: DifficultyLevel) -> Color {
        switch level {
        case .easy: return .green
        case .normal: return .cyan
        case .hard: return .orange
        }
    }
}
