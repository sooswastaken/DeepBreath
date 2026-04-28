import SwiftUI
import SwiftData
import Charts

struct ProgressChartsView: View {
    @Query(sort: \FreestyleHold.date, order: .forward) private var holds: [FreestyleHold]
    @Query(sort: \TrainingSession.date, order: .forward) private var sessions: [TrainingSession]

    private var pbOverTime: [(date: Date, value: Double)] {
        var pb: Double = 0
        return holds.compactMap { hold -> (date: Date, value: Double)? in
            if hold.duration > pb {
                pb = hold.duration
                return (date: hold.date, value: pb)
            }
            return nil
        }
    }

    private var weeklySessionCounts: [(week: String, count: Int)] {
        let calendar = Calendar.current
        var counts: [String: Int] = [:]
        for session in sessions {
            let week = weekLabel(for: session.date, calendar: calendar)
            counts[week, default: 0] += 1
        }
        return counts.sorted { $0.key < $1.key }.suffix(8).map { ($0.key, $0.value) }
    }

    private var totalSessions: Int { sessions.count }
    private var averageHold: TimeInterval {
        guard !holds.isEmpty else { return 0 }
        return holds.reduce(0) { $0 + $1.duration } / Double(holds.count)
    }

    var body: some View {
        VStack(spacing: 20) {
            summaryStats
            pbChart
            weeklyChart
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    private var summaryStats: some View {
        HStack(spacing: 12) {
            SummaryStatCard(title: "Total Sessions", value: "\(totalSessions)", color: .cyan)
            SummaryStatCard(title: "Avg Hold", value: averageHold.mmss, color: .blue)
            SummaryStatCard(title: "Holds Logged", value: "\(holds.count)", color: .purple)
        }
    }

    private var pbChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Personal Best Progression")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            if pbOverTime.isEmpty {
                emptyChartPlaceholder("No freestyle holds yet")
            } else {
                Chart(pbOverTime, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Hold (s)", point.value)
                    )
                    .foregroundStyle(Color.cyan)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Hold (s)", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.cyan.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Hold (s)", point.value)
                    )
                    .foregroundStyle(Color.cyan)
                    .symbolSize(30)
                }
                .chartYAxis {
                    AxisMarks(preset: .aligned) { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel {
                            if let seconds = value.as(Double.self) {
                                Text(TimeInterval(seconds).mmss)
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.05))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(.gray)
                    }
                }
                .frame(height: 180)
                .chartBackground { _ in Color.clear }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Sessions")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            if weeklySessionCounts.isEmpty {
                emptyChartPlaceholder("No sessions yet")
            } else {
                Chart(weeklySessionCounts, id: \.week) { item in
                    BarMark(
                        x: .value("Week", item.week),
                        y: .value("Sessions", item.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.08))
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(.gray)
                    }
                }
                .frame(height: 160)
                .chartBackground { _ in Color.clear }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func emptyChartPlaceholder(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, minHeight: 100)
    }

    private func weekLabel(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let year = components.yearForWeekOfYear ?? 0
        let week = components.weekOfYear ?? 0
        return String(format: "%d-W%02d", year, week)
    }
}

struct SummaryStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
