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
                    .navigationTitle("Lockdown 🔒")
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
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(1)
            
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .familyActivityPicker(isPresented: $isPresented, selection: Bindable(lockdownManager).selectionToDiscourage)
        .preferredColorScheme(.dark)
    }
}
