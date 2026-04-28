import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Query(sort: \FreestyleHold.date, order: .reverse) private var holds: [FreestyleHold]
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("", selection: $selectedSegment) {
                        Text("Timeline").tag(0)
                        Text("Charts").tag(1)
                        Text("Sessions").tag(2)
                        Text("Holds").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    ScrollView {
                        ZStack {
                            switch selectedSegment {
                            case 0:
                                CurriculumTimelineView()
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .leading).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            case 1:
                                ProgressChartsView()
                                    .padding(.top, 8)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            case 2:
                                sessionsList
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            case 3:
                                holdsList
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .trailing).combined(with: .opacity)
                                    ))
                            default:
                                EmptyView()
                            }
                        }
                        .animation(.easeInOut(duration: 0.28), value: selectedSegment)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var sessionsList: some View {
        LazyVStack(spacing: 10) {
            if sessions.isEmpty {
                emptyState(icon: "calendar.badge.clock", message: "No training sessions yet.\nStart training to see your history.")
            } else {
                ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                    SessionRowView(session: session)
                        .staggeredAppear(delay: Double(min(index, 6)) * 0.05)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var holdsList: some View {
        LazyVStack(spacing: 10) {
            if holds.isEmpty {
                emptyState(icon: "stopwatch", message: "No freestyle holds yet.\nRecord your first breath hold.")
            } else {
                ForEach(Array(holds.enumerated()), id: \.element.id) { index, hold in
                    HoldRowView(hold: hold)
                        .staggeredAppear(delay: Double(min(index, 6)) * 0.05)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.gray.opacity(0.4))
                .staggeredAppear(delay: 0.1, yOffset: -8)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .staggeredAppear(delay: 0.2)
        }
        .padding(.top, 80)
    }
}

struct SessionRowView: View {
    let session: TrainingSession

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: typeIcon)
                    .font(.body)
                    .foregroundStyle(typeColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(session.sessionType)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    if session.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(session.completedRounds)/\(session.rounds)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(session.difficulty)
                    .font(.caption)
                    .foregroundStyle(difficultyColor)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var typeColor: Color {
        switch session.sessionTypeEnum {
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

    private var typeIcon: String {
        switch session.sessionTypeEnum {
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

    private var difficultyColor: Color {
        switch session.difficultyEnum {
        case .easy: return .green
        case .normal: return .cyan
        case .hard: return .orange
        }
    }
}

struct HoldRowView: View {
    let hold: FreestyleHold

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(hold.isPersonalBest ? Color.yellow.opacity(0.15) : Color.purple.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: hold.isPersonalBest ? "trophy.fill" : "stopwatch.fill")
                    .font(.callout)
                    .foregroundStyle(hold.isPersonalBest ? .yellow : .purple)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(hold.isPersonalBest ? "Personal Best" : "Freestyle Hold")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(hold.isPersonalBest ? .yellow : .white)
                Text(hold.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Text(hold.duration.mmss)
                .font(.title3.bold().monospaced())
                .foregroundStyle(hold.isPersonalBest ? .yellow : .cyan)
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(hold.isPersonalBest ? Color.yellow.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}
