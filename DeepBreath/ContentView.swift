import SwiftUI

struct ContentView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @AppStorage("hasPB") private var hasPB: Bool = false
    @AppStorage("personalBest") private var personalBest: Double = 60

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            TrainView()
                .tabItem {
                    Label("Train", systemImage: "lungs.fill")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.cyan)
        .fullScreenCover(isPresented: Binding(
            get: { !hasPB },
            set: { _ in }
        )) {
            PBLockView()
        }
        .onAppear {
            // Migrate existing users who already have a PB set
            if personalBest > 0 && !hasPB {
                hasPB = true
            }
        }
    }
}

struct PBLockView: View {
    @AppStorage("personalBest") private var personalBest: Double = 0
    @AppStorage("hasPB") private var hasPB: Bool = false

    @State private var pbMinutes: Int = 1
    @State private var pbSeconds: Int = 0
    @State private var showFreestyle = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 40)

                    VStack(spacing: 16) {
                        Image(systemName: "stopwatch.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.cyan)
                            .symbolEffect(.pulse)

                        VStack(spacing: 8) {
                            Text("Set Your Personal Best")
                                .font(.title.bold())
                                .foregroundStyle(.white)

                            Text("Your PB calibrates your training tables. Enter your best breath-hold time or do a quick live hold.")
                                .font(.body)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }

                    VStack(spacing: 12) {
                        Text("Enter manually")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)

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
                        .frame(height: 150)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button {
                            guard pbTotalSeconds > 0 else { return }
                            personalBest = Double(pbTotalSeconds)
                            hasPB = true
                        } label: {
                            Text("Confirm PB")
                                .font(.headline)
                                .foregroundStyle(pbTotalSeconds > 0 ? .black : .gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(pbTotalSeconds > 0 ? Color.cyan : Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .animation(.easeInOut(duration: 0.2), value: pbTotalSeconds > 0)
                        }
                        .disabled(pbTotalSeconds == 0)
                        .buttonStyle(PressButtonStyle(scale: 0.97))
                    }

                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .padding(.horizontal, 10)
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1)
                    }

                    Button {
                        showFreestyle = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "stopwatch.fill")
                                .font(.subheadline)
                            Text("Do a live breath hold")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.cyan)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PressButtonStyle(scale: 0.97))

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 28)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showFreestyle, onDismiss: {
            if personalBest > 0 {
                hasPB = true
            }
        }) {
            FreestyleView()
        }
    }

    private var pbTotalSeconds: Int {
        pbMinutes * 60 + pbSeconds
    }
}
