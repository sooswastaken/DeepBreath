import Foundation
import SwiftData

enum TrainingTier: String, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var pbThreshold: String {
        switch self {
        case .beginner: return "under 1:30"
        case .intermediate: return "1:30 – 3:00"
        case .advanced: return "3:00+"
        }
    }

    var description: String {
        switch self {
        case .beginner: return "CO2 tables, foundation breathing, box breathing"
        case .intermediate: return "O2 tables, static ladders, first peak attempts"
        case .advanced: return "Full mix, compressed rest, frequent peak attempts"
        }
    }
}

@Model
final class CurriculumState {
    var currentTierRaw: String
    var sessionsAtTier: Int
    var consecutiveSuccesses: Int
    var consecutiveFailures: Int
    var lastSessionDate: Date?
    var lastSessionWasFailure: Bool
    var lastPeakAttemptDate: Date?
    var nextSessionTypeRaw: String
    var nextSessionDifficultyRaw: String
    var trainingFrequencyGoal: Int
    var restDaysData: Data   // JSON-encoded [Int]

    init() {
        self.currentTierRaw = TrainingTier.beginner.rawValue
        self.sessionsAtTier = 0
        self.consecutiveSuccesses = 0
        self.consecutiveFailures = 0
        self.lastSessionDate = nil
        self.lastSessionWasFailure = false
        self.lastPeakAttemptDate = nil
        self.nextSessionTypeRaw = SessionType.foundationBreathing.rawValue
        self.nextSessionDifficultyRaw = DifficultyLevel.easy.rawValue
        self.trainingFrequencyGoal = 3
        self.restDaysData = (try? JSONEncoder().encode([Int]())) ?? Data()
    }

    var tier: TrainingTier {
        TrainingTier(rawValue: currentTierRaw) ?? .beginner
    }

    var nextSessionType: SessionType {
        SessionType(rawValue: nextSessionTypeRaw) ?? .foundationBreathing
    }

    var nextDifficulty: DifficultyLevel {
        DifficultyLevel(rawValue: nextSessionDifficultyRaw) ?? .easy
    }

    var restDays: [Int] {
        get { (try? JSONDecoder().decode([Int].self, from: restDaysData)) ?? [] }
        set { restDaysData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var daysSinceLastSession: Int {
        guard let last = lastSessionDate else { return 999 }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: Date())).day ?? 0
    }

    var daysSinceLastPeak: Int {
        guard let last = lastPeakAttemptDate else { return 999 }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: Date())).day ?? 0
    }

    var sessionsNeededToProgress: Int { 3 }

    var progressFraction: Double {
        min(Double(sessionsAtTier % sessionsNeededToProgress) / Double(sessionsNeededToProgress), 1.0)
    }
}
