import SwiftUI
import FamilyControls

struct HomeView: View {
    @Environment(LockdownManager.self) private var lockdownManager
    @Environment(StoreManager.self) private var storeManager

    @State private var activeTab = 0
    @Namespace private var tabTransition

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            SoberTheme.background.ignoresSafeArea()

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
            .matchedGeometryEffect(id: "tabContent", in: tabTransition, isSource: true)
            .transition(.opacity)
            .animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.2), value: activeTab)
            .padding(.bottom, 56)

            SoberTabBar(selectedTab: $activeTab)
        }
    }
}