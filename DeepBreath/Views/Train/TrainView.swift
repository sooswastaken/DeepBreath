import SwiftUI

struct TrainView: View {
    @State private var selectedMode: TrainMode?
    @AppStorage("quickLaunchMode") private var quickLaunchMode: String = ""

    enum TrainMode: String, CaseIterable, Identifiable {
        case co2 = "CO2 Table"
        case o2 = "O2 Table"
        case freestyle = "Freestyle"
        case box = "Box Breathing"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .co2: return "bolt.fill"
            case .o2: return "arrow.up.circle.fill"
            case .freestyle: return "stopwatch.fill"
            case .box: return "square.fill"
            }
        }

        var color: Color {
            switch self {
            case .co2: return .cyan
            case .o2: return .blue
            case .freestyle: return .purple
            case .box: return .teal
            }
        }

        var description: String {
            switch self {
            case .co2: return "8 rounds · Constant hold · Decreasing rest"
            case .o2: return "8 rounds · Constant rest · Increasing hold"
            case .freestyle: return "Open timer · Save personal records"
            case .box: return "4-phase breathwork · Warmup & focus"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(TrainMode.allCases) { mode in
                            TrainModeCard(mode: mode) {
                                selectedMode = mode
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Train")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedMode) { mode in
                switch mode {
                case .co2:
                    TableSetupView(sessionType: .co2)
                case .o2:
                    TableSetupView(sessionType: .o2)
                case .freestyle:
                    FreestyleView()
                case .box:
                    BoxBreathingView()
                }
            }
            .onAppear {
                applyQuickLaunch()
            }
            .onChange(of: quickLaunchMode) { _, _ in
                applyQuickLaunch()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func applyQuickLaunch() {
        guard !quickLaunchMode.isEmpty else { return }
        let mode = TrainMode(rawValue: quickLaunchMode)
        quickLaunchMode = ""
        selectedMode = mode
    }
}

struct TrainModeCard: View {
    let mode: TrainView.TrainMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(mode.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: mode.icon)
                        .font(.title2)
                        .foregroundStyle(mode.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.rawValue)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(mode.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
