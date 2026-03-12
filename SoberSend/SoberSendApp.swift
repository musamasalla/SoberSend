import SwiftUI
import SwiftData
import UserNotifications

@main
struct SoberSendApp: App {
    
    @State private var emergencyManager = EmergencyUnlockManager()
    @State private var notificationManager = NotificationManager()
    @State private var lockdownManager = LockdownManager()
    @State private var storeManager = StoreManager()
    @State private var challengeManager = ChallengeManager()
    
    init() {
        // Register categories immediately on launch using the shared instance
        // Note: @State isn't accessible in init(), so we create a one-time instance
        NotificationManager.registerCategoriesOnce()
    }
    
    // Observe when app returns to foreground to check for pending unlock requests
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
            // Graceful fallback: log the error and use an in-memory store
            // This avoids a crash on schema migration during app updates
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
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        checkForPendingUnlockRequest()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .environment(emergencyManager)
    }
    
    // MARK: - App Lifecycle
    private func checkForPendingUnlockRequest() {
        // When app becomes active, check if the ShieldAction set the unlock flag
        // If so, send the unlock notification (which ContentView observes via AppStorage)
        guard let shared = UserDefaults(suiteName: "group.com.musamasalla.SoberSend") else { return }
        if shared.bool(forKey: "isRequestingAppUnlock") {
            // Flag is already set — ContentView will pick it up and show the challenge
            // Register notification categories so the notification actions work
            notificationManager.registerNotificationCategories()
        }
    }
}
