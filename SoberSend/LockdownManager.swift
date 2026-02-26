import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI

@MainActor
@Observable
class LockdownManager {
    var isAuthorized: Bool = false
    var selectionToDiscourage = FamilyActivitySelection() {
        didSet { setShieldRestrictions() }
    }

    private let store = ManagedSettingsStore()
    private var timer: Timer?

    // Day-of-week bitmask keys in shared defaults:
    // bit 0 = Sunday, bit 1 = Monday, ... bit 6 = Saturday (matches Calendar.component(.weekday))
    // Default: every day (0b1111111 = 127)
    private let sharedDefaults = UserDefaults(suiteName: "group.com.musamasalla.SoberSend") ?? UserDefaults.standard
    
    var activeDaysMask: Int {
        get { sharedDefaults.object(forKey: "activeDaysMask") == nil ? 127 : sharedDefaults.integer(forKey: "activeDaysMask") }
        set { sharedDefaults.set(newValue, forKey: "activeDaysMask") }
    }

    init() {
        checkAuthorization()
        startScheduleMonitoring()
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
            startScheduleMonitoring()
        } catch {
            print("Failed to authorize FamilyControls: \(error)")
        }
    }

    private func checkAuthorization() {
        if AuthorizationCenter.shared.authorizationStatus == .approved {
            isAuthorized = true
        }
    }

    func setShieldRestrictions() {
        if isCurrentlyInLockedWindow() {
            store.shield.applications = selectionToDiscourage.applicationTokens.isEmpty ? nil : selectionToDiscourage.applicationTokens
            store.shield.applicationCategories = selectionToDiscourage.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selectionToDiscourage.categoryTokens)
            store.shield.webDomains = selectionToDiscourage.webDomainTokens.isEmpty ? nil : selectionToDiscourage.webDomainTokens
        } else {
            clearRestrictions()
        }
    }

    func clearRestrictions() {
        store.clearAllSettings()
    }

    // MARK: - Schedule Monitoring
    private func startScheduleMonitoring() {
        guard isAuthorized else { return }
        setShieldRestrictions()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.setShieldRestrictions() }
        }
    }

    // MARK: - Day-of-week helpers
    
    /// Returns true if the given Calendar weekday (1=Sunday...7=Saturday) is active
    func isDayActive(_ calendarWeekday: Int) -> Bool {
        let bit = 1 << (calendarWeekday - 1)
        return (activeDaysMask & bit) != 0
    }
    
    func toggleDay(_ calendarWeekday: Int) {
        let bit = 1 << (calendarWeekday - 1)
        activeDaysMask ^= bit
        setShieldRestrictions()
    }
    
    func setAllDays(active: Bool) {
        activeDaysMask = active ? 127 : 0
        setShieldRestrictions()
    }

    // MARK: - Window Check
    public func isCurrentlyInLockedWindow() -> Bool {
        let startHour = sharedDefaults.object(forKey: "lockStartHour") == nil ? 22 : sharedDefaults.integer(forKey: "lockStartHour")
        let startMinute = sharedDefaults.integer(forKey: "lockStartMinute")
        let endHour = sharedDefaults.object(forKey: "lockEndHour") == nil ? 7 : sharedDefaults.integer(forKey: "lockEndHour")
        let endMinute = sharedDefaults.integer(forKey: "lockEndMinute")

        let now = Date()
        let calendar = Calendar.current
        
        // Check if today's weekday is enabled
        let todayWeekday = calendar.component(.weekday, from: now)
        if !isDayActive(todayWeekday) { return false }
        
        guard let startToday = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: now),
              let endToday = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: now) else {
            return false
        }

        if startToday <= endToday {
            return now >= startToday && now <= endToday
        } else {
            // Crosses midnight — also check if yesterday was enabled for the "after midnight" portion
            let yesterdayWeekday = calendar.component(.weekday, from: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
            let afterMidnight = now <= endToday
            if afterMidnight && !isDayActive(yesterdayWeekday) { return false }
            return now >= startToday || now <= endToday
        }
    }
}
