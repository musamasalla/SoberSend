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
        ZStack {
            SoberTheme.charcoal.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Premium Status
                    premiumSection
                    
                    // Schedule
                    scheduleSection
                    
                    // Notifications
                    notificationsSection
                    
                    // About
                    aboutSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Settings")
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
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Premium Status", icon: "crown.fill", color: SoberTheme.lavender)
            
            VStack(spacing: 0) {
                if storeManager.isPremium {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(SoberTheme.mint.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(SoberTheme.mint)
                        }
                        Text("SoberSend Premium")
                            .font(SoberTheme.headline())
                            .foregroundColor(.white)
                        Spacer()
                        SoberPill(text: "ACTIVE", color: SoberTheme.mint, small: true)
                    }
                    .padding(.vertical, 4)
                } else {
                    Button(action: { showPaywall = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(SoberTheme.lavender.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "crown.fill")
                                    .foregroundColor(SoberTheme.lavender)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upgrade to Premium")
                                    .font(SoberTheme.headline())
                                    .foregroundColor(SoberTheme.lavender)
                                Text("Unlock all features")
                                    .font(SoberTheme.caption())
                                    .foregroundColor(SoberTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(SoberTheme.lavender.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
                
                Divider().background(SoberTheme.border)
                
                Button(action: {
                    Task {
                        await storeManager.restorePurchases()
                        restoreMessage = storeManager.isPremium
                            ? "Premium restored successfully!"
                            : "No active subscriptions found."
                        showRestoreAlert = true
                    }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(SoberTheme.skyBlue.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(SoberTheme.skyBlue)
                        }
                        Text("Restore Purchases")
                            .font(SoberTheme.body())
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
            .soberCard()
        }
    }
    
    // MARK: - Schedule Section
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Lockdown Schedule", icon: "calendar.badge.clock", color: SoberTheme.peach)
            
            VStack(spacing: 14) {
                // Day pills
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active nights")
                        .font(SoberTheme.caption())
                        .foregroundColor(SoberTheme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { i in
                            let weekday = i + 1
                            let isActive = lockdownManager.isDayActive(weekday)
                            let isWeekend = weekday == 1 || weekday == 7
                            Button(action: { lockdownManager.toggleDay(weekday) }) {
                                Text(dayLabels[i])
                                    .font(SoberTheme.caption(13))
                                    .fontWeight(.bold)
                                    .frame(width: 34, height: 34)
                                    .background(
                                        isActive
                                        ? (isWeekend ? SoberTheme.peach : SoberTheme.lavender)
                                        : SoberTheme.surfaceBright
                                    )
                                    .foregroundColor(isActive ? SoberTheme.charcoal : SoberTheme.textSecondary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button("Weekends") { setWeekends() }
                            .font(SoberTheme.caption())
                            .foregroundColor(SoberTheme.peach)
                        Button("Every Night") { lockdownManager.setAllDays(active: true) }
                            .font(SoberTheme.caption())
                            .foregroundColor(SoberTheme.lavender)
                    }
                }
                
                Divider().background(SoberTheme.border)
                
                // Time pickers
                HStack {
                    Image(systemName: "moon.fill").foregroundColor(SoberTheme.lavender)
                    DatePicker("Starts", selection: $startTime, displayedComponents: .hourAndMinute)
                        .onChange(of: startTime) { _, v in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                            lockdownManager.lockStartHour = c.hour ?? 22
                            lockdownManager.lockStartMinute = c.minute ?? 0
                            enforceMinimumGap(changedStart: true)
                        }
                }
                
                HStack {
                    Image(systemName: "sunrise.fill").foregroundColor(SoberTheme.peach)
                    DatePicker("Ends", selection: $endTime, displayedComponents: .hourAndMinute)
                        .onChange(of: endTime) { _, v in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                            lockdownManager.lockEndHour = c.hour ?? 7
                            lockdownManager.lockEndMinute = c.minute ?? 0
                            enforceMinimumGap(changedStart: false)
                        }
                }
            }
            .soberCard()
            
            Text("The lockdown window must be at least 1 hour. If start and end are too close, the end time will be adjusted automatically.")
                .font(SoberTheme.caption(11))
                .foregroundColor(SoberTheme.textSecondary)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Notifications Section
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Notifications", icon: "bell.fill", color: SoberTheme.cream)
            
            VStack(spacing: 0) {
                if notificationManager.isAuthorized {
                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(SoberTheme.cream.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "sunrise.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(SoberTheme.cream)
                            }
                            Text("Morning Report")
                                .font(SoberTheme.body())
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Toggle("", isOn: $morningReportEnabled)
                            .toggleStyle(SoberToggleStyle(onColor: SoberTheme.cream))
                            .labelsHidden()
                            .onChange(of: morningReportEnabled) { _, enabled in
                                if enabled {
                                    notificationManager.scheduleMorningReport(at: 8, minute: 0)
                                } else {
                                    notificationManager.cancelMorningReport()
                                }
                            }
                    }
                } else {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(SoberTheme.peach.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "bell.slash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(SoberTheme.peach)
                        }
                        Text("Notifications")
                            .font(SoberTheme.body())
                            .foregroundColor(.white)
                        Spacer()
                        Button("Enable in Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(SoberTheme.caption())
                        .foregroundColor(SoberTheme.lavender)
                    }
                }
            }
            .soberCard()
            
            Text("The morning report reminds you every day at 8 AM to review last night's activity.")
                .font(SoberTheme.caption(11))
                .foregroundColor(SoberTheme.textSecondary)
                .padding(.horizontal, 4)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "About", icon: "info.circle.fill", color: SoberTheme.skyBlue)
            
            VStack(spacing: 0) {
                settingsRow(icon: "lock.doc.fill", iconColor: SoberTheme.lavender, title: "Privacy Policy") {
                    if let url = URL(string: "https://musamasalla.github.io/SoberSend/privacy.html") {
                        UIApplication.shared.open(url)
                    }
                }
                
                Divider().background(SoberTheme.border).padding(.leading, 52)
                
                settingsRow(icon: "doc.text.fill", iconColor: SoberTheme.skyBlue, title: "Terms of Service") {
                    if let url = URL(string: "https://musamasalla.github.io/SoberSend/terms.html") {
                        UIApplication.shared.open(url)
                    }
                }
                
                Divider().background(SoberTheme.border).padding(.leading, 52)
                
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(SoberTheme.surfaceBright)
                            .frame(width: 36, height: 36)
                        Image(systemName: "number")
                            .font(.system(size: 14))
                            .foregroundColor(SoberTheme.textSecondary)
                    }
                    Text("Version 1.0.0")
                        .font(SoberTheme.body())
                        .foregroundColor(SoberTheme.textSecondary)
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .soberCard()
        }
    }
    
    // MARK: - Settings Row
    
    @ViewBuilder
    private func settingsRow(icon: String, iconColor: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
                Text(title)
                    .font(SoberTheme.body())
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(SoberTheme.textSecondary)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func setWeekends() {
        lockdownManager.setAllDays(active: false)
        lockdownManager.toggleDay(1) // Sunday
        lockdownManager.toggleDay(7) // Saturday
    }
    
    private func enforceMinimumGap(changedStart: Bool) {
        let startMinutes = lockdownManager.lockStartHour * 60 + lockdownManager.lockStartMinute
        let endMinutes = lockdownManager.lockEndHour * 60 + lockdownManager.lockEndMinute
        
        let gap: Int
        if endMinutes > startMinutes {
            gap = endMinutes - startMinutes
        } else {
            gap = (24 * 60 - startMinutes) + endMinutes
        }
        
        if gap < minimumGapMinutes {
            if changedStart {
                let newEnd = (startMinutes + minimumGapMinutes) % (24 * 60)
                lockdownManager.lockEndHour = newEnd / 60
                lockdownManager.lockEndMinute = newEnd % 60
                endTime = Calendar.current.date(bySettingHour: lockdownManager.lockEndHour, minute: lockdownManager.lockEndMinute, second: 0, of: Date()) ?? Date()
            } else {
                var newStart = endMinutes - minimumGapMinutes
                if newStart < 0 { newStart += 24 * 60 }
                lockdownManager.lockStartHour = newStart / 60
                lockdownManager.lockStartMinute = newStart % 60
                startTime = Calendar.current.date(bySettingHour: lockdownManager.lockStartHour, minute: lockdownManager.lockStartMinute, second: 0, of: Date()) ?? Date()
            }
        }
    }
}
