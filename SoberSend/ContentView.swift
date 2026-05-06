//
//  ContentView.swift
//  SoberSend
//
//  Created by Musa Masalla on 2026/02/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var hasCompletedOnboarding: Bool = false
    @AppStorage("isRequestingAppUnlock", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var isRequestingAppUnlock: Bool = false
    @AppStorage("isRequestingEmergencyUnlock", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var isRequestingEmergencyUnlock: Bool = false
    @State private var showLockoutExpiredChallenge: Bool = false
    @AppStorage("soberNote", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var globalSoberNote: String = ""
    
    // Inject Managers for children
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(ChallengeManager.self) private var challengeManager
    @Environment(StoreManager.self) private var storeManager
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(EmergencyUnlockManager.self) private var emergencyManager

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else {
                HomeView()
            }
        }
        .environment(lockdownManager)
        .environment(challengeManager)
        .environment(storeManager)
        .environment(notificationManager)
        .environment(emergencyManager)
        .fullScreenCover(isPresented: $isRequestingAppUnlock) {
            ChallengeCoordinatorView(
                contactOrAppName: "Restricted App",
                difficulty: .expert,
                soberNote: globalSoberNote.isEmpty ? nil : globalSoberNote
            ) { passed in
                if passed {
                    lockdownManager.activateBypass(duration: 300)
                }
                isRequestingAppUnlock = false
            }
            .environment(lockdownManager)
            .environment(challengeManager)
            .environment(storeManager)
            .environment(notificationManager)
            .environment(emergencyManager)
        }
        .fullScreenCover(isPresented: $showLockoutExpiredChallenge) {
            ChallengeCoordinatorView(
                contactOrAppName: "Restricted App",
                difficulty: .medium,
                soberNote: globalSoberNote.isEmpty ? nil : globalSoberNote
            ) { passed in
                if passed {
                    lockdownManager.activateBypass(duration: 300)
                }
                showLockoutExpiredChallenge = false
            }
            .environment(lockdownManager)
            .environment(challengeManager)
            .environment(storeManager)
            .environment(notificationManager)
            .environment(emergencyManager)
        }
        .sheet(isPresented: $isRequestingEmergencyUnlock) {
            EmergencyUnlockView()
                .environment(lockdownManager)
                .environment(challengeManager)
                .environment(storeManager)
                .environment(notificationManager)
                .environment(emergencyManager)
        }
        .onAppear {
            if isRequestingAppUnlock || isRequestingEmergencyUnlock {
                notificationManager.registerNotificationCategories()
            }
            if let shared = UserDefaults(suiteName: "group.com.musamasalla.SoberSend"),
               shared.bool(forKey: "lockoutExpiredDeepLink") {
                shared.set(false, forKey: "lockoutExpiredDeepLink")
                showLockoutExpiredChallenge = true
                notificationManager.registerNotificationCategories()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: LockedContact.self, inMemory: true)
}
