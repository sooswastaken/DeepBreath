import Foundation

struct TableRound: Identifiable {
    let id = UUID()
    let roundNumber: Int
    let holdDuration: TimeInterval
    let restDuration: TimeInterval
}

struct TableCalculator {
    static func co2Table(pb: TimeInterval, difficulty: DifficultyLevel) -> [TableRound] {
        let holdTime = pb * difficulty.holdPercentage
        let startRest: TimeInterval = 120
        let reduction = difficulty.restReductionPerRound

        return (1...8).map { round in
            let rest = max(startRest - Double(round - 1) * reduction, 15)
            return TableRound(roundNumber: round, holdDuration: holdTime, restDuration: rest)
        }
    }

    static func staticLadder(pb: TimeInterval, difficulty: DifficultyLevel) -> [TableRound] {
        let base = pb * difficulty.holdPercentage
        let step = base * 0.25
        let rest: TimeInterval = 90
        let ascend = (1...3).map { i in
            TableRound(roundNumber: i, holdDuration: base + Double(i - 1) * step, restDuration: rest)
        }
        let descend = (1...2).map { i in
            TableRound(roundNumber: 3 + i, holdDuration: base + Double(2 - i) * step, restDuration: rest)
        }
        return ascend + descend
    }

    static func recoveryTable(pb: TimeInterval) -> [TableRound] {
        let holdTime = pb * 0.40
        let startRest: TimeInterval = 120
        return (1...8).map { round in
            let rest = max(startRest - Double(round - 1) * 10, 30)
            return TableRound(roundNumber: round, holdDuration: holdTime, restDuration: rest)
        }
    }

    static func o2Table(pb: TimeInterval, difficulty: DifficultyLevel) -> [TableRound] {
        let startHold = pb * difficulty.holdPercentage
        let maxHold = pb * 0.8
        let restTime: TimeInterval = 120
        let increment = difficulty.restReductionPerRound

        return (1...8).map { round in
            let hold = min(startHold + Double(round - 1) * increment, maxHold)
            return TableRound(roundNumber: round, holdDuration: hold, restDuration: restTime)
        }
    }
}

extension TimeInterval {
    var mmss: String {
        let total = Int(self)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    var shortDisplay: String {
        let total = Int(self)
        let m = total / 60
        let s = total % 60
        if m > 0 {
            return "\(m)m \(s)s"
        }
        return "\(s)s"
    }
}
