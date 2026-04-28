import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("personalBest") private var personalBest: Double = 60
    @State private var acknowledged = false
    @State private var pbText = "60"
    @State private var page = 0
    @FocusState private var pbFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture { pbFieldFocused = false }

            VStack {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    safetyPage.tag(1)
                    pbSetupPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == page ? Color.cyan : Color.gray.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 8)

                if page == 2 {
                    Button {
                        guard acknowledged else { return }
                        if let pb = Double(pbText), pb > 0 {
                            personalBest = pb
                        }
                        hasSeenOnboarding = true
                    } label: {
                        Text("Start Training")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(acknowledged ? Color.cyan : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!acknowledged)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                } else {
                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        Text("Continue")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lungs.fill")
                .font(.system(size: 80))
                .foregroundStyle(.cyan)
                .symbolEffect(.pulse)

            Text("DeepBreath")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Train your breath hold.\nPush your limits.\nDive deeper.")
                .font(.title3)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            Spacer()
        }
        .padding(32)
    }

    private var safetyPage: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Safety First")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Never train breath holds alone or in water without a buddy present.\n\nThis app is for **dry land training only**.\n\nAlways ensure you have a trained safety diver or buddy present when training in water.")
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)

            Toggle(isOn: $acknowledged) {
                Text("I understand and acknowledge the safety requirements")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .tint(.cyan)
            .padding()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
        .padding(32)
    }

    private var pbSetupPage: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 60))
                .foregroundStyle(.cyan)

            Text("Your Personal Best")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Enter your current best breath-hold time in seconds. This calibrates your training tables.")
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            HStack {
                TextField("Seconds", text: $pbText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.cyan)
                    .frame(width: 140)
                    .focused($pbFieldFocused)

                Text("sec")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }

            if let pb = Double(pbText), pb > 0 {
                Text("≈ \(Int(pb) / 60)m \(Int(pb) % 60)s")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
        .padding(32)
    }
}
