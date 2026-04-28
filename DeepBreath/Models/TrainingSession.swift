import Foundation
import SwiftData

enum SessionType: String, Codable, CaseIterable {
    case co2 = "CO2 Table"
    case o2 = "O2 Table"
    case freestyle = "Freestyle"
    case boxBreathing = "Box Breathing"
    case foundationBreathing = "Foundation Breathing"
    case staticLadder = "Static Ladder"
    case recovery = "Recovery Session"
    case peakAttempt = "Peak Attempt"

    var icon: String {
        switch self {
        case .co2: return "bolt.fill"
        case .o2: return "arrow.up.circle.fill"
        case .freestyle: return "stopwatch.fill"
        case .boxBreathing: return "square.fill"
        case .foundationBreathing: return "wind"
        case .staticLadder: return "stairs"
        case .recovery: return "heart.fill"
        case .peakAttempt: return "flame.fill"
        }
    }

    var accentColor: String {
        switch self {
        case .co2: return "cyan"
        case .o2: return "blue"
        case .freestyle: return "purple"
        case .boxBreathing: return "teal"
        case .foundationBreathing: return "mint"
        case .staticLadder: return "indigo"
        case .recovery: return "green"
        case .peakAttempt: return "orange"
        }
    }

    var trainingFocus: String {
        switch self {
        case .co2: return "Building CO2 tolerance"
        case .o2: return "Extending max hold time"
        case .freestyle: return "Personal record attempt"
        case .boxBreathing: return "Nervous system regulation"
        case .foundationBreathing: return "Relaxation & diaphragm control"
        case .staticLadder: return "Hold confidence & progression"
        case .recovery: return "Active recovery & reset"
        case .peakAttempt: return "Maximum effort PB test"
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"

    var holdPercentage: Double {
        switch self {
        case .easy: return 0.50
        case .normal: return 0.60
        case .hard: return 0.75
        }
    }

    var restReductionPerRound: TimeInterval {
        switch self {
        case .easy: return 10
        case .normal: return 15
        case .hard: return 20
        }
    }
}

@Model
final class TrainingSession {
    var id: UUID
    var date: Date
    var sessionType: String
    var difficulty: String
    var rounds: Int
    var completedRounds: Int
    var totalHoldTime: TimeInterval
    var pbAtTime: TimeInterval
    var notes: String

    init(
        date: Date = .now,
        sessionType: SessionType,
        difficulty: DifficultyLevel,
        rounds: Int = 8,
        completedRounds: Int = 0,
        totalHoldTime: TimeInterval = 0,
        pbAtTime: TimeInterval = 60,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.sessionType = sessionType.rawValue
        self.difficulty = difficulty.rawValue
        self.rounds = rounds
        self.completedRounds = completedRounds
        self.totalHoldTime = totalHoldTime
        self.pbAtTime = pbAtTime
        self.notes = notes
    }

    var sessionTypeEnum: SessionType {
        SessionType(rawValue: sessionType) ?? .co2
    }

    var difficultyEnum: DifficultyLevel {
        DifficultyLevel(rawValue: difficulty) ?? .normal
    }

    var isCompleted: Bool {
        completedRounds >= rounds
    }
}

@Model
final class FreestyleHold {
    var id: UUID
    var date: Date
    var duration: TimeInterval
    var isPersonalBest: Bool

    init(date: Date = .now, duration: TimeInterval, isPersonalBest: Bool = false) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.isPersonalBest = isPersonalBest
    }
}
