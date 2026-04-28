import SwiftUI
import SwiftData

struct FreestyleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("personalBest") private var personalBest: Double = 60
    @Query(sort: \FreestyleHold.date, order: .reverse) private var holds: [FreestyleHold]

    @State private var viewModel = FreestyleViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // Pulse background when running
                if viewModel.isRunning {
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.08), Color.clear],
                        center: .center,
                        startRadius: 60,
                        endRadius: 280
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                }

                VStack(spacing: 32) {
                    Spacer()

                    timerDisplay
                        .staggeredAppear(delay: 0.05, yOffset: -8)

                    controlButtons

                    if viewModel.isStopped, let duration = viewModel.lastHoldDuration {
                        saveSection(duration: duration)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }

                    if !holds.isEmpty {
                        recentHolds
                            .staggeredAppear(delay: 0.2)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .animation(.spring(response: 0.5, dampingFraction: 0.82), value: viewModel.isStopped)
                .animation(.easeInOut(duration: 0.4), value: viewModel.isRunning)
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
                .shadow(
                    color: viewModel.isRunning ? Color.cyan.opacity(0.6) : .clear,
                    radius: viewModel.isRunning ? 20 : 0
                )
                .animation(.easeInOut(duration: 0.4), value: viewModel.isRunning)

            if !viewModel.isRunning && !viewModel.isStopped {
                Text("Tap to start your hold")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isRunning)
    }

    private var controlButtons: some View {
        ZStack {
            if !viewModel.isRunning && !viewModel.isStopped {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        viewModel.start()
                    }
                } label: {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .foregroundStyle(.black)
                        )
                        .glow(color: .cyan, radius: 16)
                }
                .buttonStyle(PressButtonStyle(scale: 0.91))
                .transition(.scale(scale: 0.6).combined(with: .opacity))

            } else if viewModel.isRunning {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        viewModel.stop()
                    }
                } label: {
                    Circle()
                        .fill(Color.red.opacity(0.85))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "stop.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        )
                        .glow(color: .red, radius: 16)
                }
                .buttonStyle(PressButtonStyle(scale: 0.91))
                .transition(.scale(scale: 0.6).combined(with: .opacity))

            } else {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        viewModel.reset()
                    }
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
                .buttonStyle(PressButtonStyle(scale: 0.91))
                .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: viewModel.isRunning)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: viewModel.isStopped)
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
                        .symbolEffect(.bounce)
                        .glow(color: .yellow, radius: 14)
                }
            }
            .padding()
            .background(isPB ? Color.yellow.opacity(0.12) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isPB ? Color.yellow.opacity(0.3) : Color.clear, lineWidth: 1)
            )

            Button {
                saveHold(duration: duration, isPB: isPB)
                if isPB { personalBest = duration }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.reset()
                }
            } label: {
                Label("Save Hold", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .glow(color: .cyan, radius: 12)
            }
            .buttonStyle(PressButtonStyle(scale: 0.97))
        }
    }

    private var recentHolds: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Holds")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            ForEach(Array(holds.prefix(3).enumerated()), id: \.element.id) { index, hold in
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
                .staggeredAppear(delay: Double(index) * 0.07 + 0.25)
            }
        }
    }

    private func saveHold(duration: TimeInterval, isPB: Bool) {
        let hold = FreestyleHold(date: .now, duration: duration, isPersonalBest: isPB)
        modelContext.insert(hold)
        try? modelContext.save()
    }
}
