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
    @State private var showPaywall = false
    @AppStorage("morningReportEnabled", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var morningReportEnabled: Bool = true
    
    let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    
    // Minimum gap in minutes between start and end
    private let minimumGapMinutes = 60
    
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
                    Button("Upgrade to Premium") { showPaywall = true }
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
            Section {
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
                        enforceMinimumGap(changedStart: true)
                    }
                DatePicker("Ends", selection: $endTime, displayedComponents: .hourAndMinute)
                    .onChange(of: endTime) { _, v in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                        lockdownManager.lockEndHour = c.hour ?? 7
                        lockdownManager.lockEndMinute = c.minute ?? 0
                        enforceMinimumGap(changedStart: false)
                    }
            } header: { Text("Lockdown Schedule") } footer: {
                Text("The lockdown window must be at least 1 hour. If start and end are too close, the end time will be adjusted automatically.")
                    .font(.caption2)
            }
            
            // Notifications
            Section {
                if notificationManager.isAuthorized {
                    Toggle("Morning Report", isOn: $morningReportEnabled)
                        .onChange(of: morningReportEnabled) { _, enabled in
                            if enabled {
                                notificationManager.scheduleMorningReport(at: 8, minute: 0)
                            } else {
                                notificationManager.cancelMorningReport()
                            }
                        }
                } else {
                    HStack {
                        Label("Notifications", systemImage: "bell.slash")
                        Spacer()
                        Button("Enable in Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
            } header: { Text("Notifications") } footer: {
                Text("The morning report reminds you every day at 8 AM to review last night's activity.")
                    .font(.caption2)
            }
            
            // About
            Section("About") {
                Link("Privacy Policy", destination: URL(string: "https://musamasalla.github.io/SoberSend/privacy.html")!)
                Link("Terms of Service", destination: URL(string: "https://musamasalla.github.io/SoberSend/terms.html")!)
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
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
    
    // MARK: - Helpers
    
    private func setWeekends() {
        lockdownManager.setAllDays(active: false)
        lockdownManager.toggleDay(1) // Sunday
        lockdownManager.toggleDay(7) // Saturday
    }
    
    /// Ensures at least a 1-hour gap between start and end.
    /// If start == end or within the gap, push the other time forward.
    private func enforceMinimumGap(changedStart: Bool) {
        let startMinutes = lockdownManager.lockStartHour * 60 + lockdownManager.lockStartMinute
        let endMinutes = lockdownManager.lockEndHour * 60 + lockdownManager.lockEndMinute
        
        // Calculate effective gap (handle overnight wrapping: e.g. 22:00→07:00 = 9 hours)
        let gap: Int
        if endMinutes > startMinutes {
            gap = endMinutes - startMinutes
        } else {
            gap = (24 * 60 - startMinutes) + endMinutes
        }
        
        if gap < minimumGapMinutes {
            if changedStart {
                // Push end forward by 1 hour from start
                let newEnd = (startMinutes + minimumGapMinutes) % (24 * 60)
                lockdownManager.lockEndHour = newEnd / 60
                lockdownManager.lockEndMinute = newEnd % 60
                endTime = Calendar.current.date(bySettingHour: lockdownManager.lockEndHour, minute: lockdownManager.lockEndMinute, second: 0, of: Date()) ?? Date()
            } else {
                // Push start back by 1 hour from end
                var newStart = endMinutes - minimumGapMinutes
                if newStart < 0 { newStart += 24 * 60 }
                lockdownManager.lockStartHour = newStart / 60
                lockdownManager.lockStartMinute = newStart % 60
                startTime = Calendar.current.date(bySettingHour: lockdownManager.lockStartHour, minute: lockdownManager.lockStartMinute, second: 0, of: Date()) ?? Date()
            }
        }
    }
}
