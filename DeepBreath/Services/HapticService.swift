import UIKit

struct HapticService {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func holdStart() {
        impact(.heavy)
    }

    static func restStart() {
        impact(.light)
    }

    static func sessionComplete() {
        notification(.success)
    }

    static func tick() {
        impact(.rigid)
    }
}
