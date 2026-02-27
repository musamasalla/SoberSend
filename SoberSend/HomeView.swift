import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(StoreManager.self) private var storeManager
    
    @State private var activeTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SoberTheme.background.ignoresSafeArea()
            
            // Content area — NO swipe gesture, tabs switch via taps only
            Group {
                switch activeTab {
                case 0: SetupView()
                case 1: NavigationStack { MorningReportView() }
                case 2: NavigationStack { StatsView() }
                case 3: NavigationStack { SettingsView() }
                default: SetupView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Push content above tab bar
            .padding(.bottom, 56)
            
            SoberTabBar(selectedTab: $activeTab)
        }
        .preferredColorScheme(.light)
    }
}
