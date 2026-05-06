import Foundation
import UIKit
import UserNotifications

@MainActor
final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    static let shared = AppNotificationDelegate()

    private override init() {
        super.init()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        let sharedDefaults = UserDefaults(suiteName: "group.com.musamasalla.SoberSend")

        // Haptic feedback on user interaction
        let haptic = UINotificationFeedbackGenerator()
        await haptic.notificationOccurred(.success)

        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier, "TAKE_CHALLENGE":
            if let action = userInfo["action"] as? String {
                switch action {
                case "app_unlock_challenge":
                    sharedDefaults?.set(true, forKey: "isRequestingAppUnlock")
                    sharedDefaults?.set(true, forKey: "notificationDeepLink")
                case "app_unlock_emergency":
                    sharedDefaults?.set(true, forKey: "isRequestingEmergencyUnlock")
                    sharedDefaults?.set(true, forKey: "notificationDeepLink")
                case "lockout_expired":
                    sharedDefaults?.set(true, forKey: "lockoutExpiredDeepLink")
                    sharedDefaults?.set(true, forKey: "notificationDeepLink")
                case "morning_report":
                    sharedDefaults?.set(true, forKey: "morningReportDeepLink")
                    sharedDefaults?.set(true, forKey: "notificationDeepLink")
                default:
                    break
                }
            }
        case "DISMISS":
            break
        default:
            break
        }
    }
}
