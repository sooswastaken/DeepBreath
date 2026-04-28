import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("personalBest") private var personalBest: Double = 60
    @AppStorage("hasPB") private var hasPB: Bool = false
    @State private var acknowledged = false
    @State private var pbMinutes: Int = 1
    @State private var pbSeconds: Int = 0
    @State private var page = 0
    @State private var notificationService = NotificationService()
    @State private var notificationsRequested = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Subtle ambient glow shifts per page
            pageAccentColor
                .opacity(0.05)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: page)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    safetyPage.tag(1)
                    pbSetupPage.tag(2)
                    notificationsPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Dot indicators
                HStack(spacing: 8) {
                    ForEach(0..<4) { i in
                        Capsule()
                            .fill(i == page ? pageAccentColor : Color.gray.opacity(0.35))
                            .frame(width: i == page ? 20 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.vertical, 16)

                // Action button
                Group {
                    if page == 3 {
                        VStack(spacing: 10) {
                            Button {
                                guard canStartTraining else { return }
                                personalBest = Double(pbTotalSeconds)
                                hasPB = true
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    hasSeenOnboarding = true
                                }
                            } label: {
                                Text("Start Training")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(canStartTraining ? pageAccentColor : Color.gray.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .animation(.easeInOut(duration: 0.25), value: canStartTraining)
                            }
                            .disabled(!canStartTraining)
                            .buttonStyle(PressButtonStyle(scale: 0.97))

                            Button {
                                personalBest = 0
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    hasSeenOnboarding = true
                                }
                            } label: {
                                Text("I don't have one yet — set it later")
                                    .font(.subheadline)
                                    .foregroundStyle(acknowledged ? Color.gray : Color.gray.opacity(0.35))
                            }
                            .disabled(!acknowledged)
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                page += 1
                            }
                        } label: {
                            HStack {
                                Text("Continue")
                                    .font(.headline)
                                Image(systemName: "arrow.right")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(canContinueFromCurrentPage ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canContinueFromCurrentPage ? pageAccentColor : Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .animation(.easeInOut(duration: 0.25), value: canContinueFromCurrentPage)
                        }
                        .disabled(!canContinueFromCurrentPage)
                        .buttonStyle(PressButtonStyle(scale: 0.97))
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.8), value: page == 3)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            pbMinutes = Int(personalBest) / 60
            pbSeconds = Int(personalBest) % 60
        }
        .onChange(of: page) { _, newPage in
            if newPage > 1 && !acknowledged {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    page = 1
                }
            }
        }
    }

    private var pageAccentColor: Color {
        switch page {
        case 0: return .cyan
        case 1: return .orange
        case 2: return .cyan
        case 3: return .cyan
        default: return .cyan
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lungs.fill")
                .font(.system(size: 80))
                .foregroundStyle(.cyan)
                .symbolEffect(.pulse)
                .staggeredAppear(delay: 0.15, yOffset: -12)

            VStack(spacing: 8) {
                Text("DeepBreath")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .staggeredAppear(delay: 0.25)

                Text("Train your breath hold.\nPush your limits.\nDive deeper.")
                    .font(.title3)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .staggeredAppear(delay: 0.35)
            }

            Spacer()
        }
        .padding(32)
    }

    private var safetyPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
                .symbolEffect(.pulse)
                .staggeredAppear(delay: 0.1, yOffset: -10)

            Text("Safety First")
                .font(.title.bold())
                .foregroundStyle(.white)
                .staggeredAppear(delay: 0.18)

            Text("Never train breath holds alone or in water without a buddy present.\n\nThis app is for **dry land training only**.\n\nAlways ensure you have a trained safety diver or buddy present when training in water.")
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
                .staggeredAppear(delay: 0.26)

            Toggle(isOn: $acknowledged) {
                Text("I understand and acknowledge the safety requirements")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .tint(.orange)
            .padding()
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(acknowledged ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1)
                    .animation(.easeInOut(duration: 0.2), value: acknowledged)
            )
            .staggeredAppear(delay: 0.34)

            Spacer()
        }
        .padding(32)
    }

    private var pbSetupPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "stopwatch.fill")
                .font(.system(size: 60))
                .foregroundStyle(.cyan)
                .symbolEffect(.pulse)
                .staggeredAppear(delay: 0.1, yOffset: -10)

            Text("Your Personal Best")
                .font(.title.bold())
                .foregroundStyle(.white)
                .staggeredAppear(delay: 0.18)

            Text("Enter your current best breath-hold time. This calibrates your training tables.")
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .staggeredAppear(delay: 0.26)

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
            .staggeredAppear(delay: 0.34)

            Spacer()
        }
        .padding(32)
    }

    private var notificationsPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 60))
                .foregroundStyle(.cyan)
                .symbolEffect(.pulse)
                .staggeredAppear(delay: 0.1, yOffset: -10)

            Text("Stay Consistent")
                .font(.title.bold())
                .foregroundStyle(.white)
                .staggeredAppear(delay: 0.18)

            Text("Daily reminders help you build a training habit and push your breath-hold further.")
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
                .staggeredAppear(delay: 0.26)

            Button {
                Task {
                    await notificationService.requestAuthorization()
                    notificationsRequested = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: notificationService.isAuthorized ? "checkmark.circle.fill" : "bell.fill")
                        .foregroundStyle(notificationService.isAuthorized ? .green : .black)
                    Text(notificationService.isAuthorized ? "Notifications Enabled" : "Enable Daily Reminders")
                        .font(.headline)
                        .foregroundStyle(notificationService.isAuthorized ? .green : .black)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(notificationService.isAuthorized ? Color.green.opacity(0.15) : Color.cyan)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(notificationService.isAuthorized ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.25), value: notificationService.isAuthorized)
            }
            .buttonStyle(PressButtonStyle(scale: 0.97))
            .disabled(notificationService.isAuthorized)
            .staggeredAppear(delay: 0.34)

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
