import Foundation
import SwiftUI

@Observable
final class FreestyleViewModel {
    var elapsedTime: TimeInterval = 0
    var isRunning = false
    var isStopped = false
    var lastHoldDuration: TimeInterval?

    private var timer: Timer?
    private var startDate: Date?
    private let audioService = AudioService()

    var displayTime: String {
        let total = Int(elapsedTime)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    func start() {
        elapsedTime = 0
        isStopped = false
        isRunning = true
        startDate = Date()
        HapticService.holdStart()
        audioService.startKeepAlive()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self, let start = self.startDate else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isStopped = true
        lastHoldDuration = elapsedTime
        audioService.stopKeepAlive()
        HapticService.restStart()
    }

    func reset() {
        elapsedTime = 0
        isRunning = false
        isStopped = false
        lastHoldDuration = nil
    }
}
