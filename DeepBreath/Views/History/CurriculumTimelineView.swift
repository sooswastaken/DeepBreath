import SwiftUI
import SwiftData

struct CurriculumTimelineView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Query(sort: \FreestyleHold.date, order: .reverse) private var holds: [FreestyleHold]
    @Query private var curriculumStates: [CurriculumState]
    @AppStorage("personalBest") private var personalBest: Double = 60

    private var state: CurriculumState? { curriculumStates.first }
    private var tier: TrainingTier { CurriculumEngine.tier(for: personalBest) }
    private var pbHolds: [FreestyleHold] { holds.filter { $0.isPersonalBest } }

    var body: some View {
        LazyVStack(spacing: 0) {
            currentLevelCard
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .staggeredAppear(delay: 0.05)

            if sessions.isEmpty {
                emptyState
                    .padding(.top, 60)
            } else {
                timelineContent
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Level Card

    private var currentLevelCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tierColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Image(systemName: tierIcon)
                        .font(.title2)
                        .foregroundStyle(tierColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Current Level")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Text(tier.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("PB: \(personalBest.mmss) · \(tier.pbThreshold)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(sessions.count)")
                        .font(.title2.bold())
                        .foregroundStyle(tierColor)
                    Text("sessions")
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }

            if let s = state {
                let current = s.sessionsAtTier % s.sessionsNeededToProgress
                let needed = s.sessionsNeededToProgress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(current) of \(needed) to next progression")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08)).frame(height: 5)
                            Capsule()
                                .fill(tierColor)
                                .frame(width: geo.size.width * s.progressFraction, height: 5)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: s.progressFraction)
                        }
                    }
                    .frame(height: 5)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(tierColor.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Timeline

    private var timelineContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Training Timeline")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 12)

            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                TimelineRow(
                    session: session,
                    isFirst: index == 0,
                    isLast: index == sessions.count - 1,
                    pbHoldDates: Set(pbHolds.map { Calendar.current.startOfDay(for: $0.date) })
                )
                .staggeredAppear(delay: Double(min(index, 8)) * 0.04)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(.gray.opacity(0.4))
            Text("No sessions yet.\nComplete your first session to start your timeline.")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    private var tierColor: Color {
        switch tier {
        case .beginner: return .green
        case .intermediate: return .cyan
        case .advanced: return .orange
        }
    }

    private var tierIcon: String {
        switch tier {
        case .beginner: return "leaf.fill"
        case .intermediate: return "bolt.fill"
        case .advanced: return "flame.fill"
        }
    }
}

struct TimelineRow: View {
    let session: TrainingSession
    let isFirst: Bool
    let isLast: Bool
    let pbHoldDates: Set<Date>

    private var sessionDay: Date { Calendar.current.startOfDay(for: session.date) }
    private var wasPBDay: Bool { pbHoldDates.contains(sessionDay) }
    private var isPeakAttempt: Bool { session.sessionTypeEnum == .peakAttempt }
    private var accentColor: Color { typeColor(session.sessionTypeEnum) }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            timelineTrack
            sessionContent
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.vertical, 10)
        }
        .padding(.leading, 16)
    }

    private var timelineTrack: some View {
        VStack(spacing: 0) {
            if !isFirst {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 2)
                    .frame(height: 14)
            } else {
                Spacer().frame(height: 14)
            }
            ZStack {
                if wasPBDay || isPeakAttempt {
                    Circle()
                        .fill(wasPBDay ? Color.yellow.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 28, height: 28)
                }
                Circle()
                    .fill(accentColor)
                    .frame(width: wasPBDay || isPeakAttempt ? 14 : 10, height: wasPBDay || isPeakAttempt ? 14 : 10)
            }
            .frame(width: 28)
            if !isLast {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 28)
    }

    private var sessionContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(session.sessionType)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                if session.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                if wasPBDay {
                    Label("New PB", systemImage: "trophy.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.12))
                        .clipShape(Capsule())
                }
                if isPeakAttempt && !wasPBDay {
                    Label("Peak", systemImage: "flame.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            HStack(spacing: 8) {
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text("·")
                    .foregroundStyle(.gray.opacity(0.4))
                Text("\(session.completedRounds)/\(session.rounds) rounds")
                    .font(.caption)
                    .foregroundStyle(session.isCompleted ? .green.opacity(0.8) : .red.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func typeColor(_ type: SessionType) -> Color {
        switch type {
        case .co2: return .cyan
        case .o2: return .blue
        case .freestyle: return .purple
        case .boxBreathing: return .teal
        case .foundationBreathing: return .mint
        case .staticLadder: return .indigo
        case .recovery: return .green
        case .peakAttempt: return .orange
        }
    }
}
