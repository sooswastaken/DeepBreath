import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("personalBest") private var personalBest: Double = 60
    @AppStorage("voiceEnabled") private var voiceEnabled = true
    @AppStorage("curriculumMode") private var curriculumMode = true
    @Query private var curriculumStates: [CurriculumState]
    @Environment(\.modelContext) private var modelContext
    @State private var pbMinutes: Int = 1
    @State private var pbSeconds: Int = 0
    @State private var showPicker = false
    @State private var notificationService = NotificationService()
    @State private var reminderDays: Set<Int> = []
    @State private var reminderHour = 8
    @State private var reminderMinute = 0
    @State private var remindersEnabled = false
    @State private var showSavedFeedback = false

    private var curriculumState: CurriculumState {
        if let s = curriculumStates.first { return s }
        let s = CurriculumState()
        modelContext.insert(s)
        try? modelContext.save()
        return s
    }

    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    curriculumSection
                    pbSection
                    audioSection
                    remindersSection
                    aboutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .overlay(alignment: .top) {
                savedBanner
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            pbMinutes = Int(personalBest) / 60
            pbSeconds = Int(personalBest) % 60
            loadSavedReminders()
        }
    }

    private var curriculumSection: some View {
        Section {
            Toggle("Let the App Decide", isOn: $curriculumMode)
                .foregroundStyle(.white)
                .tint(.cyan)
                .listRowBackground(Color.white.opacity(0.06))

            if curriculumMode {
                let state = curriculumState
                Picker("Training Frequency", selection: Binding(
                    get: { state.trainingFrequencyGoal },
                    set: { state.trainingFrequencyGoal = $0; try? modelContext.save() }
                )) {
                    Text("3x / week").tag(3)
                    Text("4x / week").tag(4)
                    Text("5x / week").tag(5)
                }
                .foregroundStyle(.white)
                .tint(.cyan)
                .listRowBackground(Color.white.opacity(0.06))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Rest Days")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { day in
                            let active = state.restDays.contains(day)
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    var days = state.restDays
                                    if active { days.removeAll { $0 == day } }
                                    else { days.append(day) }
                                    state.restDays = days
                                    try? modelContext.save()
                                }
                            } label: {
                                Text(weekdays[day - 1])
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(active ? .black : .gray)
                                    .frame(width: 36, height: 36)
                                    .background(active ? Color.orange : Color.white.opacity(0.1))
                                    .clipShape(Circle())
                                    .scaleEffect(active ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: active)
                            }
                            .buttonStyle(PressButtonStyle(scale: 0.88))
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.06))
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        } header: {
            Text("Curriculum")
                .foregroundStyle(.gray)
        } footer: {
            Text(curriculumMode
                ? "The app picks each session based on your history and progression."
                : "Manual mode: you choose the session type from the Train tab.")
                .foregroundStyle(.gray.opacity(0.7))
        }
    }

    private var pbSection: some View {
        Section {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showPicker.toggle()
                }
            } label: {
                HStack {
                    Text("Personal Best")
                        .foregroundStyle(.white)
                    Spacer()
                    Text(personalBest.mmss)
                        .font(.headline.monospaced())
                        .foregroundStyle(.cyan)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: personalBest)
                    Image(systemName: showPicker ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.gray)
                        .rotationEffect(.degrees(showPicker ? 0 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showPicker)
                }
            }
            .buttonStyle(PressButtonStyle(scale: 0.98))
            .listRowBackground(Color.white.opacity(0.06))

            if showPicker {
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
                .listRowBackground(Color.white.opacity(0.06))
                .onChange(of: pbMinutes) { _, _ in savePBFromPicker() }
                .onChange(of: pbSeconds) { _, _ in savePBFromPicker() }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        } header: {
            Text("Personal Best")
                .foregroundStyle(.gray)
        } footer: {
            Text("Used to auto-calculate table holds and rest intervals.")
                .foregroundStyle(.gray.opacity(0.7))
        }
    }

    private var audioSection: some View {
        Section {
            Toggle("Voice Guidance", isOn: $voiceEnabled)
                .foregroundStyle(.white)
                .tint(.cyan)
                .listRowBackground(Color.white.opacity(0.06))
        } header: {
            Text("Audio")
                .foregroundStyle(.gray)
        } footer: {
            Text("Spoken cues during training sessions.")
                .foregroundStyle(.gray.opacity(0.7))
        }
    }

    private var remindersSection: some View {
        Section {
            Toggle("Enable Daily Reminders", isOn: $remindersEnabled)
                .foregroundStyle(.white)
                .tint(.cyan)
                .onChange(of: remindersEnabled) { _, enabled in
                    if enabled {
                        Task {
                            await notificationService.requestAuthorization()
                            scheduleReminders()
                        }
                    } else {
                        notificationService.cancelAllReminders()
                    }
                }
                .listRowBackground(Color.white.opacity(0.06))

            if remindersEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Days")
                        .font(.subheadline)
                        .foregroundStyle(.gray)

                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { day in
                            let label = weekdays[day - 1]
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    if reminderDays.contains(day) {
                                        reminderDays.remove(day)
                                    } else {
                                        reminderDays.insert(day)
                                    }
                                    scheduleReminders()
                                }
                            } label: {
                                Text(label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(reminderDays.contains(day) ? .black : .gray)
                                    .frame(width: 36, height: 36)
                                    .background(reminderDays.contains(day) ? Color.cyan : Color.white.opacity(0.1))
                                    .clipShape(Circle())
                                    .scaleEffect(reminderDays.contains(day) ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: reminderDays.contains(day))
                            }
                            .buttonStyle(PressButtonStyle(scale: 0.88))
                        }
                    }

                    DatePicker(
                        "Time",
                        selection: reminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .colorScheme(.dark)
                    .onChange(of: reminderHour) { _, _ in scheduleReminders() }
                    .onChange(of: reminderMinute) { _, _ in scheduleReminders() }
                }
                .listRowBackground(Color.white.opacity(0.06))
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        } header: {
            Text("Reminders")
                .foregroundStyle(.gray)
        } footer: {
            Text("Daily motivational reminders to keep your training consistent.")
                .foregroundStyle(.gray.opacity(0.7))
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(.white)
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.gray)
            }
            .listRowBackground(Color.white.opacity(0.06))

            NavigationLink {
                SafetyView()
            } label: {
                Label("Safety Information", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .listRowBackground(Color.white.opacity(0.06))
        } header: {
            Text("About")
                .foregroundStyle(.gray)
        }
    }

    @ViewBuilder
    private var savedBanner: some View {
        if showSavedFeedback {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Personal best saved!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.2))
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .padding(.top, 8)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showSavedFeedback)
        }
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding<Date>(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderHour = components.hour ?? 8
                reminderMinute = components.minute ?? 0
            }
        )
    }

    private func savePBFromPicker() {
        let seconds = Double(pbMinutes * 60 + pbSeconds)
        guard seconds > 0 else { return }
        personalBest = seconds
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            showSavedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showSavedFeedback = false
            }
        }
    }

    private func scheduleReminders() {
        guard remindersEnabled, !reminderDays.isEmpty else { return }
        notificationService.scheduleReminders(days: reminderDays, hour: reminderHour, minute: reminderMinute)
    }

    private func loadSavedReminders() {
        let defaults = UserDefaults.standard
        remindersEnabled = defaults.bool(forKey: "remindersEnabled")
        reminderHour = defaults.integer(forKey: "reminderHour").nonZero ?? 8
        reminderMinute = defaults.integer(forKey: "reminderMinute")
        if let days = defaults.array(forKey: "reminderDays") as? [Int] {
            reminderDays = Set(days)
        }
    }
}

extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}

struct SafetyView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.orange)
                        .symbolEffect(.pulse)
                        .padding(.top, 32)
                        .staggeredAppear(delay: 0.05, yOffset: -10)

                    Text("Safety Information")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .staggeredAppear(delay: 0.12)

                    VStack(spacing: 16) {
                        safetyPoint("Never train breath holds alone", detail: "Always have a trained safety partner present during any water breath-hold activities.")
                        safetyPoint("Dry land training only", detail: "This app is designed for dry land training only. Never use in water without professional supervision.")
                        safetyPoint("Know the risks", detail: "Shallow water blackout can occur without warning. It is a leading cause of drowning in breath-hold divers.")
                        safetyPoint("Stop if you feel dizzy", detail: "Any lightheadedness, tingling, or visual disturbances are signals to stop immediately and breathe normally.")
                        safetyPoint("Consult your doctor", detail: "If you have cardiovascular, pulmonary, or other health conditions, consult a physician before breath-hold training.")
                    }
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Safety")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private func safetyPoint(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "exclamationmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.orange)
            Text(detail)
                .font(.body)
                .foregroundStyle(.gray)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.12), lineWidth: 1)
        )
    }
}
