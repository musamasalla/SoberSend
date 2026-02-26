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
            if let error = error {
                print("Error scheduling morning report: \(error)")
            }
        }
    }
    
    func cancelMorningReport() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["morning_report"])
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
}
