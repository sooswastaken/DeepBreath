import SwiftUI

struct BoxBreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = BoxBreathingViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // Ambient background color shifts with phase
                viewModel.phaseColor
                    .opacity(viewModel.isRunning ? 0.06 : 0)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 1.5), value: viewModel.phase)

                VStack(spacing: 32) {
                    Group {
                        if viewModel.isRunning {
                            activeView
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.92).combined(with: .opacity),
                                    removal: .scale(scale: 1.05).combined(with: .opacity)
                                ))
                        } else if viewModel.currentRound > viewModel.totalRounds {
                            completedView
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        } else {
                            setupView
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .scale(scale: 0.95).combined(with: .opacity)
                                ))
                        }
                    }
                    .animation(.spring(response: 0.55, dampingFraction: 0.82), value: viewModel.isRunning)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82), value: viewModel.currentRound > viewModel.totalRounds)
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
                .symbolEffect(.pulse)
                .staggeredAppear(delay: 0.05, yOffset: -8)

            Text("Box Breathing")
                .font(.title.bold())
                .foregroundStyle(.white)
                .staggeredAppear(delay: 0.12)

            Text("Inhale → Hold → Exhale → Hold\nCalms the nervous system and prepares you for a hold.")
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .staggeredAppear(delay: 0.19)

            VStack(spacing: 16) {
                settingRow(label: "Seconds per phase", value: $viewModel.intervalSeconds, range: 4...8)
                settingRow(label: "Total rounds", value: $viewModel.totalRounds, range: 3...8)
            }
            .staggeredAppear(delay: 0.26)

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
                    .glow(color: .teal, radius: 14)
            }
            .buttonStyle(PressButtonStyle(scale: 0.97))
            .staggeredAppear(delay: 0.33)

            Spacer()
        }
    }

    private var activeView: some View {
        VStack(spacing: 24) {
            Text("Round \(viewModel.currentRound) of \(viewModel.totalRounds)")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: viewModel.currentRound)

            ZStack {
                // Outer ambient glow
                Circle()
                    .fill(viewModel.phaseColor.opacity(0.05))
                    .frame(
                        width: 240 * viewModel.animationScale,
                        height: 240 * viewModel.animationScale
                    )
                    .blur(radius: 20)
                    .animation(.easeInOut(duration: Double(viewModel.intervalSeconds)), value: viewModel.animationScale)

                // Main breathing circle
                Circle()
                    .fill(viewModel.phaseColor.opacity(0.1))
                    .frame(
                        width: 200 * viewModel.animationScale,
                        height: 200 * viewModel.animationScale
                    )
                    .animation(.easeInOut(duration: Double(viewModel.intervalSeconds)), value: viewModel.animationScale)

                // Ring
                Circle()
                    .stroke(viewModel.phaseColor.opacity(0.5), lineWidth: 2)
                    .frame(
                        width: 200 * viewModel.animationScale,
                        height: 200 * viewModel.animationScale
                    )
                    .animation(.easeInOut(duration: Double(viewModel.intervalSeconds)), value: viewModel.animationScale)

                // Inner content
                VStack(spacing: 8) {
                    Text(viewModel.phase.rawValue)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(viewModel.phaseColor)
                        .id(viewModel.phase)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.phase)

                    Text("\(Int(ceil(viewModel.timeRemaining)))")
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText(countsDown: true))
                        .animation(.linear(duration: 0.05), value: viewModel.timeRemaining)
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
            .buttonStyle(PressButtonStyle(scale: 0.93))
        }
    }

    private var completedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.teal)
                .symbolEffect(.bounce)
                .glow(color: .teal, radius: 20)

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
                .buttonStyle(PressButtonStyle())

                Button { dismiss() } label: {
                    Text("Done")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.teal)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .glow(color: .teal, radius: 12)
                }
                .buttonStyle(PressButtonStyle())
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
                        .frame(height: phase == viewModel.phase ? 5 : 4)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.phase)
                    Text(phase.rawValue.split(separator: " ").first.map(String.init) ?? "")
                        .font(.system(size: 9))
                        .foregroundStyle(phase == viewModel.phase ? viewModel.phaseColor : .gray)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.phase)
                }
                .scaleEffect(phase == viewModel.phase ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: viewModel.phase)
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                        if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                }
                .buttonStyle(PressButtonStyle(scale: 0.85))

                Text("\(value.wrappedValue)")
                    .font(.headline.monospaced())
                    .foregroundStyle(.white)
                    .frame(width: 28)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value.wrappedValue)

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                        if value.wrappedValue < range.upperBound { value.wrappedValue += 1 }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.teal)
                }
                .buttonStyle(PressButtonStyle(scale: 0.85))
            }
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
