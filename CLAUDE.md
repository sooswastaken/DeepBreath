# DeepBreath — Agent Guide

## Anti-Exploration Rule
Do not use the explore tool to blindly search the codebase. Rely on the WHAT/WHY/HOW map below and use targeted file reads.

---

## WHY — Purpose
DeepBreath is a native iOS app for freediving/apnea training. It guides users through CO2 tables, O2 tables, freestyle breath-holds, and box breathing sessions, with SwiftData-backed progress tracking.

---

## WHAT — Tech Stack & Map

| Layer | Technology |
|---|---|
| Language | Swift 5.0 |
| UI | SwiftUI |
| Persistence | SwiftData (iOS 17+) |
| Min deployment | iOS 17.0 (iPhone + iPad) |
| Bundle ID | com.deepbreath.app |

### Source layout (`DeepBreath/`)
```
DeepBreathApp.swift          — @main entry, SwiftData ModelContainer setup
ContentView.swift            — TabView: Home / Train / History / Settings
Models/TrainingSession.swift — SwiftData models: TrainingSession, FreestyleHold
ViewModels/                  — BoxBreathingViewModel, FreestyleViewModel, SessionViewModel
Views/
  Home/                      — HomeView
  Train/                     — TrainView, ActiveSessionView, TableSetupView,
                               BoxBreathingView, FreestyleView
  History/                   — HistoryView, ProgressChartsView
  Settings/                  — SettingsView
  Onboarding/                — OnboardingView
Services/                    — AudioService, HapticService, NotificationService
Utilities/TableCalculator.swift — CO2/O2 table algorithms; TimeInterval formatting
```

---

## HOW — Essential Commands

**Build (simulator):**
```bash
xcodebuild -project DeepBreath.xcodeproj \
  -scheme DeepBreath \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

**Regenerate Xcode project** (required after adding or removing Swift files):
```bash
python3 generate_xcodeproj.py
```

No automated test suite exists yet.

---

## Key Invariants
- `generate_xcodeproj.py` owns `DeepBreath.xcodeproj/project.pbxproj` — do not hand-edit that file; re-run the script instead.
- All persistent models must be registered in the `Schema` inside `DeepBreathApp.swift`.
- Session types are the `SessionType` enum (`co2`, `o2`, `freestyle`, `boxBreathing`); difficulty is `DifficultyLevel` (`easy`, `normal`, `hard`).
