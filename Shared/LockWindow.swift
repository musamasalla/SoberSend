import Foundation

/// Lock-window arithmetic shared by the app and the DeviceActivityMonitor
/// extension.
///
/// Two targets have to answer "is the nightly lock active right now": the app,
/// to decide whether shields should be up, and the extension, at every schedule
/// boundary. They used to each carry their own copy of this logic — same intent,
/// different code — so a change to one silently desynchronised background
/// enforcement from what the UI showed. One implementation, one behaviour.
///
/// `daysMask` uses bit `1 << (weekday - 1)` for the 1-based Gregorian weekday
/// (1 = Sunday, matching `Calendar.component(.weekday)`).
enum LockWindow {

    static func isDayActive(_ weekday: Int, mask: Int) -> Bool {
        (mask & (1 << (weekday - 1))) != 0
    }

    /// Whether `now` falls inside the lock window on an active night.
    ///
    /// Windows that cross midnight (e.g. 22:00 → 07:00) stay active after
    /// midnight, but only when *yesterday* was also an active night — otherwise
    /// a Friday-night-only schedule would leak into Saturday morning.
    static func isInWindow(
        startHour: Int, startMinute: Int,
        endHour: Int, endMinute: Int,
        daysMask: Int,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        let todayWeekday = calendar.component(.weekday, from: now)
        guard isDayActive(todayWeekday, mask: daysMask) else { return false }

        guard let startToday = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: now),
              let endToday = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: now) else {
            return false
        }

        if startToday <= endToday {
            return now >= startToday && now <= endToday
        } else {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
            let yesterdayWeekday = calendar.component(.weekday, from: yesterday)
            if now <= endToday && !isDayActive(yesterdayWeekday, mask: daysMask) { return false }
            return now >= startToday || now <= endToday
        }
    }
}
