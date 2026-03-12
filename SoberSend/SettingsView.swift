import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(LockdownManager.self) private var lockdownManager
    
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var showPaywall = false
    @AppStorage("morningReportEnabled", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var morningReportEnabled: Bool = true
    @AppStorage("appearanceMode", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var appearanceModeRaw: Int = 0
    
    let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]
    private let minimumGapMinutes = 60
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                premiumSection
                scheduleSection
                notificationsSection
                appearanceSection
                aboutSection
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(SoberTheme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .onAppear {
            startTime = Calendar.current.date(bySettingHour: lockdownManager.lockStartHour, minute: lockdownManager.lockStartMinute, second: 0, of: Date()) ?? Date()
            endTime = Calendar.current.date(bySettingHour: lockdownManager.lockEndHour, minute: lockdownManager.lockEndMinute, second: 0, of: Date()) ?? Date()
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(restoreMessage) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
    
    // MARK: - Premium
    
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Premium Status", icon: "crown.fill")
            
            VStack(spacing: 0) {
                if storeManager.isPremium {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(SoberTheme.mintCard).frame(width: 40, height: 40)
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(SoberTheme.mintText)
                        }
                        Text("SoberSend Premium")
                            .font(SoberTheme.headline()).foregroundStyle(SoberTheme.textPrimary)
                        Spacer()
                        SoberPill(text: "ACTIVE", bgColor: SoberTheme.mintCard, fgColor: SoberTheme.mintText, small: true)
                    }
                    .padding(.vertical, 4)
                } else {
                    Button { showPaywall = true } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(SoberTheme.lavenderCard).frame(width: 40, height: 40)
                                Image(systemName: "crown.fill").foregroundStyle(SoberTheme.lavenderText)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upgrade to Premium")
                                    .font(SoberTheme.headline()).foregroundStyle(SoberTheme.lavenderText)
                                Text("Unlock all features")
                                    .font(SoberTheme.caption()).foregroundStyle(SoberTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(SoberTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
                
                Divider()
                
                Button {
                    Task {
                        await storeManager.restorePurchases()
                        restoreMessage = storeManager.isPremium ? "Premium restored successfully!" : "No active subscriptions found."
                        showRestoreAlert = true
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(SoberTheme.blueCard).frame(width: 40, height: 40)
                            Image(systemName: "arrow.clockwise").foregroundStyle(SoberTheme.blueText)
                        }
                        Text("Restore Purchases")
                            .font(SoberTheme.body()).foregroundStyle(SoberTheme.textPrimary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
            .soberCard()
        }
    }
    
    // MARK: - Schedule
    
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Lockdown Schedule", icon: "calendar.badge.clock")
            
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Active nights")
                        .font(SoberTheme.caption()).foregroundStyle(SoberTheme.textSecondary)
                        .textCase(.uppercase).tracking(0.5)
                    
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { i in
                            let weekday = i + 1
                            let isActive = lockdownManager.isDayActive(weekday)
                            let isWeekend = weekday == 1 || weekday == 7
                            Button { lockdownManager.toggleDay(weekday) } label: {
                                Text(dayLabels[i])
                                    .font(SoberTheme.caption(13)).fontWeight(.bold)
                                    .frame(width: 34, height: 34)
                                    .background(isActive ? (isWeekend ? SoberTheme.peachCard : SoberTheme.lavenderCard) : Color.gray.opacity(0.12))
                                    .foregroundStyle(isActive ? (isWeekend ? SoberTheme.peachText : SoberTheme.lavenderText) : SoberTheme.textSecondary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button("Weekends") { setWeekends() }.font(SoberTheme.caption()).foregroundStyle(SoberTheme.peachText)
                        Button("Every Night") { lockdownManager.setAllDays(active: true) }.font(SoberTheme.caption()).foregroundStyle(SoberTheme.lavenderText)
                    }
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "moon.fill").foregroundStyle(SoberTheme.lavenderText)
                    DatePicker("Starts", selection: $startTime, displayedComponents: .hourAndMinute)
                        .onChange(of: startTime) { _, v in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: v)
                            lockdownManager.lockStartHour = c.hour ?? 22
                            lockdownManager.lockStartMinute = c.minute ?? 0
                            enforceMinimumGap(changedStart: true)
                        }
                }
                HStack {
                    Image(systemName: "sunrise.fill").foregroundStyle(SoberTheme.peachText)
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
            
            Text("The lockdown window must be at least 1 hour.")
                .font(SoberTheme.caption(11)).foregroundStyle(SoberTheme.textSecondary).padding(.horizontal, 4)
        }
    }
    
    // MARK: - Notifications
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Notifications", icon: "bell.fill")
            
            VStack(spacing: 0) {
                if notificationManager.isAuthorized {
                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle().fill(SoberTheme.creamCard).frame(width: 40, height: 40)
                                Image(systemName: "sunrise.fill").font(.system(size: 14)).foregroundStyle(SoberTheme.creamText)
                            }
                            Text("Morning Report").font(SoberTheme.body()).foregroundStyle(SoberTheme.textPrimary)
                        }
                        Spacer()
                        Toggle("", isOn: $morningReportEnabled)
                            .labelsHidden()
                            .onChange(of: morningReportEnabled) { _, enabled in
                                if enabled { notificationManager.scheduleMorningReport(at: 8, minute: 0) }
                                else { notificationManager.cancelMorningReport() }
                            }
                    }
                } else {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle().fill(SoberTheme.peachCard).frame(width: 40, height: 40)
                            Image(systemName: "bell.slash.fill").font(.system(size: 14)).foregroundStyle(SoberTheme.peachText)
                        }
                        Text("Notifications").font(SoberTheme.body()).foregroundStyle(SoberTheme.textPrimary)
                        Spacer()
                        Button("Enable") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }.font(SoberTheme.caption()).foregroundStyle(SoberTheme.lavenderText)
                    }
                }
            }
            .soberCard()
            
            Text("Daily 8 AM report of last night's activity.")
                .font(SoberTheme.caption(11)).foregroundStyle(SoberTheme.textSecondary).padding(.horizontal, 4)
        }
    }
    
    // MARK: - Appearance
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "Appearance", icon: "paintbrush.fill")
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(SoberTheme.creamCard).frame(width: 40, height: 40)
                        Image(systemName: "moon.stars.fill").font(.system(size: 16, weight: .semibold)).foregroundStyle(SoberTheme.creamText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Theme").font(SoberTheme.headline()).foregroundStyle(SoberTheme.textPrimary)
                        Text("Choose how SoberSend looks").font(SoberTheme.caption()).foregroundStyle(SoberTheme.textSecondary)
                    }
                    Spacer()
                }
                
                Picker("Appearance", selection: $appearanceModeRaw) {
                    ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .soberCard()
        }
    }
    
    // MARK: - About
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SoberSectionHeader(title: "About", icon: "info.circle.fill")
            
            VStack(spacing: 0) {
                settingsRow(icon: "lock.doc.fill", iconBg: SoberTheme.lavenderCard, iconFg: SoberTheme.lavenderText, title: "Privacy Policy") {
                    if let url = URL(string: "https://musamasalla.github.io/SoberSend/privacy.html") { UIApplication.shared.open(url) }
                }
                Divider().padding(.leading, 52)
                settingsRow(icon: "doc.text.fill", iconBg: SoberTheme.blueCard, iconFg: SoberTheme.blueText, title: "Terms of Service") {
                    if let url = URL(string: "https://musamasalla.github.io/SoberSend/terms.html") { UIApplication.shared.open(url) }
                }
                Divider().padding(.leading, 52)
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(SoberTheme.blueCard).frame(width: 40, height: 40)
                        Image(systemName: "number").font(.system(size: 16)).foregroundStyle(SoberTheme.blueText)
                    }
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")").font(SoberTheme.body()).foregroundStyle(SoberTheme.textSecondary)
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .soberCard()
        }
    }
    
    @ViewBuilder
    private func settingsRow(icon: String, iconBg: Color, iconFg: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(iconBg).frame(width: 40, height: 40)
                    Image(systemName: icon).font(.system(size: 16)).foregroundStyle(iconFg)
                }
                Text(title).font(SoberTheme.body()).foregroundStyle(SoberTheme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(SoberTheme.textSecondary)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    
    private func setWeekends() {
        lockdownManager.setAllDays(active: false)
        lockdownManager.toggleDay(1)
        lockdownManager.toggleDay(7)
    }
    
    private func enforceMinimumGap(changedStart: Bool) {
        let startMinutes = lockdownManager.lockStartHour * 60 + lockdownManager.lockStartMinute
        let endMinutes = lockdownManager.lockEndHour * 60 + lockdownManager.lockEndMinute
        let gap = endMinutes > startMinutes ? endMinutes - startMinutes : (24 * 60 - startMinutes) + endMinutes
        if gap < minimumGapMinutes {
            if changedStart {
                let newEnd = (startMinutes + minimumGapMinutes) % (24 * 60)
                lockdownManager.lockEndHour = newEnd / 60; lockdownManager.lockEndMinute = newEnd % 60
                endTime = Calendar.current.date(bySettingHour: lockdownManager.lockEndHour, minute: lockdownManager.lockEndMinute, second: 0, of: Date()) ?? Date()
            } else {
                var newStart = endMinutes - minimumGapMinutes
                if newStart < 0 { newStart += 24 * 60 }
                lockdownManager.lockStartHour = newStart / 60; lockdownManager.lockStartMinute = newStart % 60
                startTime = Calendar.current.date(bySettingHour: lockdownManager.lockStartHour, minute: lockdownManager.lockStartMinute, second: 0, of: Date()) ?? Date()
            }
        }
    }
}
