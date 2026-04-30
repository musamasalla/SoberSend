import SwiftUI
import SwiftData
import UserNotifications
import ActivityKit
import FamilyControls
import ManagedSettings

@main
struct SoberSendApp: App {

    @State private var emergencyManager = EmergencyUnlockManager()
    @State private var notificationManager = NotificationManager()
    @State private var lockdownManager = LockdownManager()
    @State private var storeManager = StoreManager()
    @State private var challengeManager = ChallengeManager()

    private let notificationDelegate = AppNotificationDelegate.shared

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        NotificationManager.registerCategoriesOnce()
    }

    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LockedContact.self,
            ChallengeAttempt.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("⚠️ SoberSend: Could not create persistent ModelContainer: \(error). Falling back to in-memory store.")
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallbackConfig])
        }
    }()

    @AppStorage("appearanceMode", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var appearanceModeRaw: Int = 0

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(emergencyManager)
                .environment(notificationManager)
                .environment(lockdownManager)
                .environment(storeManager)
                .environment(challengeManager)
                .preferredColorScheme(appearanceMode.colorScheme)
                .onAppear {
                    handleNotificationDeepLinks()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        checkForPendingUnlockRequest()
                        startLiveActivityIfNeeded()
                    }
                }
                .onChange(of: lockdownManager.isBlockingForLiveActivity) { _, isBlocking in
                    if isBlocking {
                        startLiveActivityIfNeeded()
                    } else {
                        Task { @MainActor in
                            await LiveActivityManager.shared.endLockdownActivity()
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .environment(emergencyManager)
    }

    private func checkForPendingUnlockRequest() {
        guard let shared = UserDefaults(suiteName: "group.com.musamasalla.SoberSend") else { return }
        if shared.bool(forKey: "isRequestingAppUnlock") {
            notificationManager.registerNotificationCategories()
        }
    }

    private func handleNotificationDeepLinks() {
        guard let shared = UserDefaults(suiteName: "group.com.musamasalla.SoberSend") else { return }
        shared.set(false, forKey: "notificationDeepLink")
        shared.set(false, forKey: "lockoutExpiredDeepLink")
        shared.set(false, forKey: "morningReportDeepLink")
    }

    private func startLiveActivityIfNeeded() {
        guard !LiveActivityManager.shared.isActivityRunning else { return }
        guard lockdownManager.isAppBlockingActive() else {
            Task { @MainActor in
                await LiveActivityManager.shared.endLockdownActivity()
            }
            return
        }

        let startMinuteStr = String(format: "%02d", lockdownManager.lockStartMinute)
        let endMinuteStr = String(format: "%02d", lockdownManager.lockEndMinute)

        let startTime = "\(lockdownManager.lockStartHour):\(startMinuteStr)"
        let endTime = "\(lockdownManager.lockEndHour):\(endMinuteStr)"

        let calendar = Calendar.current
        let now = Date()
        let lockEndTime: Date
        if let endToday = calendar.date(bySettingHour: lockdownManager.lockEndHour, minute: lockdownManager.lockEndMinute, second: 0, of: now) {
            lockEndTime = endToday > now ? endToday : calendar.date(byAdding: .day, value: 1, to: endToday) ?? endToday
        } else {
            lockEndTime = calendar.date(byAdding: .hour, value: 8, to: now) ?? now
        }

        let lockedCount = lockdownManager.selectionToDiscourage.applicationTokens.count

        Task { @MainActor in
            LiveActivityManager.shared.startLockdownActivity(
                startTime: startTime,
                endTime: endTime,
                lockEndTime: lockEndTime,
                lockedAppsCount: lockedCount,
                streakNights: 0
            )
        }
    }
}