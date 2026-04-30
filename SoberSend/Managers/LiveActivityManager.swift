import ActivityKit
import Foundation

@MainActor
@Observable
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private(set) var isActivityRunning: Bool = false
    private var currentActivity: Activity<LockdownActivityAttributes>?

    private init() {}

    func startLockdownActivity(
        startTime: String,
        endTime: String,
        lockEndTime: Date,
        lockedAppsCount: Int,
        streakNights: Int
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        let attributes = LockdownActivityAttributes(
            scheduleStartTime: startTime,
            scheduleEndTime: endTime
        )

        let state = LockdownActivityAttributes.ContentState(
            lockEndTime: lockEndTime,
            isInLockWindow: true,
            lockedAppsCount: lockedAppsCount,
            streakNights: streakNights
        )

        let content = ActivityContent(
            state: state,
            staleDate: lockEndTime.addingTimeInterval(60 * 30),
            relevanceScore: 80
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            currentActivity = activity
            isActivityRunning = true
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateLockdownActivity(lockEndTime: Date, isInLockWindow: Bool) async {
        guard let activity = currentActivity else { return }

        let state = LockdownActivityAttributes.ContentState(
            lockEndTime: lockEndTime,
            isInLockWindow: isInLockWindow,
            lockedAppsCount: activity.content.state.lockedAppsCount,
            streakNights: activity.content.state.streakNights
        )

        let content = ActivityContent(state: state, staleDate: lockEndTime.addingTimeInterval(60 * 30))

        await activity.update(content)

        if !isInLockWindow {
            await endLockdownActivity()
        }
    }

    func endLockdownActivity() async {
        guard let activity = currentActivity else { return }

        let finalState = LockdownActivityAttributes.ContentState(
            lockEndTime: Date(),
            isInLockWindow: false,
            lockedAppsCount: activity.content.state.lockedAppsCount,
            streakNights: activity.content.state.streakNights
        )

        let content = ActivityContent(state: finalState, staleDate: nil, relevanceScore: 0)

        await activity.end(content, dismissalPolicy: .immediate)
        currentActivity = nil
        isActivityRunning = false
    }

    func endAllActivities() async {
        for activity in Activity<LockdownActivityAttributes>.activities {
            let finalState = LockdownActivityAttributes.ContentState(
                lockEndTime: Date(),
                isInLockWindow: false,
                lockedAppsCount: 0,
                streakNights: 0
            )
            let content = ActivityContent(state: finalState, staleDate: nil)
            await activity.end(content, dismissalPolicy: .immediate)
        }
        currentActivity = nil
        isActivityRunning = false
    }
}