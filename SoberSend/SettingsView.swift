import SwiftUI

struct SettingsView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(NotificationManager.self) private var notificationManager
    
    var body: some View {
        Form {
            Section("Premium Status") {
                if storeManager.isPremium {
                    HStack {
                        Text("SoberSend Premium")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                } else {
                    NavigationLink("Upgrade to Premium") {
                        PaywallView()
                    }
                }
            }
            
            Section("Notifications") {
                Toggle("Morning Report", isOn: Bindable(notificationManager).isAuthorized)
                    .disabled(true) // Readonly status in basic view, would require deep linking to Settings to change 
                Button("Test Notification") {
                    notificationManager.scheduleMorningReport(at: Calendar.current.component(.hour, from: Date()), minute: Calendar.current.component(.minute, from: Date()) + 1)
                }
            }
            
            Section("About") {
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                Text("Version 1.0.0")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Settings ⚙️")
        .preferredColorScheme(.dark)
    }
}
