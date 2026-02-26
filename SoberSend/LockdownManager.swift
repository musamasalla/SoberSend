import Foundation
import FamilyControls
import ManagedSettings
import SwiftUI

@MainActor
@Observable
class LockdownManager {
    var isAuthorized: Bool = false
    var selectionToDiscourage = FamilyActivitySelection() {
        didSet {
            setShieldRestrictions()
        }
    }

    private let store = ManagedSettingsStore()
    private var timer: Timer?

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
        // Evaluate if currently in locked window before blindly applying shield
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
    
    // MARK: - Schedule Logic
    private func startScheduleMonitoring() {
        guard isAuthorized else { return }
        
        // Initial check
        setShieldRestrictions()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in // Check every minute
            DispatchQueue.main.async {
                self?.setShieldRestrictions()
            }
        }
    }
    
    public func isCurrentlyInLockedWindow() -> Bool {
        let sharedDefaults = UserDefaults(suiteName: "group.com.musamasalla.SoberSend") ?? UserDefaults.standard
        let startHour = sharedDefaults.integer(forKey: "lockStartHour")
        let startMinute = sharedDefaults.integer(forKey: "lockStartMinute")
        let endHour = sharedDefaults.integer(forKey: "lockEndHour")
        let endMinute = sharedDefaults.integer(forKey: "lockEndMinute")
        
        // If defaults aren't set yet (returns 0), we might just allow it, but we set robust defaults in AppStorage.
        // Assuming hour 0 minute 0 is possible, we need to carefully compare dates.
        
        let now = Date()
        let calendar = Calendar.current
        
        guard let startToday = calendar.date(bySettingHour: startHour == 0 && sharedDefaults.object(forKey: "lockStartHour") == nil ? 22 : startHour, minute: startMinute, second: 0, of: now),
              let endToday = calendar.date(bySettingHour: endHour == 0 && sharedDefaults.object(forKey: "lockEndHour") == nil ? 7 : endHour, minute: endMinute, second: 0, of: now) else {
            return false
        }
        
        if startToday <= endToday {
            // e.g. 1 PM to 5 PM
            return now >= startToday && now <= endToday
        } else {
            // e.g. 10 PM to 7 AM (crosses midnight)
            return now >= startToday || now <= endToday
        }
    }
}
