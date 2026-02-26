import Foundation
import UserNotifications

@MainActor
@Observable
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    var isAuthorized: Bool = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorization()
    }
    
    // MARK: - Authorization
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            print("Error requesting notification authorization: \(error)")
        }
    }
    
    private func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Morning Report
    func scheduleMorningReport(at hour: Int = 8, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Last night's report 🛡️"
        content.body = "Tap to see who you tried to text last night."
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "morning_report", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Error scheduling morning report: \(error)") }
        }
    }
    
    func cancelMorningReport() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["morning_report"])
    }
    
    // MARK: - App Unlock Notification (called from ShieldActionExtension via shared defaults)
    /// Sends an urgent notification that deep-links the user straight into the challenge screen.
    /// The ShieldAction extension cannot call this directly (no UNUserNotificationCenter in extensions without entitlement),
    /// so instead it sets a flag in shared defaults and the main app sends the notification when it wakes.
    func sendAppUnlockNotification() {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🔒 App Locked"
        content.body = "Want in? Prove you're sober first. Tap to take the challenge."
        content.sound = .defaultCritical
        content.userInfo = ["action": "app_unlock_challenge"]
        // Deep link URL scheme: sobersend://challenge
        content.categoryIdentifier = "APP_UNLOCK"
        
        // Remove any pending unlock notifications first (avoid spam)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["app_unlock"])
        
        // Fire immediately (1 second delay to ensure app is backgrounded)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "app_unlock", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Error scheduling unlock notification: \(error)") }
        }
    }
    
    func registerNotificationCategories() {
        let challengeAction = UNNotificationAction(
            identifier: "TAKE_CHALLENGE",
            title: "Take Challenge",
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        let unlockCategory = UNNotificationCategory(
            identifier: "APP_UNLOCK",
            actions: [challengeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([unlockCategory])
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if userInfo["action"] as? String == "app_unlock_challenge" {
            // Set the flag so ContentView shows the challenge
            let shared = UserDefaults(suiteName: "group.com.musamasalla.SoberSend")
            shared?.set(true, forKey: "isRequestingAppUnlock")
        }
    }
}
