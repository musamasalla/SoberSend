import Foundation
import UserNotifications

@MainActor
@Observable
class NotificationManager: NSObject {
    var isAuthorized: Bool = false

    override init() {
        super.init()
        checkAuthorization()
    }

    // MARK: - Authorization
    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert])
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

    // MARK: - Notification Categories
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

        let emergencyAction = UNNotificationAction(
            identifier: "VIEW_EMERGENCY",
            title: "View Options",
            options: [.foreground]
        )
        let emergencyCategory = UNNotificationCategory(
            identifier: "EMERGENCY_UNLOCK",
            actions: [emergencyAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let lockoutExpiredCategory = UNNotificationCategory(
            identifier: "LOCKOUT_EXPIRED",
            actions: [challengeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            unlockCategory,
            emergencyCategory,
            lockoutExpiredCategory
        ])
    }

    static func registerCategoriesOnce() {
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

        let emergencyAction = UNNotificationAction(
            identifier: "VIEW_EMERGENCY",
            title: "View Options",
            options: [.foreground]
        )
        let emergencyCategory = UNNotificationCategory(
            identifier: "EMERGENCY_UNLOCK",
            actions: [emergencyAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let lockoutExpiredCategory = UNNotificationCategory(
            identifier: "LOCKOUT_EXPIRED",
            actions: [challengeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            unlockCategory,
            emergencyCategory,
            lockoutExpiredCategory
        ])
    }

    // MARK: - Morning Report
    func scheduleMorningReport(at hour: Int = 8, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Your morning is clear"
        content.body = "No late-night messages last night. You're in control."
        content.sound = .default
        content.categoryIdentifier = "MORNING_REPORT"

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

    // MARK: - Lock Window Reminders
    func scheduleLockStartReminder(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Lockdown starting soon"
        content.body = "Your apps will be restricted in 15 minutes. Finish up and save your work."
        content.sound = .default
        content.categoryIdentifier = "LOCK_START"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = max(0, minute - 15)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "lock_start_reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Error scheduling lock start reminder: \(error)") }
        }
    }

    func scheduleLockEndReminder(at hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Good morning!"
        content.body = "Your lockdown has ended. Stay strong today."
        content.sound = .default
        content.categoryIdentifier = "LOCK_END"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "lock_end_reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Error scheduling lock end reminder: \(error)") }
        }
    }

    func cancelLockReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["lock_start_reminder", "lock_end_reminder"]
        )
    }

    // MARK: - Streak Celebration
    func sendStreakNotification(streakNights: Int) {
        let content = UNMutableNotificationContent()
        let messages = [
            "You're on a \(streakNights)-night streak! Keep it up.",
            "\(streakNights) nights strong. You got this.",
            "Big milestone: \(streakNights) consecutive nights."
        ]
        content.title = "Streak Celebration"
        content.body = messages[streakNights % messages.count]
        content.sound = .default
        content.categoryIdentifier = "STREAK"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "streak_\(streakNights)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Error scheduling streak notification: \(error)") }
        }
    }

    // MARK: - App Unlock Notification
    func sendAppUnlockNotification() {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "App Locked"
        content.body = "Want in? Prove you're sober first. Tap to take the challenge."
        content.sound = .defaultCritical
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["action": "app_unlock_challenge"]
        content.categoryIdentifier = "APP_UNLOCK"

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["app_unlock"])

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "app_unlock", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Error scheduling unlock notification: \(error)") }
        }
    }

    func sendEmergencyUnlockNotification() {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Emergency Override Available"
        content.body = "You can request an emergency unlock, no challenge required."
        content.sound = .defaultCritical
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["action": "app_unlock_emergency"]
        content.categoryIdentifier = "EMERGENCY_UNLOCK"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "emergency_unlock", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Error scheduling emergency notification: \(error)") }
        }
    }

    func sendLockoutExpiredNotification() {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Lockout Over"
        content.body = "Your lockout period has ended. Want to try the challenge again?"
        content.sound = .default
        content.userInfo = ["action": "lockout_expired"]
        content.categoryIdentifier = "LOCKOUT_EXPIRED"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "lockout_expired", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
        if let error { print("Error scheduling lockout expired notification: \(error)") }
    }
}

    // MARK: - UNUserNotificationCenterDelegate
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

        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            if let action = userInfo["action"] as? String {
                await handleDeepLinkAction(action, userInfo: userInfo)
            }
        case "TAKE_CHALLENGE":
            await handleDeepLinkAction("app_unlock_challenge", userInfo: userInfo)
        case "VIEW_EMERGENCY":
            await handleDeepLinkAction("app_unlock_emergency", userInfo: userInfo)
        default:
            break
        }
    }

    private nonisolated func handleDeepLinkAction(_ action: String, userInfo: [AnyHashable: Any]) async {
        let shared = UserDefaults(suiteName: "group.com.musamasalla.SoberSend")
        switch action {
        case "app_unlock_challenge":
            shared?.set(true, forKey: "isRequestingAppUnlock")
            shared?.set(true, forKey: "notificationDeepLink")
        case "app_unlock_emergency":
            shared?.set(true, forKey: "isRequestingEmergencyUnlock")
            shared?.set(true, forKey: "notificationDeepLink")
        case "lockout_expired":
            shared?.set(true, forKey: "lockoutExpiredDeepLink")
            shared?.set(true, forKey: "notificationDeepLink")
        default:
            break
        }
    }
}