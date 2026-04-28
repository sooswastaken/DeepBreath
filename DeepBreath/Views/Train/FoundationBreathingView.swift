import SwiftUI
import SwiftData

private enum FoundationPhase {
    case idle, inhale, exhale, complete
}

struct FoundationBreathingView: View {
    var rounds: Int = 6
    var onComplete: ((Bool) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("personalBest") private var personalBest: Double = 60
    @AppStorage("voiceEnabled") private var voiceEnabled = true

    @State private var phase: FoundationPhase = .idle
    @State private var timeRemaining: TimeInterval = 0
    @State private var progress: Double = 0
    @State private var currentRound = 1
    @State private var timer: Timer? = nil
    @State private var phaseEnd: Date? = nil
    @State private var savedRounds = 0

    private let inhaleDuration: TimeInterval = 5
    private let exhaleDuration: TimeInterval = 7
    private let audio = AudioService()

    private var circleScale: Double {
        switch phase {
        case .inhale: return 1.0 + progress * 0.55
        case .exhale: return 1.55 - progress * 0.55
        default: return 1.0
        }
    }

    private var phaseColor: Color {
        phase == .inhale ? .cyan : .mint
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LinearGradient(
                colors: [.clear, phaseColor.opacity(0.08), .clear],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.0), value: phase)

            VStack(spacing: 0) {
                Spacer()
                phaseCircle
                Spacer()
                if phase != .idle && phase != .complete {
                    roundLabel
                        .padding(.bottom, 32)
                }
                controlsArea
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear { stopTimer() }
    }

    private var phaseCircle: some View {
        ZStack {
            if phase == .complete {
                completionView
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else if phase == .idle {
                idleView
                    .transition(.opacity)
            } else {
                activeView
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: phase)
    }

    private var idleView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wind")
                .font(.system(size: 64))
                .foregroundStyle(.mint.opacity(0.7))
                .symbolEffect(.pulse)
            Text("Foundation Breathing")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("\(rounds) rounds · 5s in, 7s out")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private var activeView: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 8)
                .frame(width: 200, height: 200)

            Circle()
                .fill(phaseColor.opacity(0.15))
                .frame(width: 200, height: 200)
                .scaleEffect(circleScale)
                .animation(.linear(duration: 0.05), value: circleScale)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(phaseColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: progress)

            VStack(spacing: 4) {
                Text(phase == .inhale ? "Breathe In" : "Breathe Out")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(phaseColor)
                    .id(phase)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                Text("\(Int(ceil(timeRemaining)))s")
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.linear(duration: 0.1), value: timeRemaining)
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .symbolEffect(.bounce)
                .glow(color: .green, radius: 18)
            Text("Session Complete")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("\(rounds) rounds of foundation breathing")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private var roundLabel: some View {
        Text("Round \(currentRound) of \(rounds)")
            .font(.subheadline)
            .foregroundStyle(.gray)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.2), value: currentRound)
    }

    private var controlsArea: some View {
        VStack(spacing: 12) {
            if phase == .idle {
                Button {
                    startSession()
                } label: {
                    Label("Begin", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mint)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .glow(color: .mint, radius: 12)
                }
                .buttonStyle(PressButtonStyle())
                Button { handleDismiss(completed: false) } label: {
                    Text("Cancel").font(.subheadline).foregroundStyle(.gray)
                }
            } else if phase == .complete {
                Button {
                    handleDismiss(completed: true)
                } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .glow(color: .green, radius: 12)
                }
                .buttonStyle(PressButtonStyle())
            } else {
                Button {
                    stopSession(early: true)
                } label: {
                    Label("End Session", systemImage: "xmark")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressButtonStyle())
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: phase)
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    private func startSession() {
        currentRound = 1
        audio.startKeepAlive()
        beginInhale()
    }

    private func beginInhale() {
        phase = .inhale
        setTimer(duration: inhaleDuration)
        if voiceEnabled { audio.speak("Breathe in.") }
        HapticService.impact(.light)
    }

    private func beginExhale() {
        phase = .exhale
        setTimer(duration: exhaleDuration)
        if voiceEnabled { audio.speak("Breathe out.") }
    }

    private func setTimer(duration: TimeInterval) {
        stopTimer()
        phaseEnd = Date().addingTimeInterval(duration)
        timeRemaining = duration
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in tick(duration: duration) }
    }

    private func tick(duration: TimeInterval) {
        guard let end = phaseEnd else { return }
        timeRemaining = max(0, end.timeIntervalSinceNow)
        progress = 1.0 - (timeRemaining / duration)
        if timeRemaining <= 0 { advance() }
    }

    private func advance() {
        switch phase {
        case .inhale:
            beginExhale()
        case .exhale:
            if currentRound >= rounds {
                stopSession(early: false)
            } else {
                currentRound += 1
                beginInhale()
            }
        default: break
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        phaseEnd = nil
    }

    private func stopSession(early: Bool) {
        stopTimer()
        audio.stopKeepAlive()
        savedRounds = early ? max(0, currentRound - 1) : rounds
        saveSession(completedRounds: savedRounds, wasEarlyExit: early)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            phase = .complete
        }
        if !early {
            HapticService.sessionComplete()
            if voiceEnabled { audio.speak("Session complete. Well done.") }
        }
    }

    private func saveSession(completedRounds: Int, wasEarlyExit: Bool) {
        let session = TrainingSession(
            date: .now,
            sessionType: .foundationBreathing,
            difficulty: .easy,
            rounds: rounds,
            completedRounds: completedRounds,
            totalHoldTime: 0,
            pbAtTime: personalBest
        )
        modelContext.insert(session)
        try? modelContext.save()
        onComplete?(!wasEarlyExit)
    }

    private func handleDismiss(completed: Bool) {
        if phase != .complete { stopSession(early: !completed) }
        dismiss()
    }
}
