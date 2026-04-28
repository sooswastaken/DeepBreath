import Foundation

struct NextSessionPlan {
    let type: SessionType
    let difficulty: DifficultyLevel
    let rounds: Int
    let estimatedMinutes: Int
    let reasoning: String
    let displayName: String
}

struct CurriculumEngine {

    // MARK: - Tier

    static func tier(for pb: TimeInterval) -> TrainingTier {
        if pb < 90 { return .beginner }
        if pb < 180 { return .intermediate }
        return .advanced
    }

    // MARK: - Next Session

    static func nextSession(
        state: CurriculumState,
        pb: TimeInterval,
        sessions: [TrainingSession]
    ) -> NextSessionPlan {
        let streak = calculateStreak(sessions: sessions)
        let days = state.daysSinceLastSession
        let tier = tier(for: pb)

        // Rule: 3+ days away → recovery
        if days >= 3 && !sessions.isEmpty {
            return plan(.recovery, difficulty: .easy, rounds: 8,
                name: "Recovery Session",
                reason: "You've been away for \(days) days. A recovery session eases you back in safely.")
        }

        // Rule: 2 consecutive failures → recovery
        if state.consecutiveFailures >= 2 {
            return plan(.recovery, difficulty: .easy, rounds: 8,
                name: "Recovery Session",
                reason: "You've exited early from the last 2 sessions. A reset now prevents overtraining.")
        }

        // Rule: streak ≥7 + non-beginner + no peak in 7 days → peak attempt
        if streak >= 7 && tier != .beginner && state.daysSinceLastPeak >= 7 {
            return plan(.peakAttempt, difficulty: .hard, rounds: 1,
                name: "Peak Attempt",
                reason: "You're on a \(streak)-day streak. Time to push your max — a peak attempt is overdue.")
        }

        return recommend(tier: tier, state: state, sessions: sessions, pb: pb)
    }

    // MARK: - Record Result

    static func recordResult(state: CurriculumState, wasFailure: Bool, pb: TimeInterval, type: SessionType) {
        state.lastSessionDate = Date()
        state.lastSessionWasFailure = wasFailure
        state.currentTierRaw = tier(for: pb).rawValue

        if type == .peakAttempt {
            state.lastPeakAttemptDate = Date()
        }

        if wasFailure {
            state.consecutiveSuccesses = 0
            state.consecutiveFailures += 1
        } else {
            state.consecutiveFailures = 0
            state.consecutiveSuccesses += 1
            state.sessionsAtTier += 1
        }

        // After 3 successes, reset streak counter (level-up or plateau progression)
        if state.consecutiveSuccesses >= 3 {
            state.consecutiveSuccesses = 0
        }

        // Compute and cache next session
        let next = nextSession(state: state, pb: pb, sessions: [])
        state.nextSessionTypeRaw = next.type.rawValue
        state.nextSessionDifficultyRaw = next.difficulty.rawValue
    }

    // MARK: - Streak

    static func calculateStreak(sessions: [TrainingSession]) -> Int {
        var count = 0
        let cal = Calendar.current
        var check = cal.startOfDay(for: Date())
        let dates = Set(sessions.map { cal.startOfDay(for: $0.date) })
        while dates.contains(check) {
            count += 1
            check = cal.date(byAdding: .day, value: -1, to: check)!
        }
        return count
    }

    // MARK: - Private helpers

    private static func recommend(
        tier: TrainingTier,
        state: CurriculumState,
        sessions: [TrainingSession],
        pb: TimeInterval
    ) -> NextSessionPlan {
        let diff = recommendedDifficulty(state: state)
        let recent6 = Array(sessions.prefix(6))
        let totalCount = sessions.count

        switch tier {
        case .beginner:
            let recentCO2 = recent6.filter { $0.sessionTypeEnum == .co2 }.count
            if recentCO2 >= 2 {
                if totalCount % 3 == 0 {
                    return plan(.boxBreathing, difficulty: .easy, rounds: 5,
                        name: "Box Breathing",
                        reason: "Cycling in box breathing trains your nervous system for calm — critical for apnea performance.")
                }
                return plan(.foundationBreathing, difficulty: .easy, rounds: 6,
                    name: "Foundation Breathing",
                    reason: "Diaphragmatic breathing technique is the foundation of every elite freediver's practice.")
            }
            return plan(.co2, difficulty: diff, rounds: 8,
                name: "CO2 Table — \(diff.rawValue)",
                reason: "CO2 tolerance is your primary limiter at this stage. These tables directly train that.")

        case .intermediate:
            let daysSinceO2 = daysSince(.o2, in: recent6)
            if daysSinceO2 >= 2 && totalCount % 2 == 0 {
                return plan(.o2, difficulty: diff, rounds: 8,
                    name: "O2 Table — \(diff.rawValue)",
                    reason: "Alternating O2 tables push your max hold ceiling. At least 48h between O2 sessions is required.")
            }
            if totalCount % 4 == 3 {
                return plan(.staticLadder, difficulty: diff, rounds: 5,
                    name: "Static Ladder — \(diff.rawValue)",
                    reason: "The descending half of a ladder feels easier — that's your brain learning what your lungs can do.")
            }
            return plan(.co2, difficulty: diff, rounds: 8,
                name: "CO2 Table — \(diff.rawValue)",
                reason: "Intermediate divers need sustained CO2 work to break through the 2-minute plateau.")

        case .advanced:
            let daysSinceO2 = daysSince(.o2, in: recent6)
            if daysSinceO2 >= 2 && totalCount % 2 == 0 {
                return plan(.o2, difficulty: .hard, rounds: 8,
                    name: "O2 Table — Hard",
                    reason: "Hard O2 tables at this tier keep pushing your ceiling. Your base is solid — trust the work.")
            }
            return plan(.co2, difficulty: .hard, rounds: 8,
                name: "CO2 Table — Hard",
                reason: "Compressed rest intervals at hard difficulty is where advanced tolerance is built.")
        }
    }

    private static func recommendedDifficulty(state: CurriculumState) -> DifficultyLevel {
        if state.consecutiveSuccesses >= 3 { return .hard }
        if state.consecutiveSuccesses >= 1 { return .normal }
        return .easy
    }

    private static func daysSince(_ type: SessionType, in sessions: [TrainingSession]) -> Int {
        guard let match = sessions.first(where: { $0.sessionTypeEnum == type }) else { return 999 }
        return Calendar.current.dateComponents([.day], from: match.date, to: Date()).day ?? 999
    }

    private static func plan(
        _ type: SessionType,
        difficulty: DifficultyLevel,
        rounds: Int,
        name: String,
        reason: String
    ) -> NextSessionPlan {
        NextSessionPlan(
            type: type,
            difficulty: difficulty,
            rounds: rounds,
            estimatedMinutes: estimatedMinutes(type: type, rounds: rounds, difficulty: difficulty),
            reasoning: reason,
            displayName: name
        )
    }

    private static func estimatedMinutes(type: SessionType, rounds: Int, difficulty: DifficultyLevel) -> Int {
        switch type {
        case .co2: return 12 + (difficulty == .hard ? -3 : 0)
        case .o2: return 14
        case .foundationBreathing: return 8
        case .staticLadder: return 10
        case .recovery: return 10
        case .peakAttempt: return 6
        case .freestyle: return 5
        case .boxBreathing: return 5
        }
    }
}
