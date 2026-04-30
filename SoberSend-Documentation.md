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

---

## 1. Architecture Overview

SoberSend is a **native iOS app** built entirely in **SwiftUI** (with some UIKit interop via `UIViewControllerRepresentable` for contact picking). It follows a **multi-target Xcode project structure** with one main app target and three app extensions:

```
┌─────────────────────────────────────────────────────────────┐
│                    SoberSend (Main App)                   │
│                 SwiftUI + SwiftData + StoreKit              │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Widget    │    │  ShieldAction    │    │  ShieldConfig   │
│  Extension  │    │    Extension      │    │   Extension     │
│ (Timeline)  │    │ (Unlock Request)  │    │ (Shield UI)     │
└─────────────┘    └──────────────────┘    └─────────────────┘
```

**Architecture Pattern:** `@Observable` Managers with SwiftUI Environment injection (no Combine-based architecture). The main app uses `@MainActor` actors for thread safety.

---

## 2. Project Structure

```
iOS/SoberSend/
├── SoberSend/                          # Main app target
│   ├── SoberSendApp.swift               # @main entry point, ModelContainer setup
│   ├── ContentView.swift                 # Root view router (onboarding → home)
│   ├── HomeView.swift                    # Tab container (4 tabs)
│   │
│   ├── Screens/
│   │   ├── SetupView.swift              # Lock targets (apps/contacts) management
│   │   ├── MorningReportView.swift      # Daily morning summary
│   │   ├── StatsView.swift               # Progress tracking & achievements
│   │   ├── SettingsView.swift           # Schedule, appearance, about
│   │   ├── OnboardingView.swift         # 6-step onboarding flow
│   │   ├── IntentionsView.swift          # Set sober notes before going out
│   │   ├── PaywallView.swift             # Premium subscription UI
│   │   └── EmergencyUnlockView.swift    # Face ID emergency bypass
│   │
│   ├── Challenges/
│   │   ├── ChallengeCoordinatorView.swift    # Multi-stage challenge orchestrator
│   │   ├── MathChallengeView.swift             # Math problem challenge
│   │   ├── MemoryChallengeView.swift           # Color sequence memory challenge
│   │   └── SpeechChallengeView.swift          # Tongue twister speech recognition
│   │
│   ├── Models/
│   │   ├── LockedContact.swift           # SwiftData @Model
│   │   └── ChallengeAttempt.swift       # SwiftData @Model
│   │
│   ├── Managers/
│   │   ├── LockdownManager.swift        # Screen Time / ManagedSettings API
│   │   ├── ChallengeManager.swift        # Speech recognition for challenges
│   │   ├── StoreManager.swift           # StoreKit 2 subscription management
│   │   ├── NotificationManager.swift   # UNUserNotificationCenter wrapper
│   │   ├── EmergencyUnlockManager.swift  # Face ID / cooldown logic
│   │   ├── SoundManager.swift            # System sound playback
│   │   └── HapticManager.swift          # UIFeedbackGenerator wrapper
│   │
│   ├── Views/
│   │   ├── SoberTheme.swift            # Complete design system
│   │   └── ContactPickerView.swift     # CNContactPickerViewController wrapper
│   │
│   └── Assets.xcassets/                # Colors, app icon
│
├── SoberSendWidget/                     # Widget extension target
│   ├── SoberSendWidgetBundle.swift      # @main WidgetBundle
│   ├── SoberSendWidget.swift             # StaticConfiguration + Provider
│   └── Assets.xcassets/
│
├── SoberSendShieldAction/               # Shield action extension target
│   └── ShieldActionExtension.swift     # ShieldActionDelegate
│
└── SoberSendShieldConfig/              # Shield configuration extension target
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
2. `LockdownManager.setShieldRestrictions()` applies `ManagedSettingsStore` shields
3. `DeviceActivityCenter.startMonitoring()` schedules background monitoring for the time window
4. When a shielded app is opened → **ShieldActionExtension** intercepts
5. Extension sets a flag in shared `UserDefaults` (App Group) → `isRequestingAppUnlock`
6. Main app detects flag → presents `ChallengeCoordinatorView` full-screen

### 3.3 Challenge System

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

### 3.4 Emergency Unlock

Face ID / Touch ID / passcode authentication → 5-minute bypass. **24-hour cooldown** enforced via `emergencyCooldownEndTime` in shared UserDefaults.

### 3.5 Contacts Lock

Apps cannot directly block iMessage contacts on iOS. Instead:
- User picks contacts from address book
- `LockedContact` records stored in SwiftData
- When user tries to **remove** a locked contact (and lockdown is active), `ChallengeCoordinatorView` appears first
- This makes removal require passing the challenge — a friction that prevents impulsive un-blocking

### 3.6 Morning Report

Scheduled daily 8 AM local notification. Shows:
- Number of blocked attempts from previous night
- Current streak (consecutive nights without a successful unlock)
- Shareable card image (Premium)

### 3.7 Statistics & Achievements

- **Disasters Averted:** Total failed unlock attempts
- **Current Streak:** Consecutive days with no successful unlocks
- **Achievements:** 5 badges (First Save, 7-Night Streak, 30-Night Streak, Survived Weekend, Ex-Free Zone)
- All attempts logged as `ChallengeAttempt` records in SwiftData

### 3.8 Premium Subscription

**StoreKit 2** with two auto-renewable products:
- Monthly: `com.sobersend.premium.monthly`
- Yearly: `com.sobersend.premium.yearly` (includes 7-day free trial)

**Free tier limits:**
- 1 app locked maximum
- 1 contact locked maximum
- Easy/Medium challenge difficulties only
- Last 3 attempts shown in stats

**Premium unlocks:**
- Unlimited apps & contacts
- All difficulty levels (Hard, Expert)
- Full stats history
- Morning report card sharing
- All achievements

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
| Notifications | `UserNotifications` (local notifications) |
| Haptics | `UIFeedbackGenerator` |
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

---

## 6. Data Models

### 6.1 LockedContact (SwiftData @Model)

```swift
@Model
final class LockedContact {
    var contactID: String           // CNContact identifier
    var displayName: String        // Formatted full name
    var difficultyRawValue: String // ChallengeDifficulty raw value
    var soberNote: String?         // Per-contact sober note
    var lockScheduleStart: Date    // Per-contact schedule (reserved)
    var lockScheduleEnd: Date      // Per-contact schedule (reserved)
    var isActive: Bool             // Whether lock is currently enabled
}
```

### 6.2 ChallengeAttempt (SwiftData @Model)

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

### 6.3 Enums

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

Central manager for Screen Time API integration.

**Key Properties:**
- `isAuthorized: Bool` — FamilyControls authorization status
- `selectionToDiscourage: FamilyActivitySelection` — Selected apps/categories
- `isManuallyActivated: Bool` — Manual override toggle
- `activeDaysMask: Int` — Bitmask (bits 0–6 = Sun–Sat)
- `lockStartHour/Minute`, `lockEndHour/Minute` — Schedule times
- `bypassEndTime: Date?` — When temporary bypass expires

**Key Methods:**
- `requestAuthorization()` — Async FamilyControls auth request
- `setShieldRestrictions()` — Applies ManagedSettings shields
- `clearRestrictions()` — Removes all shields
- `isAppBlockingActive()` — Returns `true` if in locked window OR manually activated
- `isCurrentlyInLockedWindow()` — Checks time + day bitmask
- `activateBypass(duration:)` — Temporarily clears shields

**Storage:** All settings persisted via `UserDefaults(suiteName: "group.com.musamasalla.SoberSend")`

### 7.2 ChallengeManager

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

### 7.3 StoreManager

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

### 7.4 NotificationManager

UNUserNotificationCenter wrapper with delegate.

**Key Methods:**
- `requestAuthorization()` — Prompts for notification permission
- `scheduleMorningReport(at:minute:)` — Repeating 8 AM daily notification
- `cancelMorningReport()`
- `sendAppUnlockNotification()` — Called by main app when shield extension sets flag
- `registerNotificationCategories()` — Registers `APP_UNLOCK` category with actions
- `userNotificationCenter(didReceive:)` — Handles "Take Challenge" notification action

**Categories:**
- `APP_UNLOCK` with actions: `TAKE_CHALLENGE` (foreground), `DISMISS` (destructive)

### 7.5 EmergencyUnlockManager

Face ID emergency bypass with 24-hour cooldown.

**Key Properties:**
- `isEmergencyUnlocked: Bool`
- `emergencyUnlockEndTime: Date?`
- `emergencyCooldownEndTime: Date?` — Persisted to UserDefaults

**Key Methods:**
- `attemptEmergencyUnlock(completion:)` — `LAContext` biometric/passcode auth → activates 5-min bypass + starts 24h cooldown

### 7.6 SoundManager & HapticManager

Singleton wrappers for `AudioServicesPlaySystemSound` and `UINotificationFeedbackGenerator`/`UIImpactFeedbackGenerator`.

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

### 8.3 Component Library

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
        }
    }
}
```

Child views access managers via:
```swift
@Environment(LockdownManager.self) private var lockdownManager
@Environment(StoreManager.self) private var storeManager
// etc.
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

### 12.3 Running on Device

Screen Time API (`ManagedSettings`, `DeviceActivity`) requires a **Personal Team** provisioning profile to work at all — the FamilyControls entitlement is restricted. On simulator, the Shield Extensions compile but cannot be tested without proper provisioning.

### 12.4 Scheme Configuration

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

Simulator supports local notifications. Trigger via:
```swift
UNUserNotificationCenter.current().add(request) { error in ... }
```

### 13.4 StoreKit Testing

Use `Product.products(for:)` with a valid StoreKit config file. For sandbox testing, you'll need:
- App Store Connect sandbox account
- TestFlight build OR
- StoreKit in Xcode with sandbox mode enabled in Settings → Developer → External Updates

### 13.5 Key Debug Strings

| String | Location | Meaning |
|--------|----------|---------|
| `⚠️ SoberSend: Could not create...` | SoberSendApp | Schema migration fallback |
| `🛒 StoreManager: loaded N products` | StoreManager | Product load success |
| `❌ StoreManager: Product request failed` | StoreManager | IAP fetch failure |
| `Successfully started monitoring schedule` | LockdownManager | DeviceActivity started |

---

## Appendix A: Entitlements Summary

All four targets need these entitlements:

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
| `NSFaceIDUsageDescription` | "SoberSend uses Face ID for emergency unlock authentication." | Face ID prompt |
| `NSSpeechRecognitionUsageDescription` | "SoberSend uses speech recognition to verify you're sober during unlock challenges." | Speech recognition prompt |
| `NSContactsUsageDescription` | "SoberSend needs contacts access to add people to your lock list." | Contacts prompt |

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

---

*Documentation generated from source code analysis. Last updated: April 2026.*