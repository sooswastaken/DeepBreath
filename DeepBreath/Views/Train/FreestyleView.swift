import SwiftUI
import SwiftData

struct FreestyleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("personalBest") private var personalBest: Double = 60
    @Query(sort: \FreestyleHold.date, order: .reverse) private var holds: [FreestyleHold]

    @State private var viewModel = FreestyleViewModel()
    @State private var showSaveAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    timerDisplay

                    controlButtons

                    if viewModel.isStopped, let duration = viewModel.lastHoldDuration {
                        saveSection(duration: duration)
                    }

                    if !holds.isEmpty {
                        recentHolds
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Freestyle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.cyan)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text(viewModel.displayTime)
                .font(.system(size: 80, weight: .bold, design: .monospaced))
                .foregroundStyle(viewModel.isRunning ? .cyan : .white)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.linear(duration: 0.01), value: viewModel.displayTime)

            if !viewModel.isRunning && !viewModel.isStopped {
                Text("Tap to start your hold")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 20) {
            if !viewModel.isRunning && !viewModel.isStopped {
                Button {
                    viewModel.start()
                } label: {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundStyle(.black)
                        )
                }
            } else if viewModel.isRunning {
                Button {
                    viewModel.stop()
                } label: {
                    Circle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "stop.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        )
                }
            } else {
                Button {
                    viewModel.reset()
                } label: {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                                .foregroundStyle(.white)
                        )
                }
            }
        }
    }

    private func saveSection(duration: TimeInterval) -> some View {
        let isPB = duration > personalBest

        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isPB ? "New Personal Best!" : "Hold Complete")
                        .font(.headline)
                        .foregroundStyle(isPB ? .yellow : .white)
                    Text(duration.mmss)
                        .font(.title2.bold().monospaced())
                        .foregroundStyle(isPB ? .yellow : .cyan)
                }
                Spacer()
                if isPB {
                    Image(systemName: "trophy.fill")
                        .font(.title)
                        .foregroundStyle(.yellow)
                }
            }
            .padding()
            .background(isPB ? Color.yellow.opacity(0.12) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Button {
                saveHold(duration: duration, isPB: isPB)
                if isPB { personalBest = duration }
                viewModel.reset()
            } label: {
                Label("Save Hold", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var recentHolds: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Holds")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            ForEach(holds.prefix(3)) { hold in
                HStack {
                    Text(hold.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Spacer()
                    if hold.isPersonalBest {
                        Image(systemName: "trophy.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    Text(hold.duration.mmss)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.cyan)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private func saveHold(duration: TimeInterval, isPB: Bool) {
        let hold = FreestyleHold(date: .now, duration: duration, isPersonalBest: isPB)
        modelContext.insert(hold)
        try? modelContext.save()
    }
}
