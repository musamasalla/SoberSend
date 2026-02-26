import ManagedSettings
import UIKit
import UserNotifications

extension ManagedSettingsStore.Name {
    static let soberSend = ManagedSettingsStore.Name("com.musamasalla.SoberSend.lockdown")
}

class ShieldActionExtension: ShieldActionDelegate {
    
    private let store = ManagedSettingsStore(named: .soberSend)

    private func handleUnlockRequest(isEmergency: Bool) -> ShieldActionResponse {
        let sharedDefaults = UserDefaults(suiteName: "group.com.musamasalla.SoberSend")
        
        // Signal to the main app that an unlock or emergency was requested
        let key = isEmergency ? "isRequestingEmergencyUnlock" : "isRequestingAppUnlock"
        sharedDefaults?.set(true, forKey: key)
        sharedDefaults?.synchronize()
        
        // Send a local notification
        let content = UNMutableNotificationContent()
        content.title = isEmergency ? "🚨 Emergency Unlock" : "🔒 App Locked"
        content.body = isEmergency ? "Tap to access your emergency bypass." : "Want in? Prove you're sober first. Tap to take the challenge."
        content.sound = isEmergency ? .defaultCritical : .default
        content.userInfo = ["action": isEmergency ? "emergency_unlock" : "app_unlock_challenge"]
        content.categoryIdentifier = "APP_UNLOCK"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let identifier = isEmergency ? "emergency_request" : "shield_unlock"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        return .defer
    }

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(handleUnlockRequest(isEmergency: false))
        case .secondaryButtonPressed:
            completionHandler(handleUnlockRequest(isEmergency: true))
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(handleUnlockRequest(isEmergency: false))
        case .secondaryButtonPressed:
            completionHandler(handleUnlockRequest(isEmergency: true))
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(handleUnlockRequest(isEmergency: false))
        case .secondaryButtonPressed:
            completionHandler(handleUnlockRequest(isEmergency: true))
        @unknown default:
            completionHandler(.close)
        }
    }
}
