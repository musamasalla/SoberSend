import ActivityKit
import Foundation

public struct LockdownActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        public var lockEndTime: Date
        public var isInLockWindow: Bool
        public var lockedAppsCount: Int
        public var streakNights: Int

        public init(
            lockEndTime: Date,
            isInLockWindow: Bool,
            lockedAppsCount: Int,
            streakNights: Int
        ) {
            self.lockEndTime = lockEndTime
            self.isInLockWindow = isInLockWindow
            self.lockedAppsCount = lockedAppsCount
            self.streakNights = streakNights
        }
    }

    public var scheduleStartTime: String
    public var scheduleEndTime: String

    public init(scheduleStartTime: String, scheduleEndTime: String) {
        self.scheduleStartTime = scheduleStartTime
        self.scheduleEndTime = scheduleEndTime
    }
}