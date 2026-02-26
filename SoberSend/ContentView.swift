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
    
    // Inject Managers
    @State private var lockdownManager = LockdownManager()
    @State private var challengeManager = ChallengeManager()
    @State private var storeManager = StoreManager()
    @State private var notificationManager = NotificationManager()
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
                soberNote: "Are you sure you want to open this app?"
            ) { passed in
                if passed {
                    // Temporarily lift restrictions (for demonstration purposes this clears all shields; 
                    // a robust implementation might use ShieldConfiguration to allow specific apps)
                    lockdownManager.clearRestrictions()
                    
                    // Re-apply them after 5 minutes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
                        lockdownManager.setShieldRestrictions()
                    }
                }
                
                // Clear the flag to dismiss the sheet
                isRequestingAppUnlock = false
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: LockedContact.self, inMemory: true)
}
