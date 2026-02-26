//
//  ContentView.swift
//  SoberSend
//
//  Created by Musa Masalla on 2026/02/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var hasCompletedOnboarding: Bool = false
    @AppStorage("isRequestingAppUnlock", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var isRequestingAppUnlock: Bool = false
    @AppStorage("isRequestingEmergencyUnlock", store: UserDefaults(suiteName: "group.com.musamasalla.SoberSend")) private var isRequestingEmergencyUnlock: Bool = false
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
                    // Temporarily lift restrictions via the manager
                    lockdownManager.activateBypass(duration: 300)
                }
                
                // Clear the flag to dismiss the sheet
                isRequestingAppUnlock = false
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
            // Check flags immediately in case app was killed
            if isRequestingAppUnlock || isRequestingEmergencyUnlock {
                notificationManager.registerNotificationCategories()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: LockedContact.self, inMemory: true)
}
