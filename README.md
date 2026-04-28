# DeepBreath

A freediving and apnea training app for iOS. Built around the training methods that actually work: CO2 tables, O2 tables, freestyle holds, and box breathing, with progress tracking that stays out of your way.

---

## What it does

**CO2 Tables:** Fixed hold time with progressively shorter rest periods. Trains your body to tolerate carbon dioxide buildup, which is the primary limiter for most divers.

**O2 Tables:** Fixed rest with progressively longer hold times. Builds oxygen efficiency and extends your maximum breath-hold duration.

**Freestyle:** Open-ended breath holds with a running timer. Each hold is logged automatically and personal bests are tracked.

**Box Breathing:** Structured 4-phase breathing cycles for pre-dive relaxation and nervous system regulation.

All sessions are calibrated to your personal best. Pick a difficulty level and the app generates a table that scales to where you actually are, not a generic template.

---

## Installing via AltStore

DeepBreath is distributed as a sideloadable IPA through AltStore. You do not need a developer account.

**Prerequisites:** [AltStore](https://altstore.io) installed on your device and paired with AltServer on your Mac or PC.

**Steps:**

1. Open AltStore on your iPhone or iPad.
2. Go to **Sources** and tap the **+** button in the top-left corner.
3. Enter the source URL:
   ```
   https://raw.githubusercontent.com/sooswastaken/DeepBreath/main/apps.json
   ```
4. Once the source is added, find DeepBreath in the Sources tab and tap **Free** to install.
5. AltStore will refresh your app automatically as long as AltServer is running. Apps expire after 7 days on free accounts, so keep AltServer accessible.

The source manifest is `apps.json` at the root of this repo. It is updated automatically on each release.

---

## Stack

- Swift / SwiftUI
- SwiftData (iOS 17+)
- No third-party dependencies

**Minimum deployment:** iOS 17.0  
**Supports:** iPhone and iPad

---

## Building

Clone the repo and open in Xcode, or build from the command line:

```bash
xcodebuild -project DeepBreath.xcodeproj \
  -scheme DeepBreath \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

If you add or remove Swift source files, regenerate the Xcode project before building:

```bash
python3 generate_xcodeproj.py
```

The script owns `project.pbxproj` -- do not hand-edit that file.

---

## Project structure

```
DeepBreath/
  DeepBreathApp.swift          app entry point, SwiftData container
  ContentView.swift            root tab view
  Models/                      SwiftData models (TrainingSession, FreestyleHold)
  ViewModels/                  session state and business logic
  Views/
    Home/                      dashboard
    Train/                     session setup and active training views
    History/                   session log and progress charts
    Settings/                  user preferences and personal best
    Onboarding/                first-launch flow
  Services/                    audio, haptics, notifications
  Utilities/                   table generation algorithms, time formatting
```

---

## License

MIT
