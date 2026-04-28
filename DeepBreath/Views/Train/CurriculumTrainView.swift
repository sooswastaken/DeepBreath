import SwiftUI
import SwiftData

struct CurriculumTrainView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Query private var curriculumStates: [CurriculumState]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("personalBest") private var personalBest: Double = 60

    @State private var activeSheet: ActiveSheet? = nil
    @State private var showWhySheet = false
    @State private var appeared = false

    private var state: CurriculumState {
        if let s = curriculumStates.first { return s }
        let s = CurriculumState()
        modelContext.insert(s)
        try? modelContext.save()
        return s
    }

    private var plan: NextSessionPlan {
        CurriculumEngine.nextSession(state: state, pb: personalBest, sessions: sessions)
    }

    private var tier: TrainingTier {
        CurriculumEngine.tier(for: personalBest)
    }

    private var streak: Int {
        CurriculumEngine.calculateStreak(sessions: sessions)
    }

    enum ActiveSheet: Identifiable {
        case co2(DifficultyLevel), o2(DifficultyLevel), freestyle, box
        case foundation(Int), staticLadder(DifficultyLevel), recovery, peakAttempt
        var id: String {
            switch self {
            case .co2(let d): return "co2-\(d.rawValue)"
            case .o2(let d): return "o2-\(d.rawValue)"
            case .freestyle: return "freestyle"
            case .box: return "box"
            case .foundation(let r): return "foundation-\(r)"
            case .staticLadder(let d): return "staticLadder-\(d.rawValue)"
            case .recovery: return "recovery"
            case .peakAttempt: return "peakAttempt"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        tierCard
                            .staggeredAppear(delay: 0.05)
                        curriculumCard
                            .staggeredAppear(delay: 0.15)
                        if sessions.count > 0 {
                            recentActivity
                                .staggeredAppear(delay: 0.25)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Today's Session")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $activeSheet) { sheet in
                sessionSheet(for: sheet)
            }
            .sheet(isPresented: $showWhySheet) {
                whySheet
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Tier Card

    private var tierCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tierColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: tierIcon)
                    .font(.title2)
                    .foregroundStyle(tierColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(tier.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(tier.description)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(streak)")
                    .font(.title2.bold())
                    .foregroundStyle(.orange)
                Text("day streak")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(tierColor.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Curriculum Card

    private var curriculumCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Today's Session", systemImage: "calendar.badge.clock")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.gray)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) { showWhySheet = true }
                    } label: {
                        Label("Why this?", systemImage: "questionmark.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.cyan)
                    }
                }

                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(sessionColor(plan.type).opacity(0.15))
                            .frame(width: 52, height: 52)
                        Image(systemName: plan.type.icon)
                            .font(.title2)
                            .foregroundStyle(sessionColor(plan.type))
                            .symbolEffect(.pulse)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(plan.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(plan.type.trainingFocus)
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Text("~\(plan.estimatedMinutes) min")
                            .font(.caption2)
                            .foregroundStyle(.gray.opacity(0.7))
                    }
                    Spacer()
                }

                progressArc
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [sessionColor(plan.type).opacity(0.12), Color.clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(sessionColor(plan.type).opacity(0.25), lineWidth: 1))

            Button {
                launchSession()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Start Session")
                        .font(.headline)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(sessionColor(plan.type))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .glow(color: sessionColor(plan.type), radius: 14)
            }
            .buttonStyle(PressButtonStyle(scale: 0.97))
            .padding(.top, 10)
        }
    }

    private var progressArc: some View {
        VStack(alignment: .leading, spacing: 6) {
            let current = state.sessionsAtTier % state.sessionsNeededToProgress
            let needed = state.sessionsNeededToProgress
            HStack {
                Text("\(current) of \(needed) sessions to next step")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Spacer()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 5)
                    Capsule()
                        .fill(sessionColor(plan.type))
                        .frame(width: geo.size.width * state.progressFraction, height: 5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: state.progressFraction)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            ForEach(Array(sessions.prefix(3).enumerated()), id: \.element.id) { i, session in
                HStack(spacing: 10) {
                    Circle()
                        .fill(sessionColor(session.sessionTypeEnum).opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: session.sessionTypeEnum.icon)
                                .font(.caption)
                                .foregroundStyle(sessionColor(session.sessionTypeEnum))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.sessionType)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        Text(session.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(session.isCompleted ? .green : .red.opacity(0.7))
                        .font(.subheadline)
                }
                .padding(.vertical, 6)
                if i < 2 { Divider().background(Color.white.opacity(0.07)) }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Why Sheet

    private var whySheet: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(sessionColor(plan.type).opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: plan.type.icon)
                            .font(.system(size: 36))
                            .foregroundStyle(sessionColor(plan.type))
                    }
                    .padding(.top, 24)

                    VStack(spacing: 8) {
                        Text(plan.displayName)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text(plan.type.trainingFocus)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why today?")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(plan.reasoning)
                            .font(.body)
                            .foregroundStyle(.gray)
                            .lineSpacing(5)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Why This Session?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showWhySheet = false }
                        .foregroundStyle(.cyan)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Session Launch

    @ViewBuilder
    private func sessionSheet(for sheet: ActiveSheet) -> some View {
        switch sheet {
        case .co2(let d): TableSetupView(sessionType: .co2, presetDifficulty: d)
        case .o2(let d): TableSetupView(sessionType: .o2, presetDifficulty: d)
        case .freestyle: FreestyleView()
        case .box: BoxBreathingView()
        case .foundation(let r):
            FoundationBreathingView(rounds: r) { success in
                recordResult(success: success)
            }
        case .staticLadder(let d):
            StaticLadderView(difficulty: d) { success in
                recordResult(success: success)
            }
        case .recovery:
            RecoverySessionView { success in
                recordResult(success: success)
            }
        case .peakAttempt:
            PeakAttemptView { success in
                CurriculumEngine.recordResult(state: state, wasFailure: !success, pb: personalBest, type: .peakAttempt)
                try? modelContext.save()
            }
        }
    }

    private func launchSession() {
        switch plan.type {
        case .co2: activeSheet = .co2(plan.difficulty)
        case .o2: activeSheet = .o2(plan.difficulty)
        case .freestyle: activeSheet = .freestyle
        case .boxBreathing: activeSheet = .box
        case .foundationBreathing: activeSheet = .foundation(plan.rounds)
        case .staticLadder: activeSheet = .staticLadder(plan.difficulty)
        case .recovery: activeSheet = .recovery
        case .peakAttempt: activeSheet = .peakAttempt
        }
    }

    private func recordResult(success: Bool) {
        CurriculumEngine.recordResult(state: state, wasFailure: !success, pb: personalBest, type: plan.type)
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func sessionColor(_ type: SessionType) -> Color {
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
