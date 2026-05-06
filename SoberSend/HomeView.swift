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

            VStack(spacing: 0) {
                // Warning banner for DeviceActivity errors
                if let errorMessage = lockdownManager.deviceActivityErrorMessage {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                         .accessibilityLabel("Warning")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Screen Time Required")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                        Button(action: {
                            withAnimation(reduceMotion ? nil : .default) {
                                lockdownManager.dismissDeviceActivityError()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        }
                        .accessibilityLabel("Dismiss warning")
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
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
                Spacer(minLength: 0)
            }

            SoberTabBar(selectedTab: $activeTab)
        }
    }
}