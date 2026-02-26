import SwiftUI
import UserNotifications

struct SettingsView: View {
    // Environment Managers
    @Environment(StoreManager.self) private var storeManager
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(LockdownManager.self) private var lockdownManager
    
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    
    let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        Form {
            // Premium Status
            Section("Premium Status") {
                if storeManager.isPremium {
                    HStack {
                        Text("SoberSend Premium")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                } else {
                    NavigationLink("Upgrade to Premium") { PaywallView() }
                }
                Button("Restore Purchases") {
                    Task {
                        await storeManager.restorePurchases()
                        restoreMessage = storeManager.isPremium
                            ? "Premium restored successfully!"
                            : "No active subscriptions found."
                        showRestoreAlert = true
                    }
                }
            }
            
            // Schedule
            Section("Lockdown Schedule") {
                // Day pills
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active nights")
                        .font(.caption).foregroundColor(.gray)
                    
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { i in
                            let weekday = i + 1
                            let isActive = lockdownManager.isDayActive(weekday)
                            let isWeekend = weekday == 1 || weekday == 7  // Sunday=1, Saturday=7
                            Button(action: { lockdownManager.toggleDay(weekday) }) {
                                Text(dayLabels[i])
                                    .font(.system(size: 13, weight: .bold))
                                    .frame(width: 34, height: 34)
                                    .background(isActive ? (isWeekend ? Color.orange : Color.blue) : Color.white.opacity(0.08))
                                    .foregroundColor(isActive ? .white : .gray)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button("Weekends") { setWeekends() }
                            .font(.caption).foregroundColor(.orange)
                        Button("Every Night") { lockdownManager.setAllDays(active: true) }
                            .font(.caption).foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 4)
                
                DatePicker("Starts", selection: $startTime, displayedComponents: .hourAndMinute)
                    .onChange(of: startTime) { _, v in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                        lockdownManager.lockStartHour = c.hour ?? 22
                        lockdownManager.lockStartMinute = c.minute ?? 0
                    }
                DatePicker("Ends", selection: $endTime, displayedComponents: .hourAndMinute)
                    .onChange(of: endTime) { _, v in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                        lockdownManager.lockEndHour = c.hour ?? 7
                        lockdownManager.lockEndMinute = c.minute ?? 0
                    }
            }
            
            // Notifications
            Section("Notifications") {
                HStack {
                    Text("Morning Report")
                    Spacer()
                    if notificationManager.isAuthorized {
                        Text("Enabled")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    } else {
                        Button("Enable in Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                Button("Send Test Notification") {
                    let content = UNMutableNotificationContent()
                    content.title = "Last night's report 🛡️"
                    content.body = "Tap to see who you tried to text last night."
                    content.sound = .default
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                    let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request)
                }
            }
            
            // About
            Section("About") {
                Link("Privacy Policy", destination: URL(string: "https://musamasalla.github.io/SoberSend/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://musamasalla.github.io/SoberSend/terms")!)
                Text("Version 1.0.0").foregroundColor(.gray)
            }
        }
        .navigationTitle("Settings ⚙️")
        .preferredColorScheme(.dark)
        .onAppear {
            startTime = Calendar.current.date(bySettingHour: lockdownManager.lockStartHour, minute: lockdownManager.lockStartMinute, second: 0, of: Date()) ?? Date()
            endTime = Calendar.current.date(bySettingHour: lockdownManager.lockEndHour, minute: lockdownManager.lockEndMinute, second: 0, of: Date()) ?? Date()
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(restoreMessage) }
    }
    
    private func setWeekends() {
        lockdownManager.setAllDays(active: false)
        lockdownManager.toggleDay(6)
        lockdownManager.toggleDay(7)
    }
}
