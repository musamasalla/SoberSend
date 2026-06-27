import LocalAuthentication
import Foundation
import SwiftUI

@MainActor
@Observable
class EmergencyUnlockManager {
    var isEmergencyUnlocked: Bool = false
    var emergencyUnlockEndTime: Date? = nil
    var emergencyCooldownEndTime: Date? = nil {
        didSet {
            if let date = emergencyCooldownEndTime {
                sharedDefaults.set(date.timeIntervalSince1970, forKey: "emergencyCooldownEndTime")
            } else {
                sharedDefaults.removeObject(forKey: "emergencyCooldownEndTime")
            }
        }
    }
    
    // 5 minute unlock, 24 hour cooldown after use
    private let unlockDuration: TimeInterval = 5 * 60
    private let cooldownDuration: TimeInterval = 24 * 60 * 60
    private var unlockTask: Task<Void, Never>?
    @ObservationIgnored private var sharedDefaults = UserDefaults(suiteName: "group.com.musamasalla.SoberSend") ?? UserDefaults.standard
    
    init() {
        let cooldownTimestamp = sharedDefaults.double(forKey: "emergencyCooldownEndTime")
        if cooldownTimestamp > 0 {
            let date = Date(timeIntervalSince1970: cooldownTimestamp)
            if date > Date() {
                self.emergencyCooldownEndTime = date
            } else {
                sharedDefaults.removeObject(forKey: "emergencyCooldownEndTime")
            }
        }
        
        // Restore emergency unlock state if still within unlock window
        let unlockTimestamp = sharedDefaults.double(forKey: "emergencyUnlockEndTime")
        if unlockTimestamp > 0 {
            let unlockDate = Date(timeIntervalSince1970: unlockTimestamp)
            if unlockDate > Date() {
                self.emergencyUnlockEndTime = unlockDate
                self.isEmergencyUnlocked = true
                // Schedule the auto-reset task when restoring from persistence
                let remaining = unlockDate.timeIntervalSince(Date())
                if remaining > 0 {
                    unlockTask?.cancel()
                    unlockTask = Task { [weak self] in
                        try? await Task.sleep(for: .seconds(remaining))
                        guard let self, !Task.isCancelled else { return }
                        self.isEmergencyUnlocked = false
                        self.emergencyUnlockEndTime = nil
                        self.sharedDefaults.removeObject(forKey: "emergencyUnlockEndTime")
                    }
                }
            } else {
                sharedDefaults.removeObject(forKey: "emergencyUnlockEndTime")
            }
        }
    }
    
    func attemptEmergencyUnlock(completion: @escaping (Bool, String?) -> Void) {
        if let cooldownEnd = emergencyCooldownEndTime, Date() < cooldownEnd {
            let formatter = RelativeDateTimeFormatter()
            let timeRemaining = formatter.localizedString(for: cooldownEnd, relativeTo: Date())
            completion(false, "Emergency Unlock is on cooldown. Available \(timeRemaining).")
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        // Determine which authentication policy to use
        let canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let policy: LAPolicy = canUseBiometrics ? .deviceOwnerAuthenticationWithBiometrics : .deviceOwnerAuthentication
        let reason = canUseBiometrics 
            ? "Authenticate to trigger Emergency Unlock (5 minutes)."
            : "Authenticate with passcode to trigger Emergency Unlock."
        
        context.evaluatePolicy(policy, localizedReason: reason) { [weak self] success, authenticationError in
            DispatchQueue.main.async {
                if success {
                    self?.activateEmergencyUnlock()
                    completion(true, nil)
                } else {
                    completion(false, authenticationError?.localizedDescription ?? "Authentication failed.")
                }
            }
        }
    }
    
    private func activateEmergencyUnlock() {
        let now = Date()
        let unlockEndTime = now.addingTimeInterval(unlockDuration)
        let cooldownEndTime = now.addingTimeInterval(cooldownDuration)
        
        isEmergencyUnlocked = true
        self.emergencyUnlockEndTime = unlockEndTime
        self.emergencyCooldownEndTime = cooldownEndTime
        
        // Persist unlock end time for crash/recovery scenarios
        sharedDefaults.set(unlockEndTime.timeIntervalSince1970, forKey: "emergencyUnlockEndTime")
        sharedDefaults.set(cooldownEndTime.timeIntervalSince1970, forKey: "emergencyCooldownEndTime")
        
        // Cancel any existing unlock task
        unlockTask?.cancel()
        
        // Auto-lock after duration using modern concurrency
        unlockTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(unlockDuration))
            guard let self, !Task.isCancelled else { return }
            self.isEmergencyUnlocked = false
            self.emergencyUnlockEndTime = nil
            self.sharedDefaults.removeObject(forKey: "emergencyUnlockEndTime")
        }
    }
}
