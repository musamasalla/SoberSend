import ManagedSettings
import ManagedSettingsUI
import UIKit

extension ManagedSettingsStore.Name {
    static let soberSend = ManagedSettingsStore.Name("com.musamasalla.SoberSend.lockdown")
}

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    private let store = ManagedSettingsStore(named: .soberSend)
    private func getSoberSendConfig() -> ShieldConfiguration {
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1.0),
            icon: UIImage(systemName: "lock.shield.fill"), // Using a system image as a fallback
            title: ShieldConfiguration.Label(text: "App Locked", color: .white),
            subtitle: ShieldConfiguration.Label(text: "SoberSend is active. Prove you're sober to unlock, or use Emergency if you're in trouble.\n\n(Swipe up to cancel and return home)", color: .lightGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Take Challenge", color: .white),
            primaryButtonBackgroundColor: UIColor.systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Emergency", color: .systemRed)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return getSoberSendConfig()
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return getSoberSendConfig()
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return getSoberSendConfig()
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return getSoberSendConfig()
    }
}
