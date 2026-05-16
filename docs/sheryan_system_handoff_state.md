# 🚀 Sheryan System Handoff State: Architectural Brain Dump

## 1. 🎯 Current Project Milestone: "The Notification Ecosystem Lock"
As of May 2026, the **Staged Manual Notification Dispatch** ecosystem is 100% feature-complete, security-hardened, and architecturaly stable. The legacy global broadcast model has been entirely replaced.

### ✅ Completed & Verified Components:
- **Backend Service:** `StagedNotificationService` implements atomic transactions with server-side cooldown validation (30 mins) and in-memory medical blockers (60-day rule).
- **Notification Engine:** Switched exclusively to **FCM Data-only payloads** for emergency alerts to eliminate OS-level hijacking and ensure 100% routing accuracy.
- **Routing & Deep-Linking:** Global `navigatorKey` integrated in `main.dart` with handlers for Foreground, Background, and Terminated app states.
- **Donor State Shield:** Reactive `lastEmergencyRequestIdProvider` ensures that incoming alerts update the UI instantly (via `EmergencyAlertsTab`), even if the user ignores the push notification.
- **UI Action Bridge:** In-app notification cards now feature a localized "View Details" button with strict null-safety guards on `requestId`.
- **UI Locking:** `RequestResponseScreen` prevents interaction with "Ghost Alerts" (already fulfilled or previously declined requests).
- **Phone Standardization:** Project-wide enforcement of Syrian international format (`+963`) with strict 9-digit validation and prefix-stripping logic for edits.

---

## 2. 🏛️ Core Architectural Commandments (Immutable Rules)

### 2.1 Transaction Side-Effect Separation (The "Pure" Rule)
**Rule:** NO non-idempotent side effects (FCM pushes, email triggers) inside `runTransaction` blocks.
- **Why?** Firestore transactions may retry multiple times. Placing a push trigger inside causes redundant notifications and state desyncs (e.g., triggering a cooldown exception on a retry because the previous attempt updated the timestamp).
- **Implementation:** Transactions must only calculate state and perform database updates, then return the results/lists to be processed by an async "Action Block" *outside* the transaction.

### 2.2 Routing & Payloads (The "Anti-Hijack" Rule)
**Rule:** Use pure `"data"` payloads for emergency alerts. Omit the `"notification"` block entirely.
- **Why?** Bundling a notification block allows the System OS to intercept the click, often discarding the data payload or failing to wake up the Dart background handler. Data-only payloads force the app to handle the display locally via `flutter_local_notifications`, granting us 100% control over the navigation stack.

### 2.3 UI Reactivity & Fallbacks
**Rule:** Always provide a "State-Driven" fallback for notifications.
- **Implementation:** Don't just rely on the user clicking a push. Use foreground listeners to update a global Riverpod state (`lastEmergencyRequestIdProvider`). The persistent "Emergency Alerts" tab must monitor this state to show active requests immediately upon manual app launch.

### 2.4 Localization & Null Safety
**Rule:** Zero hardcoded strings. Zero red-screen crashes.
- **Enforcement:** Strictly use `.arb` files and `AppLocalizations`. Any navigation based on a dynamic ID (like `requestId`) must have a guard checking for null/empty values, showing a SnackBar instead of crashing.

---

## 3. 📑 The Feature Lifecycle Protocol
Every new feature MUST follow this 3-tier documentation lifecycle before a single line of production code is written:
1.  `_plan.md`: Discovery, gap analysis, and technical proposal.
2.  `_blueprint.md`: Approved architectural schema, logic flows, and security measures.
3.  `_impl.md`: Granular line-by-line implementation log and unit testing results.

*Reference the central protocol in `docs/index.md` before starting any refactor.*

---

## 4. 🚀 The Next Epic: "Recipient Smart Dashboard"
The next session will focus on transforming the Recipient experience from a passive observer to an active orchestrator.

### Immediate Next Steps:
1.  **Phase 1 (Data):** Refactor user querying to create a `SmartMatchProvider`.
2.  **Phase 2 (UX):** Implement a list/map view for the Recipient to see compatible donors nearby.
3.  **Phase 3 (Bridge):** Integrate the direct "WhatsApp Bridge" allowing peer-to-peer mobilization without waiting for batch timers.

**Handoff Status: ARCHITECTURE LOCKED. READY FOR RECIPIENT EPIC.**
