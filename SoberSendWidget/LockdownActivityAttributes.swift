import ActivityKit
import Foundation

struct LockdownActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        var lockEndTime: Date
        var isInLockWindow: Bool
        var lockedAppsCount: Int
        var streakNights: Int
    }

    var scheduleStartTime: String
    var scheduleEndTime: String
}