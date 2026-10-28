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

    // MARK: - Notification Categories
    /// Registers the actionable notification categories. Called once from app
    /// launch; categories persist across launches so re-registering is only
    /// needed after the set changes.
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

    // MARK: - UNUserNotificationCenterDelegate
    // NOTE: NotificationManager is deliberately NOT the notification center
    // delegate — SoberSendApp assigns AppNotificationDelegate.shared, which
    // owns deep-link routing. The delegate methods that used to live here were
    // dead code that duplicated that logic.
}