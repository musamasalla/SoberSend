import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(LockdownManager.self) private var lockdownManager
    
    @State private var isPresented = false
    @State private var activeTab = 0
    @State private var showIntentions = false
    
    var body: some View {
        TabView(selection: $activeTab) {
            NavigationStack {
                SetupView(showAppPicker: $isPresented)
                    .navigationTitle(lockdownManager.isAppBlockingActive() ? "Lockdown Active 🔒" : "SoberSend 🛡️")
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: { showIntentions = true }) {
                                Label("Intentions", systemImage: "pencil.and.outline")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Lockdown", systemImage: "lock.shield")
            }
            .tag(0)
            
            NavigationStack {
                MorningReportView()
            }
            .tabItem {
                Label("Report", systemImage: "sunrise")
            }
            .tag(1)
            
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(2)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .familyActivityPicker(isPresented: $isPresented, selection: Bindable(lockdownManager).selectionToDiscourage)
        .sheet(isPresented: $showIntentions) {
            IntentionsView()
        }
        .preferredColorScheme(.dark)
    }
}
