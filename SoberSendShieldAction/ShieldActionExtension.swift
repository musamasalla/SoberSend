import ManagedSettings
import UIKit

class ShieldActionExtension: ShieldActionDelegate {
    
    private func handleAction() -> ShieldActionResponse {
        // Find our shared group
        let sharedDefaults = UserDefaults(suiteName: "group.com.musamasalla.SoberSend")
        
        // Signal to the main app that we want to unlock an app
        sharedDefaults?.set(true, forKey: "isRequestingAppUnlock")
        
        // Unfortunately, Shield Actions Cannot directly open URLs (openURL is unavailable in app extensions).
        // BUT, returning .defer dismisses the shield momentarily so the user can open our app themselves, 
        // OR better yet, since iOS 16, they can just be told via notification.
        // As a fallback for iOS: returning `none` does nothing. `close` closes the app. `defer` defer the shield.
        // We will return `defer` so they can go to our app.
        
        return .defer
    }

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(handleAction())
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            fatalError()
        }
    }
    
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(handleAction())
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            fatalError()
        }
    }
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(handleAction())
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            fatalError()
        }
    }
}
