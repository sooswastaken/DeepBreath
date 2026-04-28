import SwiftUI

struct BoxBreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BoxBreathingViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 32) {
                    if viewModel.isRunning {
                        activeView
                    } else if viewModel.currentRound > viewModel.totalRounds {
                        completedView
                    } else {
                        setupView
                    }
                }
                .padding(24)
            }
            .navigationTitle("Box Breathing")
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

    private var setupView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "square.fill")
                .font(.system(size: 60))
                .foregroundStyle(.teal)

            Text("Box Breathing")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Inhale → Hold → Exhale → Hold\nCalms the nervous system and prepares you for a hold.")
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                settingRow(label: "Seconds per phase", value: $viewModel.intervalSeconds, range: 4...8)
                settingRow(label: "Total rounds", value: $viewModel.totalRounds, range: 3...8)
            }

            Button {
                viewModel.start()
            } label: {
                Label("Start Breathing", systemImage: "play.fill")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.teal)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
    }

    private var activeView: some View {
        VStack(spacing: 24) {
            Text("Round \(viewModel.currentRound) of \(viewModel.totalRounds)")
                .font(.subheadline)
                .foregroundStyle(.gray)

            ZStack {
                Circle()
                    .fill(viewModel.phaseColor.opacity(0.08))
                    .frame(
                        width: 200 * viewModel.animationScale,
                        height: 200 * viewModel.animationScale
                    )
                    .animation(.easeInOut(duration: Double(viewModel.intervalSeconds)), value: viewModel.animationScale)

                Circle()
                    .stroke(viewModel.phaseColor.opacity(0.4), lineWidth: 2)
                    .frame(
                        width: 200 * viewModel.animationScale,
                        height: 200 * viewModel.animationScale
                    )
                    .animation(.easeInOut(duration: Double(viewModel.intervalSeconds)), value: viewModel.animationScale)

                VStack(spacing: 6) {
                    Text(viewModel.phase.rawValue)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(viewModel.phaseColor)

                    Text("\(Int(ceil(viewModel.timeRemaining)))")
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
            }
            .frame(height: 340)

            phaseIndicator

            Button {
                viewModel.stop()
            } label: {
                Text("Stop")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
    }

    private var completedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.teal)

            Text("Breathing Complete")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("You're ready. Now go hold your breath.")
                .font(.body)
                .foregroundStyle(.gray)

            HStack(spacing: 12) {
                Button {
                    viewModel.start()
                } label: {
                    Text("Again")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.teal)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.teal.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button { dismiss() } label: {
                    Text("Done")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.teal)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            Spacer()
        }
    }

    private var phaseIndicator: some View {
        let phases: [BoxPhase] = [.inhale, .holdIn, .exhale, .holdOut]
        return HStack(spacing: 8) {
            ForEach(phases, id: \.self) { phase in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(phase == viewModel.phase ? viewModel.phaseColor : Color.white.opacity(0.15))
                        .frame(height: 4)
                    Text(phase.rawValue.split(separator: " ").first.map(String.init) ?? "")
                        .font(.system(size: 9))
                        .foregroundStyle(phase == viewModel.phase ? viewModel.phaseColor : .gray)
                }
            }
        }
    }

    private func settingRow(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 12) {
                Button {
                    if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                }

                Text("\(value.wrappedValue)")
                    .font(.headline.monospaced())
                    .foregroundStyle(.white)
                    .frame(width: 28)

                Button {
                    if value.wrappedValue < range.upperBound { value.wrappedValue += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
