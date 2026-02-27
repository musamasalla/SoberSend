import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(StoreManager.self) private var storeManager
    
    @State private var isPresented = false
    @State private var activeTab = 0
    @State private var showIntentions = false
    @State private var showPaywallForApps = false
    
    // Free tier limit
    private let freeAppLimit = 1
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            SoberTheme.charcoal.ignoresSafeArea()
            
            // Content
            TabView(selection: $activeTab) {
                NavigationStack {
                    SetupView(showAppPicker: $isPresented)
                        .navigationTitle(lockdownManager.isAppBlockingActive() ? "Lockdown Active" : "SoberSend")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(action: { showIntentions = true }) {
                                    Image(systemName: "pencil.and.outline")
                                        .foregroundColor(SoberTheme.lavender)
                                }
                            }
                        }
                }
                .tag(0)
                
                NavigationStack {
                    MorningReportView()
                }
                .tag(1)
                
                NavigationStack {
                    StatsView()
                }
                .tag(2)
                
                NavigationStack {
                    SettingsView()
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom tab bar
            SoberTabBar(selectedTab: $activeTab)
        }
        .familyActivityPicker(isPresented: $isPresented, selection: Bindable(lockdownManager).selectionToDiscourage)
        .onChange(of: isPresented) { _, presented in
            // Enforce free tier limit after picker closes
            if !presented && !storeManager.isPremium {
                let appCount = lockdownManager.selectionToDiscourage.applicationTokens.count
                if appCount > freeAppLimit {
                    let allowed = Set(lockdownManager.selectionToDiscourage.applicationTokens.prefix(freeAppLimit))
                    lockdownManager.selectionToDiscourage.applicationTokens = allowed
                    showPaywallForApps = true
                }
            }
        }
        .sheet(isPresented: $showIntentions) {
            IntentionsView()
        }
        .sheet(isPresented: $showPaywallForApps) {
            PaywallView()
        }
        .preferredColorScheme(.dark)
    }
}
