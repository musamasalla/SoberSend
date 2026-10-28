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

    // MARK: - Lockdown Active Notification (Proactive)
    /// Sends an immediate notification that lockdown is active, showing contact reminder count.
    func sendLockdownActiveNotification(contactCount: Int) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🔒 Lockdown Active"
        
        if contactCount > 0 {
            let contactText = contactCount == 1 ? "1 contact reminder" : "\(contactCount) contact reminders"
            content.body = "Your lockdown is now protecting you. You have \(contactText) set. Open SoberSend to see them."
        } else {
            content.body = "Your lockdown is now active. Your selected apps are restricted until the lockdown ends."
        }
        
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["action": "lockdown_active"]
        content.categoryIdentifier = "LOCKDOWN_ACTIVE"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "lockdown_active", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Error scheduling lockdown active notification: \(error)") }
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

        let lockdownActiveAction = UNNotificationAction(
            identifier: "VIEW_CONTACT_REMINDERS",
            title: "View Contact Reminders",
            options: [.foreground]
        )
        let lockdownActiveCategory = UNNotificationCategory(
            identifier: "LOCKDOWN_ACTIVE",
            actions: [lockdownActiveAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            unlockCategory,
            emergencyCategory,
            lockoutExpiredCategory,
            lockdownActiveCategory
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

        let lockdownActiveAction = UNNotificationAction(
            identifier: "VIEW_CONTACT_REMINDERS",
            title: "View Contact Reminders",
            options: [.foreground]
        )
        let lockdownActiveCategory = UNNotificationCategory(
            identifier: "LOCKDOWN_ACTIVE",
            actions: [lockdownActiveAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            unlockCategory,
            emergencyCategory,
            lockoutExpiredCategory,
            lockdownActiveCategory
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

    /// Identifier prefixes for the repeating lock-window reminders. Each one is
    /// scheduled once per active weekday with the weekday appended.
    private let lockReminderPrefixes = [
        "lock_start_reminder",
        "lock_end_reminder",
        "lockdown_active_reminder"
    ]

    /// Re-schedules all lock-window reminders to match the current schedule.
    ///
    /// One repeating request is registered per active weekday (identifiers
    /// suffixed with the weekday), so reminders only fire on nights the user
    /// actually selected. Previously these reminders were never scheduled at
    /// all: the methods existed but had no callers.
    func syncLockReminders(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, daysMask: Int) {
        cancelLockReminders()
        guard isAuthorized else { return }

        for weekday in 1...7 where (daysMask & (1 << (weekday - 1))) != 0 {
            scheduleLockReminder(
                id: "lock_start_reminder_\(weekday)",
                title: "Lockdown starting soon",
                body: "Your apps will be restricted in 15 minutes. Finish up and save your work.",
                categoryIdentifier: "LOCK_START",
                hour: startHour, minute: startMinute,
                offsetMinutes: -15,
                weekday: weekday
            )
            scheduleLockReminder(
                id: "lockdown_active_reminder_\(weekday)",
                title: "🔒 Lockdown Active",
                body: "Your lockdown is now active. Apps are restricted. Open SoberSend if you need to reach someone on your list.",
                categoryIdentifier: "LOCKDOWN_ACTIVE",
                hour: startHour, minute: startMinute,
                offsetMinutes: 0,
                weekday: weekday,
                isTimeSensitive: true,
                action: "lockdown_active"
            )
            scheduleLockReminder(
                id: "lock_end_reminder_\(weekday)",
                title: "Good morning!",
                body: "Your lockdown has ended. Stay strong today.",
                categoryIdentifier: "LOCK_END",
                hour: endHour, minute: endMinute,
                offsetMinutes: 0,
                weekday: weekday
            )
        }
    }

    private func scheduleLockReminder(
        id: String,
        title: String,
        body: String,
        categoryIdentifier: String,
        hour: Int,
        minute: Int,
        offsetMinutes: Int,
        weekday: Int,
        isTimeSensitive: Bool = false,
        action: String? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if isTimeSensitive { content.interruptionLevel = .timeSensitive }
        if let action { content.userInfo = ["action": action] }
        content.categoryIdentifier = categoryIdentifier

        var dateComponents = DateComponents()
        // Offset rolls the hour backwards when needed (e.g. a 00:30 lock warns
        // at 00:15 the previous day) — clamping the minute alone used to fire
        // the warning after the lock had already started.
        let totalMinutes = (hour * 60 + minute + offsetMinutes + 24 * 60) % (24 * 60)
        dateComponents.hour = totalMinutes / 60
        dateComponents.minute = totalMinutes % 60
        dateComponents.weekday = weekday

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Error scheduling \(id) reminder: \(error)") }
        }
    }

    /// Removes every lock-window reminder, including the legacy unsuffixed
    /// identifiers older builds registered.
    func cancelLockReminders() {
        var identifiers = [String]()
        for prefix in lockReminderPrefixes {
            identifiers.append(prefix)
            for weekday in 1...7 {
                identifiers.append("\(prefix)_\(weekday)")
            }
        }
        identifiers.append("lockdown_active")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
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
        content.sound = .default
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
        content.sound = .default
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
        case "lockdown_active":
            shared?.set(true, forKey: "lockdownActiveDeepLink")
            shared?.set(true, forKey: "notificationDeepLink")
        default:
            break
        }
    }
}