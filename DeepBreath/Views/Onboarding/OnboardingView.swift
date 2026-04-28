import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("personalBest") private var personalBest: Double = 60
    @State private var acknowledged = false
    @State private var pbMinutes: Int = 1
    @State private var pbSeconds: Int = 0
    @State private var page = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
                        guard canStartTraining else { return }
                        personalBest = Double(pbTotalSeconds)
                        hasSeenOnboarding = true
                    } label: {
                        Text("Start Training")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canStartTraining ? Color.cyan : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canStartTraining)
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
                            .background(canContinueFromCurrentPage ? Color.cyan : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canContinueFromCurrentPage)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            pbMinutes = Int(personalBest) / 60
            pbSeconds = Int(personalBest) % 60
        }
        .onChange(of: page) { _, newPage in
            if newPage > 1 && !acknowledged {
                withAnimation {
                    page = 1
                }
            }
        }
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

            HStack(spacing: 0) {
                Picker("Minutes", selection: $pbMinutes) {
                    ForEach(0...9, id: \.self) { m in
                        Text("\(m) min").tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("Seconds", selection: $pbSeconds) {
                    ForEach(0...59, id: \.self) { s in
                        Text(String(format: "%02d sec", s)).tag(s)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 170)

            Text("≈ \(pbMinutes)m \(String(format: "%02d", pbSeconds))s")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Spacer()
        }
        .padding(32)
    }

    private var canContinueFromCurrentPage: Bool {
        page != 1 || acknowledged
    }

    private var pbTotalSeconds: Int {
        pbMinutes * 60 + pbSeconds
    }

    private var canStartTraining: Bool {
        acknowledged && pbTotalSeconds > 0
    }
}
