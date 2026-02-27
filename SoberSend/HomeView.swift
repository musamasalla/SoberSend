import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(StoreManager.self) private var storeManager
    
    @State private var isPresented = false
    @State private var activeTab = 0
    @State private var showIntentions = false
    @State private var showPaywallForApps = false
    
    private let freeAppLimit = 1
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SoberTheme.background.ignoresSafeArea()
            
            TabView(selection: $activeTab) {
                NavigationStack {
                    SetupView(showAppPicker: $isPresented)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button { showIntentions = true } label: {
                                    Image(systemName: "pencil.and.outline")
                                        .foregroundStyle(SoberTheme.lavenderText)
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
            
            SoberTabBar(selectedTab: $activeTab)
        }
        .familyActivityPicker(isPresented: $isPresented, selection: Bindable(lockdownManager).selectionToDiscourage)
        .onChange(of: isPresented) { _, presented in
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
        .preferredColorScheme(.light)
    }
}
