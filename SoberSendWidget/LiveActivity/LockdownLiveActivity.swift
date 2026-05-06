import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct LockdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LockdownActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.mint)
                        Text(context.attributes.scheduleStartTime)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.orange)
                        Text(context.attributes.scheduleEndTime)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        if context.state.isInLockWindow {
                            Text(timerInterval: Date()...context.state.lockEndTime, countsDown: true)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                            Text("until unlock")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Unlocked")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.mint)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(context.state.isInLockWindow ? "App lock active, unlocks at " + context.attributes.scheduleEndTime : "Apps are unlocked")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        if context.state.lockedAppsCount > 0 {
                            Label("\(context.state.lockedAppsCount)", systemImage: "app.badge.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        if context.state.streakNights > 0 {
                            Label("\(context.state.streakNights) nights", systemImage: "flame.fill")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            } compactLeading: {
                ZStack {
                    Circle()
                        .fill(context.state.isInLockWindow ? Color.mint.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 24, height: 24)
                    Image(systemName: context.state.isInLockWindow ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(context.state.isInLockWindow ? .mint : .orange)
                }
            } compactTrailing: {
                if context.state.isInLockWindow {
                    Text(timerInterval: Date()...context.state.lockEndTime, countsDown: true)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .frame(minWidth: 36)
                } else {
                    Text("Free")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.mint)
                }
            } minimal: {
                Image(systemName: context.state.isInLockWindow ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(context.state.isInLockWindow ? .mint : .orange)
            }
        }
    }
}

@available(iOS 16.1, *)
struct LockScreenLiveActivityView: View {
    var context: ActivityViewContext<LockdownActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(context.state.isInLockWindow ?
                          Color(red: 0.83, green: 0.96, blue: 0.91) :
                          Color(red: 1.0, green: 0.88, blue: 0.86))
                    .frame(width: 48, height: 48)
                Image(systemName: context.state.isInLockWindow ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(context.state.isInLockWindow ?
                                     Color(red: 0.18, green: 0.55, blue: 0.38) :
                                     Color(red: 0.70, green: 0.30, blue: 0.25))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.isInLockWindow ? "App Lock Active" : "Unlocked")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                if context.state.isInLockWindow {
                    Text("Unlocks at \(context.attributes.scheduleEndTime)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Enjoy your freedom")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                if context.state.streakNights > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                        Text("\(context.state.streakNights)-night streak")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(context.state.isInLockWindow ? "App lock active, unlocks at \(context.attributes.scheduleEndTime), \(context.state.streakNights) night streak" : "Apps are unlocked")

            Spacer()

            if context.state.isInLockWindow {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timerInterval: Date()...context.state.lockEndTime, countsDown: true)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color(red: 0.18, green: 0.55, blue: 0.38))
                    Text("remaining")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .activityBackgroundTint(Color(UIColor.systemBackground).opacity(0.9))
    }
}