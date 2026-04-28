import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    let rounds: [TableRound]
    let sessionType: SessionType
    let difficulty: DifficultyLevel
    let pbAtTime: TimeInterval
    var onSessionSaved: ((Int, TimeInterval) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SessionViewModel(audioService: AudioService())
    @State private var showingCompletionAlert = false
    @State private var completedRounds = 0
    @State private var totalHoldTime: TimeInterval = 0

    var body: some View {
        ZStack {
            // Animated background that shifts with phase
            backgroundGradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.2), value: viewModel.phase)

            VStack(spacing: 0) {
                if viewModel.phase != .complete && viewModel.phase != .idle {
                    roundsList
                        .frame(maxHeight: 220)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }

                Spacer()
                timerDisplay
                Spacer()
                controlsArea
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.configure(rounds: rounds, type: sessionType)
            viewModel.onSessionComplete = { completed, holdTime in
                completedRounds = completed
                totalHoldTime = holdTime
                saveSession(completed: completed, totalHold: holdTime)
                showingCompletionAlert = true
            }
        }
        .alert("Session Complete!", isPresented: $showingCompletionAlert) {
            Button("Done") { dismiss() }
        } message: {
            Text("You completed \(completedRounds) of \(rounds.count) rounds.\nTotal hold time: \(totalHoldTime.shortDisplay)")
        }
    }

    private var backgroundGradient: some View {
        ZStack {
            Color.black
            LinearGradient(
                colors: phaseBackgroundColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(0.12)
        }
    }

    private var phaseBackgroundColors: [Color] {
        switch viewModel.phase {
        case .holding: return [.clear, .cyan.opacity(0.4), .clear]
        case .breatheIn: return [.clear, .orange.opacity(0.3), .clear]
        case .resting: return [.clear, .green.opacity(0.25), .clear]
        case .complete: return [.clear, .green.opacity(0.3), .clear]
        default: return [.clear, .clear]
        }
    }

    private var roundsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(rounds) { round in
                    RoundChip(
                        round: round,
                        isActive: viewModel.currentRound == round.roundNumber && viewModel.isRunning,
                        isCompleted: viewModel.currentRound > round.roundNumber || viewModel.phase == .complete,
                        currentPhase: viewModel.phase
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var timerDisplay: some View {
        ZStack {
            if viewModel.phase == .complete {
                completionDisplay
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.75).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else if viewModel.phase == .idle {
                idleDisplay
                    .transition(.opacity)
            } else {
                activeTimerDisplay
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.82), value: viewModel.phase)
    }

    private var idleDisplay: some View {
        VStack(spacing: 12) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 64))
                .foregroundStyle(.cyan.opacity(0.7))
                .symbolEffect(.pulse)
            Text("Ready to train")
                .font(.title2)
                .foregroundStyle(.gray)
            Text("\(rounds.count) rounds · \(sessionType.rawValue)")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.6))
        }
    }

    private var activeTimerDisplay: some View {
        VStack(spacing: 8) {
            // Phase label with crossfade on change
            Text(viewModel.phaseLabel)
                .font(.title3.weight(.semibold))
                .foregroundStyle(viewModel.phaseColor)
                .id(viewModel.phaseLabel)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.phaseLabel)

            // Timer ring with glow
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: 10)
                    .frame(width: 220, height: 220)

                // Glow ring (blurred copy behind)
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(viewModel.phaseColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 10)
                    .opacity(0.5)
                    .animation(.linear(duration: 0.1), value: viewModel.progress)

                // Main progress ring
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(viewModel.phaseColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: viewModel.progress)

                VStack(spacing: 4) {
                    Text(Int(ceil(viewModel.timeRemaining)).description)
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.linear(duration: 0.1), value: viewModel.timeRemaining)
                    Text("seconds")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Text("Round \(viewModel.currentRound) of \(rounds.count)")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: viewModel.currentRound)
        }
    }

    private var completionDisplay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .symbolEffect(.bounce)
                .glow(color: .green, radius: 20)

            Text("Session Complete!")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("\(completedRounds) rounds · \(totalHoldTime.shortDisplay) total hold")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private var controlsArea: some View {
        VStack(spacing: 12) {
            if viewModel.phase == .idle {
                VStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.start()
                        }
                    } label: {
                        Label("Start Session", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .glow(color: .cyan, radius: 14)
                    }
                    .buttonStyle(PressButtonStyle())

                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))

            } else if viewModel.phase != .complete {
                HStack(spacing: 12) {
                    Button {
                        viewModel.skipPhase()
                    } label: {
                        Label("Skip", systemImage: "forward.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(PressButtonStyle())

                    Button {
                        viewModel.stop()
                    } label: {
                        Label("End", systemImage: "xmark")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(PressButtonStyle())
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))

            } else {
                Button { dismiss() } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .glow(color: .green, radius: 14)
                }
                .buttonStyle(PressButtonStyle())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.phase)
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    private func saveSession(completed: Int, totalHold: TimeInterval) {
        let session = TrainingSession(
            date: .now,
            sessionType: sessionType,
            difficulty: difficulty,
            rounds: rounds.count,
            completedRounds: completed,
            totalHoldTime: totalHold,
            pbAtTime: pbAtTime
        )
        modelContext.insert(session)
        try? modelContext.save()
        onSessionSaved?(completed, totalHold)
    }
}

struct RoundChip: View {
    let round: TableRound
    let isActive: Bool
    let isCompleted: Bool
    let currentPhase: SessionPhase

    private var activeColor: Color {
        currentPhase == .breatheIn ? .orange : .cyan
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("R\(round.roundNumber)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isActive ? .black : isCompleted ? .gray : .white)

            Text(round.holdDuration.mmss)
                .font(.caption2.monospaced())
                .foregroundStyle(isActive ? .black.opacity(0.8) : isCompleted ? .gray : .cyan)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isActive ? activeColor :
            isCompleted ? Color.white.opacity(0.06) :
            Color.white.opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? activeColor : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isActive ? 1.08 : (isCompleted ? 0.92 : 1.0))
        .shadow(
            color: isActive ? activeColor.opacity(0.7) : .clear,
            radius: isActive ? 8 : 0
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isActive)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
}
