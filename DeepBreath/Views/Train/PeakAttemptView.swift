import SwiftUI
import SwiftData

private enum PeakPhase {
    case idle, breathing, holdReady, holding, complete
}

struct PeakAttemptView: View {
    var onComplete: ((Bool) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("personalBest") private var personalBest: Double = 60
    @AppStorage("voiceEnabled") private var voiceEnabled = true

    @State private var phase: PeakPhase = .idle
    @State private var prepRound = 0
    @State private var prepPhaseLabel = "Breathe In"
    @State private var prepProgress: Double = 0
    @State private var prepTimeRemaining: TimeInterval = 0
    @State private var holdElapsed: TimeInterval = 0
    @State private var holdStart: Date? = nil
    @State private var prepTimer: Timer? = nil
    @State private var holdTimer: Timer? = nil
    @State private var prepEnd: Date? = nil
    @State private var newPB = false
    @State private var holdDuration: TimeInterval = 0
    @State private var isInhaling = true

    private let totalPrepRounds = 3
    private let audio = AudioService()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            phaseBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                mainDisplay
                Spacer()
                controlsArea
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear { stopAll() }
    }

    private var phaseBackground: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .top, endPoint: .bottom
        )
        .opacity(0.1)
        .animation(.easeInOut(duration: 1.2), value: phase)
    }

    private var backgroundColors: [Color] {
        switch phase {
        case .breathing: return [.clear, .teal.opacity(0.5), .clear]
        case .holdReady, .holding: return [.clear, .orange.opacity(0.6), .clear]
        case .complete: return [.clear, newPB ? Color.yellow.opacity(0.5) : Color.green.opacity(0.4), .clear]
        default: return [.clear, .clear]
        }
    }

    @ViewBuilder
    private var mainDisplay: some View {
        switch phase {
        case .idle:
            idleView
                .transition(.opacity)
        case .breathing:
            breathingView
                .transition(.opacity)
        case .holdReady:
            holdReadyView
                .transition(.scale(scale: 0.9).combined(with: .opacity))
        case .holding:
            holdingView
                .transition(.opacity)
        case .complete:
            completionView
                .transition(.scale(scale: 0.8).combined(with: .opacity))
        }
    }

    private var idleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame.fill")
                .font(.system(size: 72))
                .foregroundStyle(.orange)
                .symbolEffect(.pulse)
                .glow(color: .orange, radius: 20)
            Text("Peak Attempt")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("3 breathing prep rounds, then one max hold.\nGive everything.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    private var breathingView: some View {
        VStack(spacing: 24) {
            Text("Breathing Prep")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.gray)
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: prepProgress)
                    .stroke(isInhaling ? Color.cyan : Color.teal,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.05), value: prepProgress)
                VStack(spacing: 4) {
                    Text(prepPhaseLabel)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isInhaling ? .cyan : .teal)
                        .id(prepPhaseLabel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    Text("\(Int(ceil(prepTimeRemaining)))s")
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(countsDown: true))
                }
            }
            Text("Round \(prepRound) of \(totalPrepRounds)")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private var holdReadyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange)
                .symbolEffect(.pulse)
                .glow(color: .orange, radius: 24)
            Text("Deep breath in.")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("Fill your lungs completely.\nWhen you're ready — hold.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    private var holdingView: some View {
        VStack(spacing: 16) {
            Text("HOLD")
                .font(.system(size: 28, weight: .heavy))
                .foregroundStyle(.orange)
                .glow(color: .orange, radius: 10)
            Text(holdElapsed.mmss)
                .font(.system(size: 80, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.1), value: holdElapsed)
            if personalBest > 0 {
                Text("PB: \(personalBest.mmss)")
                    .font(.subheadline)
                    .foregroundStyle(holdElapsed >= personalBest ? .yellow : .gray)
                    .animation(.easeInOut(duration: 0.3), value: holdElapsed >= personalBest)
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: newPB ? "trophy.fill" : "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(newPB ? .yellow : .green)
                .symbolEffect(.bounce)
                .glow(color: newPB ? .yellow : .green, radius: 24)
            if newPB {
                Text("New Personal Best!")
                    .font(.title.bold())
                    .foregroundStyle(.yellow)
            } else {
                Text("Hold Complete")
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }
            Text(holdDuration.mmss)
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundStyle(newPB ? .yellow : .cyan)
        }
    }

    private var controlsArea: some View {
        VStack(spacing: 12) {
            switch phase {
            case .idle:
                Button { beginPrep() } label: {
                    Label("Begin", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .glow(color: .orange, radius: 12)
                }
                .buttonStyle(PressButtonStyle())
                Button { dismiss() } label: {
                    Text("Cancel").font(.subheadline).foregroundStyle(.gray)
                }
            case .breathing:
                Button { stopAll(); dismiss() } label: {
                    Label("Cancel", systemImage: "xmark")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressButtonStyle())
            case .holdReady:
                Button { beginHold() } label: {
                    Label("Hold Now", systemImage: "lungs.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .glow(color: .orange, radius: 12)
                }
                .buttonStyle(PressButtonStyle())
            case .holding:
                Button { endHold() } label: {
                    Label("Release", systemImage: "hand.raised.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .glow(color: .orange, radius: 12)
                }
                .buttonStyle(PressButtonStyle())
            case .complete:
                Button { dismiss() } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(newPB ? Color.yellow : Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .glow(color: newPB ? .yellow : .green, radius: 12)
                }
                .buttonStyle(PressButtonStyle())
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: phase)
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }

    // MARK: - Logic

    private func beginPrep() {
        audio.startKeepAlive()
        prepRound = 1
        isInhaling = true
        phase = .breathing
        if voiceEnabled { audio.speak("Three breathing cycles before your hold. Begin.") }
        startPrepPhase(duration: 5, label: "Breathe In", inhaling: true)
    }

    private func startPrepPhase(duration: TimeInterval, label: String, inhaling: Bool) {
        prepPhaseLabel = label
        isInhaling = inhaling
        prepProgress = 0
        prepTimeRemaining = duration
        prepEnd = Date().addingTimeInterval(duration)
        prepTimer?.invalidate()
        prepTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            tickPrep(duration: duration)
        }
    }

    private func tickPrep(duration: TimeInterval) {
        guard let end = prepEnd else { return }
        prepTimeRemaining = max(0, end.timeIntervalSinceNow)
        prepProgress = 1.0 - (prepTimeRemaining / duration)
        if prepTimeRemaining <= 0 { advancePrep() }
    }

    private func advancePrep() {
        prepTimer?.invalidate()
        if isInhaling {
            startPrepPhase(duration: 7, label: "Breathe Out", inhaling: false)
        } else {
            if prepRound >= totalPrepRounds {
                showHoldReady()
            } else {
                prepRound += 1
                startPrepPhase(duration: 5, label: "Breathe In", inhaling: true)
            }
        }
    }

    private func showHoldReady() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            phase = .holdReady
        }
        if voiceEnabled {
            audio.speak("Take a deep final breath. Fill your lungs. Then hold.")
        }
    }

    private func beginHold() {
        holdElapsed = 0
        holdStart = Date()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            phase = .holding
        }
        HapticService.holdStart()
        if voiceEnabled { audio.speak("Hold.") }
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let s = holdStart else { return }
            holdElapsed = Date().timeIntervalSince(s)
        }
    }

    private func endHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdDuration = holdElapsed
        audio.stopKeepAlive()
        HapticService.restStart()

        newPB = holdDuration > personalBest
        if newPB {
            personalBest = holdDuration
            if voiceEnabled { audio.speak("New personal best! Incredible effort.") }
            HapticService.sessionComplete()
        } else {
            if voiceEnabled { audio.speak("Hold complete. Well done.") }
        }

        saveSession(duration: holdDuration, isPB: newPB)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            phase = .complete
        }
        onComplete?(true)
    }

    private func stopAll() {
        prepTimer?.invalidate()
        holdTimer?.invalidate()
        prepTimer = nil
        holdTimer = nil
        audio.stopKeepAlive()
    }

    private func saveSession(duration: TimeInterval, isPB: Bool) {
        let session = TrainingSession(
            date: .now,
            sessionType: .peakAttempt,
            difficulty: .hard,
            rounds: 1,
            completedRounds: 1,
            totalHoldTime: duration,
            pbAtTime: personalBest
        )
        modelContext.insert(session)

        if isPB {
            let hold = FreestyleHold(date: .now, duration: duration, isPersonalBest: true)
            modelContext.insert(hold)
            let prev = try? modelContext.fetch(FetchDescriptor<FreestyleHold>())
            prev?.filter { $0.isPersonalBest && $0.id != hold.id }.forEach { $0.isPersonalBest = false }
        }

        try? modelContext.save()
    }
}
