//
//  SoberSendApp.swift
//  SoberSend
//
//  Created by Musa Masalla on 2026/02/26.
//

import SwiftUI
import SwiftData

@main
struct SoberSendApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LockedContact.self,
            ChallengeAttempt.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var emergencyManager = EmergencyUnlockManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .environment(emergencyManager)
    }
}
