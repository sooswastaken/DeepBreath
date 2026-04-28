import SwiftUI
import SwiftData

struct ActiveSessionView: View {
    let rounds: [TableRound]
    let sessionType: SessionType
    let difficulty: DifficultyLevel
    let pbAtTime: TimeInterval

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SessionViewModel(audioService: AudioService())
    @State private var showingCompletionAlert = false
    @State private var completedRounds = 0
    @State private var totalHoldTime: TimeInterval = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.phase != .complete && viewModel.phase != .idle {
                    roundsList
                        .frame(maxHeight: 220)
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
        VStack(spacing: 16) {
            if viewModel.phase == .complete {
                completionDisplay
            } else if viewModel.phase == .idle {
                idleDisplay
            } else {
                activeTimerDisplay
            }
        }
    }

    private var idleDisplay: some View {
        VStack(spacing: 12) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 64))
                .foregroundStyle(.cyan.opacity(0.6))
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
            Text(viewModel.phaseLabel)
                .font(.title3.weight(.semibold))
                .foregroundStyle(viewModel.phaseColor)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 10)
                    .frame(width: 220, height: 220)

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
                    Text("seconds")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Text("Round \(viewModel.currentRound) of \(rounds.count)")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private var completionDisplay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

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
                Button {
                    viewModel.start()
                } label: {
                    Label("Start Session", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

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
                }
            } else {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
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
    }
}
