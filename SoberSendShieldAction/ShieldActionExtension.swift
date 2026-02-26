import ManagedSettings
import UIKit
import UserNotifications

class ShieldActionExtension: ShieldActionDelegate {

    private func handleUnlockRequest() -> ShieldActionResponse {
        let sharedDefaults = UserDefaults(suiteName: "group.com.musamasalla.SoberSend")
        
        // Signal to the main app that an unlock was requested
        sharedDefaults?.set(true, forKey: "isRequestingAppUnlock")
        
        // Send a local notification — this wakes the user into SoberSend with a tap
        // Note: ShieldAction extensions ARE allowed to schedule local notifications
        let content = UNMutableNotificationContent()
        content.title = "🔒 App Locked"
        content.body = "Want in? Prove you're sober first. Tap to take the challenge."
        content.sound = .defaultCritical
        content.userInfo = ["action": "app_unlock_challenge"]
        content.categoryIdentifier = "APP_UNLOCK"
        
        // Remove previous pending unlock notification to avoid spam
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["shield_unlock"])
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(identifier: "shield_unlock", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        // .defer closes the shield momentarily — user taps the notification → SoberSend opens → challenge appears
        return .defer
    }

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(handleUnlockRequest())
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(handleUnlockRequest())
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(handleUnlockRequest())
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }
}
