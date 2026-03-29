import AudioToolbox
import UIKit

enum FeedbackManager {
    static func playSelection() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        AudioServicesPlaySystemSound(1104)
    }

    static func playSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1025)
    }

    static func playError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        AudioServicesPlaySystemSound(1521)
    }
}
