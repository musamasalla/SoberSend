import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

// Shares the ManagedSettingsStore with the main app and Shield Action extension
// so all three write to the same shield state.
extension ManagedSettingsStore.Name {
    static let soberSend = ManagedSettingsStore.Name("com.musamasalla.SoberSend.lockdown")
}

/// Reacts to lockdown window boundaries in the background so shields apply and
/// lift on schedule even when the main app is never opened.
class SoberSendDeviceActivityMonitor: DeviceActivityMonitor {

    private let store = ManagedSettingsStore(named: .soberSend)
    private let sharedDefaults = UserDefaults(suiteName: "group.com.musamasalla.SoberSend")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        applyShieldIfWindowActive()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        applyShieldIfWindowActive()
    }

    /// Recomputes whether shielding should be active right now and syncs the
    /// store to match. Called at every window boundary, this both engages
    /// shields at lock start and clears them at lock end.
    private func applyShieldIfWindowActive() {
        guard let defaults = sharedDefaults else { return }
        defaults.synchronize()

        // User-driven states that override the schedule
        if defaults.bool(forKey: "isManuallyActive") { return }
        let bypassEnd = defaults.double(forKey: "bypassEndTime")
        if bypassEnd > 0 && Date() < Date(timeIntervalSince1970: bypassEnd) { return }

        guard isCurrentlyInLockedWindow(defaults: defaults) else {
            store.clearAllSettings()
            return
        }

        guard let selectionData = defaults.data(forKey: "savedFamilyActivitySelection"),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData) else {
            return
        }

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    /// Mirrors LockdownManager.isCurrentlyInLockedWindow(), including the
    /// day-of-week mask the OS schedule itself does not enforce.
    private func isCurrentlyInLockedWindow(defaults: UserDefaults) -> Bool {
        let startHour = defaults.object(forKey: "lockStartHour") == nil ? 22 : defaults.integer(forKey: "lockStartHour")
        let startMinute = defaults.integer(forKey: "lockStartMinute")
        let endHour = defaults.object(forKey: "lockEndHour") == nil ? 7 : defaults.integer(forKey: "lockEndHour")
        let endMinute = defaults.integer(forKey: "lockEndMinute")
        let activeDaysMask = defaults.object(forKey: "activeDaysMask") == nil ? 127 : defaults.integer(forKey: "activeDaysMask")

        let now = Date()
        let calendar = Calendar.current

        func isDayActive(_ weekday: Int) -> Bool {
            (activeDaysMask & (1 << (weekday - 1))) != 0
        }

        let todayWeekday = calendar.component(.weekday, from: now)
        guard isDayActive(todayWeekday) else { return false }

        guard let startToday = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: now),
              let endToday = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: now) else {
            return false
        }

        if startToday <= endToday {
            return now >= startToday && now <= endToday
        } else {
            let yesterdayWeekday = calendar.component(.weekday, from: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
            let afterMidnight = now <= endToday
            if afterMidnight && !isDayActive(yesterdayWeekday) { return false }
            return now >= startToday || now <= endToday
        }
    }
}
