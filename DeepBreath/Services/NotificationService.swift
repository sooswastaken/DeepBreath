import UserNotifications
import Foundation

@Observable
final class NotificationService {
    var isAuthorized = false

    private let motivationalMessages = [
        "Time to train — your lungs are waiting.",
        "Every hold makes you stronger. Let's go!",
        "Your personal best won't break itself.",
        "Breathe deep. Push further. Train now.",
        "Champions train daily. Today is your day.",
        "One session closer to your goal. Train now."
    ]

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { isAuthorized = granted }
        } catch {
            await MainActor.run { isAuthorized = false }
        }
    }

    func scheduleReminders(days: Set<Int>, hour: Int, minute: Int) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        for weekday in days {
            var components = DateComponents()
            components.weekday = weekday
            components.hour = hour
            components.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = "DeepBreath"
            content.body = motivationalMessages.randomElement() ?? motivationalMessages[0]
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "reminder-\(weekday)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
