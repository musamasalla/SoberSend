import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI
import DeviceActivity

extension ManagedSettingsStore.Name {
    static let soberSend = ManagedSettingsStore.Name("com.musamasalla.SoberSend.lockdown")
}

@MainActor
@Observable
class LockdownManager {
    var isAuthorized: Bool = false
    
    // Shared constants
    private let appGroup = "group.com.musamasalla.SoberSend"
    private let activityName = DeviceActivityName("com.musamasalla.SoberSend.lockdownActivity")
    
    @ObservationIgnored private lazy var sharedDefaults = UserDefaults(suiteName: appGroup) ?? UserDefaults.standard
    @ObservationIgnored private let selectionKey = "savedFamilyActivitySelection"
    
    var selectionToDiscourage = FamilyActivitySelection() {
        didSet {
            saveSelection()
            setShieldRestrictions()
        }
    }

    var isManuallyActivated: Bool {
        get { sharedDefaults.bool(forKey: "isManuallyActive") }
        set {
            sharedDefaults.set(newValue, forKey: "isManuallyActive")
            setShieldRestrictions()
        }
    }

    var activeDaysMask: Int {
        get { sharedDefaults.object(forKey: "activeDaysMask") == nil ? 127 : sharedDefaults.integer(forKey: "activeDaysMask") }
        set { sharedDefaults.set(newValue, forKey: "activeDaysMask") }
    }

    private let store = ManagedSettingsStore(named: .soberSend)

    init() {
        loadSelection()
        checkAuthorization()
    }

    private func saveSelection() {
        if let data = try? JSONEncoder().encode(selectionToDiscourage) {
            sharedDefaults.set(data, forKey: selectionKey)
        }
    }

    private func loadSelection() {
        if let data = sharedDefaults.data(forKey: selectionKey),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectionToDiscourage = selection
        }
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
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
        if isAppBlockingActive() {
            store.shield.applications = selectionToDiscourage.applicationTokens.isEmpty ? nil : selectionToDiscourage.applicationTokens
            store.shield.applicationCategories = selectionToDiscourage.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selectionToDiscourage.categoryTokens)
            store.shield.webDomains = selectionToDiscourage.webDomainTokens.isEmpty ? nil : selectionToDiscourage.webDomainTokens
            
            // Register with OS for background enforcement
            startDeviceActivityMonitoring()
        } else {
            clearRestrictions()
        }
    }

    func clearRestrictions() {
        store.clearAllSettings()
        DeviceActivityCenter().stopMonitoring([activityName])
    }

    // MARK: - Device Activity Monitoring (Background Enforcement)
    private func startDeviceActivityMonitoring() {
        guard isAuthorized else { return }
        
        let startHour = sharedDefaults.object(forKey: "lockStartHour") == nil ? 22 : sharedDefaults.integer(forKey: "lockStartHour")
        let startMinute = sharedDefaults.integer(forKey: "lockStartMinute")
        let endHour = sharedDefaults.object(forKey: "lockEndHour") == nil ? 7 : sharedDefaults.integer(forKey: "lockEndHour")
        let endMinute = sharedDefaults.integer(forKey: "lockEndMinute")
        
        // Create components for the schedule
        let startComponents = DateComponents(hour: startHour, minute: startMinute)
        let endComponents = DateComponents(hour: endHour, minute: endMinute)
        
        // DeviceActivitySchedule handles the "Every Day" logic if we want, 
        // but since we have a custom bitmask, we monitor the window and let 
        // isAppBlockingActive check the weekday on each transition or manual trigger.
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )
        
        do {
            try DeviceActivityCenter().startMonitoring(activityName, during: schedule)
            print("Successfully started monitoring schedule: \(startHour):\(startMinute) to \(endHour):\(endMinute)")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

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
    public func isAppBlockingActive() -> Bool {
        return isCurrentlyInLockedWindow() || isManuallyActivated
    }

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
            let yesterdayWeekday = calendar.component(.weekday, from: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
            let afterMidnight = now <= endToday
            if afterMidnight && !isDayActive(yesterdayWeekday) { return false }
            return now >= startToday || now <= endToday
        }
    }
}
