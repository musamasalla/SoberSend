# SoberSend - Comprehensive Technical Documentation

> **SoberSend** is an iOS app that helps people in recovery by locking down their most triggering apps and contacts during vulnerable hours (default: 10 PM – 7 AM), and requiring proof of sobriety via cognitive challenges before unlocking.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Project Structure](#2-project-structure)
3. [Core Features & User Flows](#3-core-features--user-flows)
4. [Technical Stack & Dependencies](#4-technical-stack--dependencies)
5. [App Extensions](#5-app-extensions)
6. [Data Models](#6-data-models)
7. [Managers & Services](#7-managers--services)
8. [Design System (SoberTheme)](#8-design-system-sobertheme)
9. [State Management](#9-state-management)
10. [App Group & Data Sharing](#10-app-group--data-sharing)
11. [Privacy & Security](#11-privacy--security)
12. [Build & Run](#12-build--run)
13. [Testing & Debugging](#13-testing--debugging)
14. [Recent Enhancements](#14-recent-enhancements)

---

## 1. Architecture Overview

SoberSend is a **native iOS app** built entirely in **SwiftUI** (with some UIKit interop via `UIViewControllerRepresentable` for contact picking). It follows a **multi-target Xcode project structure** with one main app target and three app extensions:

```
┌─────────────────────────────────────────────────────────────┐
│                    SoberSend (Main App)                      │
│         SwiftUI + SwiftData + StoreKit + ActivityKit         │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Widget    │    │  ShieldAction    │    │  ShieldConfig   │
│  Extension  │    │    Extension      │    │   Extension     │
│(Timeline+   │    │ (Unlock Request) │    │ (Shield UI)     │
│LiveActivity)│    └──────────────────┘    └─────────────────┘
└─────────────┘
```

**Architecture Pattern:** `@Observable` Managers with SwiftUI Environment injection. The main app uses `@MainActor` actors for thread safety. Live Activity state is tracked via `LockdownManager.isBlockingForLiveActivity` — a dedicated `@Observable` property updated whenever shield restrictions change.

---

## 2. Project Structure

```
iOS/SoberSend/
├── SoberSend/                          # Main app target
│   ├── SoberSendApp.swift               # @main entry point, ModelContainer setup,
│   │                                    # Live Activity lifecycle, notification delegate
│   ├── ContentView.swift                 # Root view router (onboarding → home)
│   ├── HomeView.swift                    # Tab container (4 tabs, spring transitions,
│   │                                    # respects system colorScheme)
│   │
│   ├── Screens/
│   │   ├── SetupView.swift              # Lock targets (apps/contacts) management
│   │   ├── MorningReportView.swift      # Daily morning summary
│   │   ├── StatsView.swift              # Progress tracking & achievements
│   │   ├── SettingsView.swift           # Schedule, appearance, about
│   │   ├── OnboardingView.swift          # 6-step onboarding flow
│   │   ├── IntentionsView.swift          # Set sober notes before going out
│   │   ├── PaywallView.swift             # Premium subscription UI
│   │   └── EmergencyUnlockView.swift    # Face ID emergency bypass
│   │
│   ├── Challenges/
│   │   ├── ChallengeCoordinatorView.swift   # Multi-stage challenge orchestrator
│   │   ├── MathChallengeView.swift             # Math problem challenge
│   │   ├── MemoryChallengeView.swift           # Color sequence memory challenge
│   │   └── SpeechChallengeView.swift          # Tongue twister speech recognition
│   │
│   ├── Models/
│   │   ├── LockedContact.swift           # SwiftData @Model
│   │   ├── ChallengeAttempt.swift        # SwiftData @Model
│   │   └── LockdownActivityAttributes.swift  # ActivityAttributes for Live Activity
│   │
│   ├── Managers/
│   │   ├── LockdownManager.swift         # Screen Time / ManagedSettings API + Live Activity state
│   │   ├── ChallengeManager.swift        # Speech recognition for challenges
│   │   ├── StoreManager.swift            # StoreKit 2 subscription management
│   │   ├── NotificationManager.swift     # UNUserNotificationCenter (rich categories, deep links)
│   │   ├── EmergencyUnlockManager.swift  # Face ID / cooldown logic
│   │   ├── SoundManager.swift             # System sound playback
│   │   ├── HapticManager.swift           # UIFeedbackGenerator (5 impact levels + selection)
│   │   ├── LiveActivityManager.swift     # Activity.request/update/end wrapper
│   │   └── AppNotificationDelegate.swift  # Sendable UNUserNotificationCenterDelegate
│   │
│   ├── Views/
│   │   ├── SoberTheme.swift             # Complete design system
│   │   └── ContactPickerView.swift      # CNContactPickerViewController wrapper
│   │
│   └── Assets.xcassets/                  # Colors, app icon
│
├── SoberSendWidget/                      # Widget extension target
│   ├── SoberSendWidgetBundle.swift       # @main WidgetBundle (widget + Live Activity)
│   ├── SoberSendWidget.swift              # StaticConfiguration + Provider (home screen widget)
│   ├── LockdownActivityAttributes.swift   # ActivityAttributes copy for extension target
│   └── LiveActivity/
│       └── LockdownLiveActivity.swift    # Dynamic Island + Lock Screen Live Activity
│
├── SoberSendShieldAction/                # Shield action extension target
│   └── ShieldActionExtension.swift       # ShieldActionDelegate
│
└── SoberSendShieldConfig/               # Shield configuration extension target
    └── ShieldConfigurationExtension.swift  # ShieldConfigurationDataSource
```

---

## 3. Core Features & User Flows

### 3.1 Onboarding Flow (6 Steps)

1. **Welcome** — Emotional hook, explains the problem
2. **Screen Time Access** — Requests `FamilyControls` authorization via `AuthorizationCenter.shared.requestAuthorization(for: .individual)`
3. **Lock Schedule** — Sets active nights (Sun–Sat bitmask) and time window (start/end hours)
4. **Demo Challenge** — Simple math problem to set expectations
5. **Set Intentions** — Write a "sober note" to self (shown during unlock challenges)
6. **Paywall** — Offer premium upgrade or continue with free tier

### 3.2 Lockdown Mechanism

The app uses Apple's **Screen Time API** (`FamilyControls`, `ManagedSettings`, `DeviceActivity` frameworks):

1. User selects apps/categories via `FamilyActivityPicker`
2. `LockdownManager.setShieldRestrictions()` applies `ManagedSettingsStore` shields and updates `isBlockingForLiveActivity`
3. `DeviceActivityCenter.startMonitoring()` schedules background monitoring for the time window
4. When a shielded app is opened → **ShieldActionExtension** intercepts
5. Extension sets a flag in shared `UserDefaults` (App Group) → `isRequestingAppUnlock`
6. Main app detects flag → presents `ChallengeCoordinatorView` full-screen

### 3.3 Live Activity (Dynamic Island + Lock Screen)

When lockdown is active, a Live Activity shows a real-time countdown in the Dynamic Island and on the Lock Screen:

- **Compact:** Lock icon + countdown timer
- **Expanded:** Schedule times (start/end), large countdown center, locked-apps count, streak nights
- **Lock Screen:** Lock icon + status + unlock time + countdown timer + streak badge
- Triggered automatically by `onChange(of: lockdownManager.isBlockingForLiveActivity)` in `SoberSendApp`
- Uses `LockdownActivityAttributes.ContentState(lockEndTime:isInLockWindow:lockedAppsCount:streakNights:)`
- Automatically ends when `isAppBlockingActive()` becomes `false`

### 3.4 Challenge System

Four difficulty levels determine challenge sequence length:

| Difficulty | Challenges |
|------------|-----------|
| `easy`     | Math only |
| `medium`   | Math → Memory |
| `hard`     | Math → Speech |
| `expert`   | Math → Memory → Speech |

**Math Challenge:** Random arithmetic problem (difficulty scales digit count and operators). 3 attempts.

**Memory Challenge:** Color sequence display (4–7 colors based on difficulty), then user repeats. 3 attempts.

**Speech Challenge:** Tongue twister recited aloud. `SFSpeechRecognizer` transcribes and scores word overlap against target. 85% similarity threshold required. 3 attempts.

**Lockout:** After any failed challenge → 10-minute lockout timer before retry.

**Bypass:** After passing all challenges → `LockdownManager.activateBypass(duration: 300)` clears shields for 5 minutes.

### 3.5 Emergency Unlock

Face ID / Touch ID / passcode authentication → 5-minute bypass. **24-hour cooldown** enforced via `emergencyCooldownEndTime` in shared UserDefaults.

### 3.6 Rich Notifications

Five notification categories with deep-link actions:

| Category | Trigger | Action |
|----------|---------|--------|
| `APP_UNLOCK` | Blocked app opened | `TAKE_CHALLENGE` → opens challenge |
| `EMERGENCY_UNLOCK` | Emergency flag set | `VIEW_OPTIONS` → emergency sheet |
| `LOCKOUT_EXPIRED` | Lockout timer ends | `TAKE_CHALLENGE` → opens challenge |
| `MORNING_REPORT` | 8 AM daily | Opens morning report |
| `LOCK_START` / `LOCK_END` | 15 min before lock / at unlock | Opens app |

Foreground handling via `AppNotificationDelegate` — all notifications appear as banners even when app is open.

### 3.7 Statistics & Achievements

- **Disasters Averted:** Total failed unlock attempts
- **Current Streak:** Consecutive days with no successful unlocks
- **Achievements:** 5 badges (First Save, 7-Night Streak, 30-Night Streak, Survived Weekend, Ex-Free Zone)
- All attempts logged as `ChallengeAttempt` records in SwiftData

---

## 4. Technical Stack & Dependencies

| Component | Technology |
|----------|------------|
| UI Framework | SwiftUI (iOS 17+) |
| Data Persistence | SwiftData (`@Model`, `ModelContainer`, `ModelContext`, `@Query`) |
| State Management | `@Observable` (iOS 17+ Observation framework) with `@Environment` injection |
| App Blocking | `FamilyControls`, `ManagedSettings`, `DeviceActivity` |
| Speech Recognition | `Speech` framework (`SFSpeechRecognizer`) |
| Authentication | `LocalAuthentication` (`LAContext`) |
| In-App Purchases | StoreKit 2 (`Product`, `Transaction`) |
| Notifications | `UserNotifications` (local notifications, foreground delegate, rich categories) |
| Live Activity | `ActivityKit` (iOS 16.1+; Dynamic Island + Lock Screen) |
| Haptics | `UIFeedbackGenerator` (5 impact styles + selection + alignment) |
| Audio | `AudioToolbox` (system sound IDs) |
| Contacts | `Contacts`, `ContactsUI` |
| Widgets | `WidgetKit` |
| Concurrency | Swift Concurrency (`async/await`, `@MainActor`, `Task`) |

**No third-party dependencies.** The app uses exclusively Apple frameworks.

**Minimum iOS Version:** iOS 17 (uses Observation framework `@Observable`)

**Bundle Identifiers:**
- Main app: `com.musamasalla.SoberSend`
- App Group: `group.com.musamasalla.SoberSend`
- Widget: `com.musamasalla.SberSend.SoberSendWidget`
- Shield Action: `com.musamasalla.SoberSend.ShieldAction`
- Shield Config: `com.musamasalla.SoberSend.ShieldConfiguration`

---

## 5. App Extensions

### 5.1 ShieldActionExtension (ShieldActionDelegate)

Intercepts shield actions when user taps on blocked app/website shield.

```swift
class ShieldActionExtension: ShieldActionDelegate
```

**Handles three token types:**
- `ApplicationToken` (blocked apps)
- `WebDomainToken` (blocked websites)
- `ActivityCategoryToken` (blocked categories)

**Actions:**
- `primaryButtonPressed` → Sets `isRequestingAppUnlock = true` in shared UserDefaults → sends local notification → returns `.defer`
- `secondaryButtonPressed` → Sets `isRequestingEmergencyUnlock = true` → same notification flow

**Key constraint:** Extensions cannot call `UNUserNotificationCenter.add()` directly without special entitlement. Workaround: set a shared UserDefaults flag; main app sends the notification when it wakes.

### 5.2 ShieldConfigurationExtension (ShieldConfigurationDataSource)

Provides the UI for the shield overlay that appears when a blocked app is opened.

```swift
class ShieldConfigurationExtension: ShieldConfigurationDataSource
```

Returns a `ShieldConfiguration` with:
- Dark background blur
- Lock shield icon
- Title: "App Locked"
- Subtitle explaining SoberSend + instructions
- Primary button: "Take Challenge" (blue)
- Secondary button: "Emergency" (red)

### 5.3 SoberSendWidget (WidgetKit)

Small home screen widget showing:
- Current lock status (Protected/Unprotected)
- Active time window (e.g., "22:00 – 07:00")
- Lock/unlock icon with contextual color (mint = protected, peach = unprotected)

Timeline refreshes every 15 minutes, reading schedule from shared UserDefaults.

### 5.4 LockdownLiveActivity (ActivityKit)

Live Activity shown in Dynamic Island and on Lock Screen while lockdown is active:

**ContentState fields:**
- `lockEndTime: Date` — When the lock window ends (countdown target)
- `isInLockWindow: Bool` — Whether currently in a lock window
- `lockedAppsCount: Int` — Number of apps being blocked
- `streakNights: Int` — Current streak for display

**Dynamic Island views:**
- **Compact:** Lock/unlock icon + countdown timer
- **Minimal:** Lock/unlock icon only
- **Expanded:** Schedule start/end times, large countdown center, locked-apps count, streak

**Lock Screen:** Lock icon + "App Lock Active" / "Unlocked" status + unlock time + countdown + streak badge

---

## 6. Data Models

### 6.1 LockdownActivityAttributes (ActivityKit)

Shared between main app and widget extension via two identical copies (one in each target):

```swift
struct LockdownActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var lockEndTime: Date
        var isInLockWindow: Bool
        var lockedAppsCount: Int
        var streakNights: Int
    }
    var scheduleStartTime: String  // "HH:mm"
    var scheduleEndTime: String    // "HH:mm"
}
```

### 6.2 LockedContact (SwiftData @Model)

```swift
@Model
final class LockedContact {
    var contactID: String           // CNContact identifier
    var displayName: String        // Formatted full name
    var difficultyRawValue: String // ChallengeDifficulty raw value
    var soberNote: String?         // Per-contact sober note
    var lockScheduleStart: Date    // Per-contact schedule (reserved)
    var lockScheduleEnd: Date      // Per-contact schedule (reserved)
    var isActive: Bool              // Whether lock is currently enabled
}
```

### 6.3 ChallengeAttempt (SwiftData @Model)

```swift
@Model
final class ChallengeAttempt {
    var contactOrApp: String        // Name of blocked item attempted
    var timestamp: Date            // When attempt occurred
    var passed: Bool               // Whether individual challenge passed
    var challengeTypeRawValue: String // ChallengeType raw value
    var attemptNumber: Int         // Which attempt in the sequence (1, 2, 3...)
    var unlockGranted: Bool        // Whether full sequence was passed
}
```

### 6.4 Enums

```swift
enum ChallengeDifficulty: String, Codable, CaseIterable {
    case easy, medium, hard, expert
}

enum ChallengeType: String, Codable, CaseIterable {
    case math, memory, speech, combined
}

enum AppearanceMode: Int, CaseIterable {
    case system = 0, light = 1, dark = 2
}
```

---

## 7. Managers & Services

### 7.1 LockdownManager

Central manager for Screen Time API integration and Live Activity state.

**Key Properties:**
- `isAuthorized: Bool` — FamilyControls authorization status
- `selectionToDiscourage: FamilyActivitySelection` — Selected apps/categories
- `isManuallyActivated: Bool` — Manual override toggle
- `activeDaysMask: Int` — Bitmask (bits 0–6 = Sun–Sat)
- `lockStartHour/Minute`, `lockEndHour/Minute` — Schedule times
- `bypassEndTime: Date?` — When temporary bypass expires
- `isBlockingForLiveActivity: Bool` — Observable property; source of truth for Live Activity activation. Updated by `refreshLiveActivityState()` whenever `setShieldRestrictions()` is called.

**Key Methods:**
- `requestAuthorization()` — Async FamilyControls auth request
- `setShieldRestrictions()` — Applies ManagedSettings shields, updates `isBlockingForLiveActivity`
- `clearRestrictions()` — Removes all shields
- `isAppBlockingActive()` — Returns `true` if in locked window OR manually activated
- `isCurrentlyInLockedWindow()` — Checks time + day bitmask
- `activateBypass(duration:)` — Temporarily clears shields
- `refreshLiveActivityState()` — Recomputes `isBlockingForLiveActivity`

**Storage:** All settings persisted via `UserDefaults(suiteName: "group.com.musamasalla.SoberSend")`

### 7.2 LiveActivityManager

`@MainActor @Observable` singleton that wraps `Activity<LockdownActivityAttributes>`:

```swift
@MainActor @Observable
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private(set) var isActivityRunning: Bool = false
    private var currentActivity: Activity<LockdownActivityAttributes>?

    func startLockdownActivity(startTime:endTime:lockEndTime:lockedAppsCount:streakNights:)
    func updateLockdownActivity(lockEndTime:isInLockWindow:) async
    func endLockdownActivity() async
    func endAllActivities() async  // Cleanup on app launch
}
```

Called from `SoberSendApp.onChange(of: lockdownManager.isBlockingForLiveActivity)`.

### 7.3 AppNotificationDelegate

`@MainActor @Sendable` wrapper implementing `UNUserNotificationCenterDelegate`. Handles foreground notification presentation and deep-link routing:

```swift
@MainActor
final class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = AppNotificationDelegate()

    nonisolated func userNotificationCenter(willPresent:) async -> UNNotificationPresentationOptions
    nonisolated func userNotificationCenter(didReceive:) async
}
```

Registered in `SoberSendApp.init()` via `UNUserNotificationCenter.current().delegate = notificationDelegate`.

### 7.4 NotificationManager

`@MainActor @Observable` class wrapping `UNUserNotificationCenter`. Implements rich local notifications with deep-link categories:

**Notification Categories:**
- `APP_UNLOCK` — actions: `TAKE_CHALLENGE`, `DISMISS`
- `EMERGENCY_UNLOCK` — actions: `VIEW_OPTIONS`, `DISMISS`
- `LOCKOUT_EXPIRED` — actions: `TAKE_CHALLENGE`, `DISMISS`

**Scheduling Methods:**
- `scheduleMorningReport(at:minute:)` — Repeating 8 AM daily
- `scheduleLockStartReminder(at:minute:)` — 15 minutes before lock window
- `scheduleLockEndReminder(at:minute:)` — At unlock time
- `sendStreakNotification(streakNights:)` — One-shot on streak milestones
- `sendAppUnlockNotification()` — Time-sensitive critical alert
- `sendEmergencyUnlockNotification()` — Critical alert
- `sendLockoutExpiredNotification()` — Standard alert

**Delegation:** Registers as `UNUserNotificationCenterDelegate` in `init()` to handle foreground presentation and action routing. Deep links set flags in shared `UserDefaults` for `ContentView` to pick up.

### 7.5 HapticManager

`@MainActor final class: Sendable` wrapping all `UIFeedbackGenerator` types:

```swift
@MainActor
final class HapticManager: Sendable {
    static let shared = HapticManager()

    func notification(type: UINotificationFeedbackGenerator.FeedbackType)  // success/error/warning
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle)            // light/medium/heavy/rigid/soft
    func selection()      // UISelectionFeedbackGenerator
    func alignment()     // UISelectionFeedbackGenerator (for alignment guides)
    func dragStart()     // Light impact at 0.5 intensity

    // Convenience
    func success()   // notification(.success)
    func error()      // notification(.error)
    func warning()   // notification(.warning)
    func lightTap()   // impact(.light)
    func mediumTap()  // impact(.medium)
    func heavyTap()   // impact(.heavy)
    func rigidTap()   // impact(.rigid)
    func softTap()    // impact(.soft)
}
```

All generators are `prepare()`-ed on init for minimum latency.

### 7.6 ChallengeManager

Speech recognition for the Speech Challenge.

**Key Properties:**
- `isRecording: Bool`
- `speechScore: Double` — 0.0–1.0 similarity score
- `recognizedText: String` — Live transcription
- `isAuthorizedForSpeech: Bool`

**Key Methods:**
- `startRecording(targetPhrase:)` — Begins `SFSpeechRecognizer` recognition
- `stopRecording()` — Ends session
- `calculateSimilarity(target:output:)` — Word overlap ratio

### 7.7 StoreManager

StoreKit 2 subscription management.

**Key Properties:**
- `isPremium: Bool` — Whether user has active subscription
- `products: [Product]` — Fetched App Store products
- `isLoadingProducts: Bool`
- `productsLoadError: String?`

**Key Methods:**
- `requestProducts()` — Fetches products from App Store
- `purchase(Product)` — Initiates purchase flow
- `restorePurchases()` — `AppStore.sync()` + status check
- Listens to `Transaction.updates` async stream for auto-renewal updates

### 7.8 EmergencyUnlockManager

Face ID emergency bypass with 24-hour cooldown.

**Key Properties:**
- `isEmergencyUnlocked: Bool`
- `emergencyUnlockEndTime: Date?`
- `emergencyCooldownEndTime: Date?` — Persisted to UserDefaults

**Key Methods:**
- `attemptEmergencyUnlock(completion:)` — `LAContext` biometric/passcode auth → activates 5-min bypass + starts 24h cooldown

### 7.9 SoundManager

Singleton wrapper for `AudioServicesPlaySystemSound`. Used for challenge feedback.

---

## 8. Design System (SoberTheme)

SoberTheme provides a complete adaptive design system that responds to light/dark mode.

### 8.1 Color Palette

All colors use `adaptive(light:dark:)` helper that returns `Color` from `UIColor` with trait collection support:

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `background` | #EBF5FA | #121214 | Page background |
| `card` | #FFFFFF | #1C1C1E | Card surfaces |
| `textPrimary` | #1A1A1A | #F2F2F2 | Primary text |
| `textSecondary` | #8F8F94 | #8C8C8C | Secondary text |
| `ctaBlack` | #1A1A1A | #F2F2F2 | CTA buttons (inverted) |
| `lavender*` | #E8E0F8 | #38305C | Primary accent |
| `mint*` | #D4F5EB | #1F3D2E | Success/protected |
| `peach*` | #FFEFE0 | #4D241F | Warning/unprotected |
| `cream*` | #FFF8E8 | #40381F | Warm accent |
| `blue*` | #D9EBFA | #1F2E47 | Cool accent |

### 8.2 Typography

Rounded system font at various weights:

```swift
SoberTheme.title(28)      // .bold, rounded, 28pt
SoberTheme.headline(17)    // .semibold, rounded, 17pt
SoberTheme.body(15)        // .regular, rounded, 15pt
SoberTheme.caption(12)      // .medium, rounded, 12pt
SoberTheme.mono(28)        // .bold, monospaced, 28pt
```

### 8.3 Animation

All view transitions respect `accessibilityReduceMotion`. Tab switching in `HomeView` uses `.matchedGeometryEffect` with spring animation (duration 0.35, bounce 0.2) when motion is not reduced.

### 8.4 Component Library

| Component | Purpose |
|-----------|---------|
| `SoberCardModifier` | Card with shadow and rounded corners |
| `SoberRow` | Settings-style row with icon + title + subtitle + chevron |
| `SoberPill` | Rounded badge / status pill |
| `SoberSectionHeader` | Uppercase label with optional icon |
| `SoberPrimaryButtonStyle` | Full-width CTA button with press animation |
| `SoberSecondaryButtonStyle` | Outlined CTA button |
| `SoberTabBar` | 4-tab bottom tab bar with animated pill indicator |
| `PastelAccentCard` | Card with colored background |

---

## 9. State Management

The app uses **Observation framework** (`@Observable`) with **SwiftUI Environment** for dependency injection:

```swift
@main
struct SoberSendApp: App {
    @State private var emergencyManager = EmergencyUnlockManager()
    @State private var notificationManager = NotificationManager()
    @State private var lockdownManager = LockdownManager()
    @State private var storeManager = StoreManager()
    @State private var challengeManager = ChallengeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(emergencyManager)
                .environment(notificationManager)
                .environment(lockdownManager)
                .environment(storeManager)
                .environment(challengeManager)
                .preferredColorScheme(appearanceMode.colorScheme)
                .onChange(of: lockdownManager.isBlockingForLiveActivity) { _, isBlocking in
                    if isBlocking { startLiveActivityIfNeeded() }
                    else { Task { await LiveActivityManager.shared.endLockdownActivity() } }
                }
        }
    }
}
```

**Persistence Strategy:**
- SwiftData (`ModelContainer`) for structured data: `LockedContact`, `ChallengeAttempt`
- `UserDefaults(suiteName:)` (App Group) for settings and flags shared between app and extensions
- `@AppStorage` in SwiftUI views for reactive binding to UserDefaults

---

## 10. App Group & Data Sharing

App Group `group.com.musamasalla.SoberSend` is used for cross-process communication between the main app and extensions:

| Key | Type | Purpose |
|-----|------|---------|
| `savedFamilyActivitySelection` | Data (JSON) | Encoded `FamilyActivitySelection` |
| `isManuallyActive` | Bool | Manual override state |
| `activeDaysMask` | Int | Active days bitmask |
| `lockStartHour`/`Minute` | Int | Schedule start |
| `lockEndHour`/`Minute` | Int | Schedule end |
| `bypassEndTime` | Double (timestamp) | Bypass expiration |
| `isRequestingAppUnlock` | Bool | Shield action → challenge flow |
| `isRequestingEmergencyUnlock` | Bool | Shield action → emergency flow |
| `emergencyCooldownEndTime` | Double (timestamp) | 24h emergency cooldown |
| `soberNote` | String | Global sober note |
| `hasCompletedOnboarding` | Bool | Onboarding state |
| `morningReportEnabled` | Bool | Morning notification toggle |
| `appearanceMode` | Int | 0=system, 1=light, 2=dark |
| `challengeLockoutEnd` | Double (timestamp) | Challenge lockout expiration |
| `notificationDeepLink` | Bool | Any notification tapped |
| `lockoutExpiredDeepLink` | Bool | Lockout expired notification tapped |
| `morningReportDeepLink` | Bool | Morning report notification tapped |

---

## 11. Privacy & Security

### 11.1 Data Collection

- **No analytics or third-party SDKs**
- All challenge attempts (`ChallengeAttempt`) stored locally in SwiftData on-device
- No data transmitted to any server
- Contact picker uses system `CNContactPickerViewController` — app only receives the selected contact ID/name
- Speech recognition uses on-device `SFSpeechRecognizer` (requires user permission)

### 11.2 Permissions Required

| Permission | Framework | Purpose |
|------------|-----------|---------|
| Family Controls | FamilyControls | Screen Time API for app blocking |
| Speech Recognition | Speech | Speech challenge transcription |
| Notifications | UserNotifications | Morning report + unlock alerts |
| Contacts | Contacts | Contact picker for locked contacts |

### 11.3 Emergency Unlock Security

- Requires biometric (Face ID/Touch ID) or device passcode
- 5-minute bypass is the shortest reasonable duration
- 24-hour cooldown prevents abuse
- All emergency unlocks are logged as `ChallengeAttempt` records with `unlockGranted = true`

---

## 12. Build & Run

### 12.1 Prerequisites

- Xcode 15+
- iOS 17+ Simulator or device
- Apple Developer account with Screen Time capability enabled
- App Group capability configured in signing
- StoreKit configuration file (for testing IAP in simulator)

### 12.2 StoreKit Configuration

For local testing of in-app purchases without App Store Connect:
1. Create a StoreKit Configuration File (`.storekit`) in Xcode
2. Add it to the scheme's StoreKit Configuration setting
3. Configure products in the file:
   - `com.sobersend.premium.monthly`
   - `com.sobersend.premium.yearly`

### 12.3 Live Activities

`NSSupportsLiveActivities = YES` must be set in `Info.plist` for Live Activities to function. This is already configured.

### 12.4 Running on Device

Screen Time API (`ManagedSettings`, `DeviceActivity`) requires a **Personal Team** provisioning profile to work at all — the FamilyControls entitlement is restricted. On simulator, the Shield Extensions compile but cannot be tested without proper provisioning.

### 12.5 Scheme Configuration

The Xcode project should have the SoberSend scheme configured with:
- StoreKit Configuration: select your `.storekit` file for Debug
- Signing: automatic with your development team
- App Groups: `group.com.musamasalla.SoberSend` enabled on all targets

---

## 13. Testing & Debugging

### 13.1 SwiftData Testing

Use `ModelContainer` with `isStoredInMemoryOnly: true` for test fixtures:
```swift
let container = try! ModelContainer(for: LockedContact.self, ChallengeAttempt.self, inMemory: true)
```

### 13.2 FamilyControls Testing

- Authorization status can be reset via iOS Settings → Screen Time → App Limits → tap any app → Remove Limit
- `AuthorizationCenter.shared.authorizationStatus` reflects current state
- Test the shield flow on a physical device only (extensions don't run in simulator)

### 13.3 Notification Testing

Simulator supports local notifications including foreground banners via `UNUserNotificationCenterDelegate`. Test deep links by triggering `sendAppUnlockNotification()` or `sendLockoutExpiredNotification()`.

### 13.4 Live Activity Testing

Start a Live Activity by enabling Screen Time and setting a current-time lock window in Settings. The Dynamic Island and Lock Screen widget should appear automatically. End via `LiveActivityManager.shared.endLockdownActivity()` or by disabling the lock window.

### 13.5 StoreKit Testing

Use `Product.products(for:)` with a valid StoreKit config file. For sandbox testing, you'll need:
- App Store Connect sandbox account
- TestFlight build OR
- StoreKit in Xcode with sandbox mode enabled in Settings → Developer → External Updates

### 13.6 Key Debug Strings

| String | Location | Meaning |
|--------|----------|---------|
| `⚠️ SoberSend: Could not create...` | SoberSendApp | Schema migration fallback |
| `🛒 StoreManager: loaded N products` | StoreManager | Product load success |
| `❌ StoreManager: Product request failed` | StoreManager | IAP fetch failure |
| `Successfully started monitoring schedule` | LockdownManager | DeviceActivity started |
| `Live Activity started:` | LiveActivityManager | Live Activity created |
| `Failed to start Live Activity:` | LiveActivityManager | ActivityKit not enabled |

---

## 14. Recent Enhancements

### Live Activity Countdown

The app now shows a real-time countdown timer in the Dynamic Island and Lock Screen via `LockdownLiveActivity` (iOS 16.1+). When `lockdownManager.isBlockingForLiveActivity` becomes `true`, `SoberSendApp` calls `LiveActivityManager.startLockdownActivity()`. When it becomes `false`, the activity is ended. The countdown timer uses SwiftUI's `Text(timerInterval:countsDown:)` for automatic real-time updates.

### Rich Notifications

Five notification categories (`APP_UNLOCK`, `EMERGENCY_UNLOCK`, `LOCKOUT_EXPIRED`, `MORNING_REPORT`, `LOCK_START`/`LOCK_END`) with foreground banner support via `AppNotificationDelegate`. Tapping any notification action sets deep-link flags in shared UserDefaults for `ContentView` to handle routing.

### Haptic Feedback

`HapticManager` is now `@MainActor final class: Sendable` with 5 impact levels (light, medium, heavy, rigid, soft), plus selection, alignment, drag-start, and convenience methods (success, error, warning). All generators are pre-prepared on init for zero-latency response.

### Animation Polish

`HomeView` tab transitions now use `matchedGeometryEffect` with spring animation (0.35s, bounce 0.2) disabled under `Reduce Motion`. `preferredColorScheme(.light)` hardcode removed — the app now respects system preference or the user's explicit appearance mode setting.

---

## Appendix A: Entitlements Summary

All targets need these entitlements:

| Entitlement | Targets |
|------------|---------|
| `com.apple.developer.family-controls` | All |
| `com.apple.security.application-groups` (`group.com.musamasalla.SoberSend`) | All |
| `com.apple.developer.siri` | Main |
| `aps-environment` (for push notifications) | Main |

---

## Appendix B: Info.plist Keys

| Key | Value | Purpose |
|-----|-------|---------|
| `NSFaceIDUsageDescription` | "SoberSend uses Face ID for the Emergency Unlock feature to verify your identity." | Face ID prompt |
| `NSSpeechRecognitionUsageDescription` | "SoberSend requires Speech Recognition to analyze the tongue twister challenge and verify you are sober." | Speech recognition prompt |
| `NSContactsUsageDescription` | "SoberSend needs access to your contacts so you can select which contacts to lock during your lockdown window." | Contacts prompt |
| `NSMicrophoneUsageDescription` | "SoberSend needs the microphone to listen to you reading the tongue twister challenge." | Microphone prompt |
| `NSSupportsLiveActivities` | `YES` | Enable Live Activities |

---

## Appendix C: URL Scheme

SoberSend registers the URL scheme `sobersend://` for deep linking from notifications:
- `sobersend://challenge` — Opens challenge coordinator

---

## Appendix D: Architecture Decisions

1. **Why `@Observable` over `ObservableObject`?** — iOS 17+ only, simplifies boilerplate, @MainActor-friendly.
2. **Why SwiftData over Core Data?** — Modern Swift-native API, schema migration with VersionedSchema support, CloudKit sync ready.
3. **Why system sounds over bundled audio?** — Zero app size overhead, native feel.
4. **Why StoreKit 2 over StoreKit 1?** — Async/await API, no completion handlers, automatic transaction listener.
5. **Why 85% speech similarity threshold?** — Balances tolerance for minor mispronunciations against requiring actual effort.
6. **Why 24-hour emergency cooldown?** — Long enough to prevent casual abuse, short enough to handle genuine emergencies.
7. **Why not block contacts directly in iMessage?** — Apple doesn't provide any API for this. `CNContactPickerViewController` only reads contacts; no write or block capability exists.
8. **Why bypass via notification rather than direct extension call?** — `UNUserNotificationCenter` in extensions requires a specific entitlement (`com.apple.developer.usernotifications.time-sensitive`) that has limited availability. The shared UserDefaults flag pattern is the most reliable cross-process communication mechanism.
9. **Why a separate `isBlockingForLiveActivity` property?** — `isAppBlockingActive()` is a method; `onChange` requires an `Equatable` property. A dedicated `@Observable` boolean property updated by `refreshLiveActivityState()` provides a clean, observable source of truth for both the Live Activity trigger and SwiftUI's `onChange`.
10. **Why duplicate `LockdownActivityAttributes` in both targets?** — The widget extension is a separate compilation target and cannot import the main app's module. Each target has its own copy of the struct, which is the standard pattern for App-Widget data sharing in iOS.

---

*Documentation generated from source code analysis. Last updated: April 2026.*