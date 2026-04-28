import Foundation
import SwiftUI
import Combine

enum SessionPhase {
    case idle
    case preparing
    case holding
    case resting
    case breatheIn
    case complete
}

private let breatheInDuration: TimeInterval = 4

@Observable
final class SessionViewModel {
    var currentRound = 1
    var phase: SessionPhase = .idle
    var timeRemaining: TimeInterval = 0
    var elapsedInPhase: TimeInterval = 0
    var rounds: [TableRound] = []
    var sessionType: SessionType = .co2
    var isRunning = false

    private var timer: Timer?
    private var phaseEndDate: Date?
    private var phaseDuration: TimeInterval = 0
    private var announcedCountdowns = Set<Int>()

    private(set) var audioService: AudioService
    var onSessionComplete: ((Int, TimeInterval) -> Void)?

    init(audioService: AudioService) {
        self.audioService = audioService
    }

    var currentRoundData: TableRound? {
        guard currentRound <= rounds.count else { return nil }
        return rounds[currentRound - 1]
    }

    var progress: Double {
        guard phaseDuration > 0, timeRemaining > 0 else { return 0 }
        return 1 - (timeRemaining / phaseDuration)
    }

    var phaseLabel: String {
        switch phase {
        case .idle: return "Ready"
        case .preparing: return "Prepare"
        case .holding: return "HOLD"
        case .resting: return "Breathe"
        case .breatheIn: return "Breathe In"
        case .complete: return "Done!"
        }
    }

    var phaseColor: Color {
        switch phase {
        case .holding: return .cyan
        case .resting: return .green
        case .breatheIn: return .orange
        case .preparing: return .orange
        case .complete: return .purple
        case .idle: return .gray
        }
    }

    func configure(rounds: [TableRound], type: SessionType) {
        self.rounds = rounds
        self.sessionType = type
        self.currentRound = 1
        self.phase = .idle
    }

    func start() {
        guard !rounds.isEmpty else { return }
        phase = .preparing
        isRunning = true
        audioService.speak("Get ready. Session starting in 5 seconds.")
        audioService.startKeepAlive()
        setPhaseTimer(5)
        startTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        phaseEndDate = nil
        audioService.stopKeepAlive()
        let completed = max(0, currentRound - 1)
        let totalHold = rounds.prefix(completed).reduce(0) { $0 + $1.holdDuration }
        onSessionComplete?(completed, totalHold)
        phase = .complete
    }

    func skipPhase() {
        advancePhase()
    }

    private func setPhaseTimer(_ duration: TimeInterval) {
        phaseDuration = duration
        timeRemaining = duration
        elapsedInPhase = 0
        phaseEndDate = Date().addingTimeInterval(duration)
        announcedCountdowns = []
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let endDate = phaseEndDate else { return }
        timeRemaining = max(0, endDate.timeIntervalSinceNow)
        elapsedInPhase = phaseDuration - timeRemaining

        let remaining = Int(ceil(timeRemaining))

        switch phase {
        case .preparing, .holding, .breatheIn:
            if remaining <= 3 && remaining > 0 && !announcedCountdowns.contains(remaining) {
                announcedCountdowns.insert(remaining)
                audioService.announceCountdown(remaining)
            }
        default: break
        }

        if timeRemaining <= 0 {
            advancePhase()
        }
    }

    private func advancePhase() {
        switch phase {
        case .preparing:
            beginBreatheIn()
        case .breatheIn:
            beginHold()
        case .holding:
            beginRest()
        case .resting:
            currentRound += 1
            if currentRound > rounds.count {
                completeSession()
            } else {
                beginBreatheIn()
            }
        default: break
        }
    }

    private func beginBreatheIn() {
        phase = .breatheIn
        setPhaseTimer(breatheInDuration)
        HapticService.impact(.medium)
        audioService.speak("Breathe in deeply.")
    }

    private func beginHold() {
        guard let round = currentRoundData else { return }
        phase = .holding
        setPhaseTimer(round.holdDuration)
        HapticService.holdStart()
        audioService.announceRound(currentRound, of: rounds.count)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.audioService.speak("Hold.")
        }
    }

    private func beginRest() {
        guard let round = currentRoundData else { return }
        phase = .resting
        setPhaseTimer(round.restDuration)
        HapticService.restStart()
        audioService.speak("Breathe out. Recover.")
    }

    private func completeSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        phaseEndDate = nil
        phase = .complete
        audioService.stopKeepAlive()
        HapticService.sessionComplete()
        audioService.announceComplete()
        let totalHold = rounds.reduce(0) { $0 + $1.holdDuration }
        onSessionComplete?(rounds.count, totalHold)
    }
}
