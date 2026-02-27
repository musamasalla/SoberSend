import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(StoreManager.self) private var storeManager
    
    @State private var activeTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SoberTheme.background.ignoresSafeArea()
            
            TabView(selection: $activeTab) {
                SetupView()
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
        .preferredColorScheme(.light)
    }
}
