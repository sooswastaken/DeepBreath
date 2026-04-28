import SwiftUI

struct SettingsView: View {
    @AppStorage("personalBest") private var personalBest: Double = 60
    @AppStorage("voiceEnabled") private var voiceEnabled = true
    @State private var pbText = ""
    @State private var notificationService = NotificationService()
    @State private var reminderDays: Set<Int> = []
    @State private var reminderHour = 8
    @State private var reminderMinute = 0
    @State private var remindersEnabled = false
    @State private var showSavedFeedback = false
    @FocusState private var pbFieldFocused: Bool

    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        pbFieldFocused = false
                    }
                    .foregroundStyle(.cyan)
                }
            }
            .overlay(
                savedBanner
                    .animation(.easeInOut, value: showSavedFeedback),
                alignment: .top
            )
        }
        .preferredColorScheme(.dark)
        .onAppear {
            pbText = "\(Int(personalBest))"
            loadSavedReminders()
        }
        .task {
            await notificationService.requestAuthorization()
        }
    }

    private var pbSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current PB:")
                        .foregroundStyle(.gray)
                    Text(personalBest.mmss)
                        .font(.headline.monospaced())
                        .foregroundStyle(.cyan)
                }

                HStack {
                    TextField("Seconds (e.g. 90)", text: $pbText)
                        .keyboardType(.numberPad)
                        .foregroundStyle(.white)
                        .focused($pbFieldFocused)
                        .onSubmit { savePB() }

                    Button("Save") {
                        savePB()
                        pbFieldFocused = false
                    }
                    .foregroundStyle(.cyan)
                    .buttonStyle(.plain)
                }
            }
            .listRowBackground(Color.white.opacity(0.06))
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
                        scheduleReminders()
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
                                if reminderDays.contains(day) {
                                    reminderDays.remove(day)
                                } else {
                                    reminderDays.insert(day)
                                }
                                scheduleReminders()
                            } label: {
                                Text(label)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(reminderDays.contains(day) ? .black : .gray)
                                    .frame(width: 36, height: 36)
                                    .background(reminderDays.contains(day) ? Color.cyan : Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
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

    private var savedBanner: some View {
        Group {
            if showSavedFeedback {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Personal best saved!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.2))
                .clipShape(Capsule())
                .padding(.top, 8)
            }
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

    private func savePB() {
        guard let pb = Double(pbText), pb > 0 else { return }
        personalBest = pb
        showSavedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSavedFeedback = false
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
                        .padding(.top, 32)

                    Text("Safety Information")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 16) {
                        safetyPoint("Never train breath holds alone", detail: "Always have a trained safety partner present during any water breath-hold activities.")
                        safetyPoint("Dry land training only", detail: "This app is designed for dry land training only. Never use in water without professional supervision.")
                        safetyPoint("Know the risks", detail: "Shallow water blackout can occur without warning. It is a leading cause of drowning in breath-hold divers.")
                        safetyPoint("Stop if you feel dizzy", detail: "Any lightheadedness, tingling, or visual disturbances are signals to stop immediately and breathe normally.")
                        safetyPoint("Consult your doctor", detail: "If you have cardiovascular, pulmonary, or other health conditions, consult a physician before breath-hold training.")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
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
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
