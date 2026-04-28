import Foundation
import SwiftUI

enum BoxPhase: String {
    case inhale = "Breathe In"
    case holdIn = "Hold In"
    case exhale = "Breathe Out"
    case holdOut = "Hold Out"
}

@Observable
final class BoxBreathingViewModel {
    var phase: BoxPhase = .inhale
    var timeRemaining: TimeInterval = 0
    var phaseProgress: Double = 0
    var currentRound = 0
    var isRunning = false
    var intervalSeconds: Int = 4
    var totalRounds: Int = 5

    private var timer: Timer?
    private var phaseEndDate: Date?
    private let phases: [BoxPhase] = [.inhale, .holdIn, .exhale, .holdOut]
    private var phaseIndex = 0
    private let audioService = AudioService()

    var phaseColor: Color {
        switch phase {
        case .inhale: return .cyan
        case .holdIn: return .blue
        case .exhale: return .teal
        case .holdOut: return .indigo
        }
    }

    var animationScale: Double {
        switch phase {
        case .inhale: return 1.0 + phaseProgress * 0.6
        case .holdIn: return 1.6
        case .exhale: return 1.6 - phaseProgress * 0.6
        case .holdOut: return 1.0
        }
    }

    var isComplete: Bool {
        currentRound >= totalRounds && phase == .holdOut && timeRemaining <= 0
    }

    func start() {
        phaseIndex = 0
        currentRound = 1
        isRunning = true
        audioService.startKeepAlive()
        beginPhase()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        phaseEndDate = nil
        audioService.stopKeepAlive()
    }

    private func beginPhase() {
        phase = phases[phaseIndex]
        let duration = Double(intervalSeconds)
        timeRemaining = duration
        phaseProgress = 0
        phaseEndDate = Date().addingTimeInterval(duration)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard let endDate = phaseEndDate else { return }
        timeRemaining = max(0, endDate.timeIntervalSinceNow)
        phaseProgress = 1.0 - (timeRemaining / Double(intervalSeconds))
        phaseProgress = max(0, min(1, phaseProgress))

        if timeRemaining <= 0 {
            advance()
        }
    }

    private func advance() {
        phaseIndex = (phaseIndex + 1) % phases.count

        if phaseIndex == 0 {
            currentRound += 1
            if currentRound > totalRounds {
                stop()
                return
            }
        }
        beginPhase()
    }
}
