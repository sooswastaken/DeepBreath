import SwiftUI
import SwiftData

struct HomeView: View {
    @AppStorage("personalBest") private var personalBest: Double = 60
    @AppStorage("selectedTab") private var selectedTab = 0
    @AppStorage("quickLaunchMode") private var quickLaunchMode: String = ""
    @Query(sort: \TrainingSession.date, order: .reverse) private var sessions: [TrainingSession]
    @Query(sort: \FreestyleHold.date, order: .reverse) private var holds: [FreestyleHold]

    private var streak: Int {
        var count = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        let allDates = sessions.map { calendar.startOfDay(for: $0.date) }.sorted().reversed()
        var datesSet = Set(allDates)
        while datesSet.contains(checkDate) {
            count += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        return count
    }

    private var allTimePB: TimeInterval {
        holds.first?.duration ?? personalBest
    }

    private var todaySessions: [TrainingSession] {
        let today = Calendar.current.startOfDay(for: Date())
        return sessions.filter { Calendar.current.startOfDay(for: $0.date) == today }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        pbCard
                            .staggeredAppear(delay: 0.05)
                        statsRow
                            .staggeredAppear(delay: 0.15)
                        todayCard
                            .staggeredAppear(delay: 0.25)
                        quickStartCard
                            .staggeredAppear(delay: 0.35)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("DeepBreath")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var pbCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Personal Best")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text(allTimePB.mmss)
                    .font(.system(size: 52, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: allTimePB)
            }
            Spacer()
            Image(systemName: "trophy.fill")
                .font(.system(size: 44))
                .foregroundStyle(.yellow.opacity(0.85))
                .symbolEffect(.bounce, value: allTimePB)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.cyan.opacity(0.18), Color.blue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.cyan.opacity(0.35), lineWidth: 1)
        )
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(title: "Streak", value: "\(streak)", unit: "days", icon: "flame.fill", color: .orange)
            StatCard(title: "Sessions", value: "\(sessions.count)", unit: "total", icon: "chart.bar.fill", color: .purple)
            StatCard(title: "Today", value: "\(todaySessions.count)", unit: "done", icon: "checkmark.circle.fill", color: .green)
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Suggestion")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            let suggestion = todaySuggestion
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(suggestion.subtitle)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Button {
                    selectedTab = 1
                } label: {
                    Text("Start")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.cyan)
                        .clipShape(Capsule())
                }
                .buttonStyle(PressButtonStyle(scale: 0.93))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var quickStartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Start")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                QuickStartButton(title: "CO2", icon: "bolt.fill", color: .cyan) {
                    quickLaunchMode = "CO2 Table"
                    selectedTab = 1
                }
                QuickStartButton(title: "O2", icon: "arrow.up.circle.fill", color: .blue) {
                    quickLaunchMode = "O2 Table"
                    selectedTab = 1
                }
                QuickStartButton(title: "Freestyle", icon: "stopwatch.fill", color: .purple) {
                    quickLaunchMode = "Freestyle"
                    selectedTab = 1
                }
                QuickStartButton(title: "Box", icon: "square.fill", color: .teal) {
                    quickLaunchMode = "Box Breathing"
                    selectedTab = 1
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var todaySuggestion: (title: String, subtitle: String) {
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        switch dayOfWeek % 3 {
        case 0: return ("CO2 Table", "Build CO2 tolerance · Normal difficulty")
        case 1: return ("O2 Table", "Push your max hold time · Normal difficulty")
        default: return ("Box Breathing + Freestyle", "Warm up, then go for a PB")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .scaleEffect(appeared ? 1 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.05), value: appeared)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear { appeared = true }
    }
}

struct QuickStartButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PressButtonStyle())
    }
}
