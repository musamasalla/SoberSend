import LocalAuthentication
import Foundation
import SwiftUI

@Observable
class EmergencyUnlockManager {
    var isEmergencyUnlocked: Bool = false
    var emergencyUnlockEndTime: Date? = nil
    var emergencyCooldownEndTime: Date? = nil
    
    // 5 minute unlock, 24 hour cooldown after use
    private let unlockDuration: TimeInterval = 5 * 60
    private let cooldownDuration: TimeInterval = 24 * 60 * 60
    
    func attemptEmergencyUnlock(completion: @escaping (Bool, String?) -> Void) {
        if let cooldownEnd = emergencyCooldownEndTime, Date() < cooldownEnd {
            let formatter = RelativeDateTimeFormatter()
            let timeRemaining = formatter.localizedString(for: cooldownEnd, relativeTo: Date())
            completion(false, "Emergency Unlock is on cooldown. Available \(timeRemaining).")
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is possible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to trigger Emergency Unlock (5 minutes)."
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.activateEmergencyUnlock()
                        completion(true, nil)
                    } else {
                        completion(false, authenticationError?.localizedDescription ?? "Authentication failed.")
                    }
                }
            }
        } else {
            // Fallback to passcode if biometrics aren't available
            let reason = "Authenticate with passcode to trigger Emergency Unlock."
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.activateEmergencyUnlock()
                        completion(true, nil)
                    } else {
                        completion(false, authenticationError?.localizedDescription ?? "Authentication failed.")
                    }
                }
            }
        }
    }
    
    private func activateEmergencyUnlock() {
        let now = Date()
        isEmergencyUnlocked = true
        emergencyUnlockEndTime = now.addingTimeInterval(unlockDuration)
        emergencyCooldownEndTime = now.addingTimeInterval(cooldownDuration)
        
        // Auto-lock after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + unlockDuration) { [weak self] in
            self?.isEmergencyUnlocked = false
        }
    }
}
