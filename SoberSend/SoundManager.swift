import Foundation
import AudioToolbox

/// Manages playing lightweight system sounds using iOS AudioServices framework.
/// We use built-in system IDs instead of bundling custom UI sound files to keep the app size small
/// and the styling native to the Apple ecosystem.
class SoundManager {
    static let shared = SoundManager()
    
    // Some common iOS system sound IDs
    // References: https://github.com/TUNER88/iOSSystemSoundsLibrary
    
    // A soft, positive pop/click
    private let touchSoftID: SystemSoundID = 1104
    // A sharper click for typing
    private let tickID: SystemSoundID = 1103
    // A clear success chime (like a payment/AirDrop success)
    private let successID: SystemSoundID = 1007
    // A negative/error buzz/chime
    private let errorID: SystemSoundID = 1053
    // A heavier clunk/lock sound
    private let lockID: SystemSoundID = 1100
    
    private init() { }
    
    /// Play a subtle tick (good for typing numbers or flipping cards)
    func playTick() {
        AudioServicesPlaySystemSound(tickID)
    }
    
    /// Play a soft touch sound
    func playTap() {
        AudioServicesPlaySystemSound(touchSoftID)
    }
    
    /// Play a success chime
    func playSuccess() {
        AudioServicesPlaySystemSound(successID)
    }
    
    /// Play an error/failure buzz
    func playError() {
        AudioServicesPlaySystemSound(errorID)
    }
    
    /// Play a locking/clunk sound
    func playLock() {
        AudioServicesPlaySystemSound(lockID)
    }
}
