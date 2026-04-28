import SwiftUI
import SwiftData
import UserNotifications

@main
struct DeepBreathApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TrainingSession.self,
            FreestyleHold.self,
            CurriculumState.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .modelContainer(sharedModelContainer)
            } else {
                OnboardingView()
                    .modelContainer(sharedModelContainer)
            }
        }
    }
}
