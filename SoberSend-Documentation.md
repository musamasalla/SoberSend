
## Appendix E: Production Interconnection Fixes

### Fix 1: DeviceActivity Error Propagation to UI

**Problem:** `startDeviceActivityMonitoring()` in `LockdownManager` caught all errors and returned `false`, but there was no user-facing feedback when Screen Time access was denied. The user saw "App Lock Active" but the OS wasn't actually enforcing it.

**Solution:**
- Added `deviceActivityErrorMessage: String?` to `LockdownManager` (defaults to `nil`)
- Updated `startDeviceActivityMonitoring()` to catch `NSError where error.domain == "DeviceActivity"` and map specific error codes to user-friendly messages:
  - Code 1: "Screen Time access denied. Please enable it in Settings > Screen Time."
  - Code 2: "Screen Time authorization required. Please authorize SoberSend in Settings."
- Added `dismissDeviceActivityError()` for user dismissal
- Updated `setShieldRestrictions()` to call `startDeviceActivityMonitoring()` and set/clear `deviceActivityErrorMessage` appropriately
- Added dismissible orange warning banner to `HomeView` that appears when `deviceActivityErrorMessage` is non-nil, with VoiceOver accessibility labels
- Banner uses `withAnimation` respecting `reduceMotion` preference

**Files Changed:** `LockdownManager.swift`, `HomeView.swift`

### Fix 2: StoreManager Task Retain Cycle

**Problem:** `StoreManager` stored a `Task` in `updatesTask` that ran an infinite `for await in Transaction.updates` loop. The `Task` closure captured `self` strongly, creating a retain cycle: `StoreManager` -> `Task` -> `self` (StoreManager). This was harmless in practice (StoreManager is app-lifetime) but could cause issues in previews/tests.

**Solution:**
- Removed `updatesTask` stored property entirely
- Created the `Task { for await in Transaction.updates }` without storing the reference in a property
- Since `StoreManager` is a long-lived app object, the task runs for the app lifetime; when the app is killed, the OS terminates all tasks

**File Changed:** `StoreManager.swift` (1 line removed, `updatesTask` property and assignment removed)

---

*Documentation generated from source code analysis. Last updated: April 2026.*
