# 🏗️ Master Blueprint: Staged Manual Notification Ecosystem

## Phase 1: Database Schema & Data Integrity
To ensure absolute tracking and unique donor targeting, the following modifications to the Firestore schema are required.

### 1.1 `blood_requests/{requestId}` Collection
- **`lastNotificationSentAt` (Timestamp):** Tracks server-side dispatch time. Essential for security validation and UI countdown.
- **`notifiedDonorIds` (Array<String>):** The "Master List" of all donors who have received a notification for this request.
- **`declinedDonorIds` (Array<String>):** UIDs of donors who explicitly tapped "Decline". These users are removed from current slots and never re-targeted for this request.
- **`notificationBatchCount` (Integer):** Tracks how many times the recipient (or hospital) has triggered a batch.

### 1.2 `users` Medical Logic (String Parsing)
- **Critical Catch:** Field `users/{uid}/lastDonated` is stored as an **ISO 8601 String** (e.g., `"2023-10-25T..."`), NOT a Timestamp.
- **Parsing Strategy:** The `StagedNotificationService` must use `DateTime.parse()` inside the filtering logic.
- **Validation:** If `null` or empty, the donor is considered eligible. If parsing fails, the donor is skipped for safety.

---

## Phase 2: Backend Engine (`StagedNotificationService`) & Security
The backend must act as the ultimate source of truth, regardless of client-side state.

### 2.1 The Dispatch Logic (`dispatchNextBatch`)
- **Ranking:** 1. Verified Status (`true` first) > 2. Tier (`points` descending).
- **Filtering:** 
    - Exclude `notifiedDonorIds` AND `declinedDonorIds`.
    - Exclude donors where `DateTime.now().difference(DateTime.parse(lastDonated)).inDays < 60`.
- **Atomic Transaction:** Perform all reads (Request Doc + Candidate Pool) inside a Firestore Transaction to prevent duplicate dispatching.

### 2.2 The Security Shield (Cooldown Validation)
- **Constraint:** Inside the transaction, read the `lastNotificationSentAt` field.
- **Validation:** Compare `Timestamp.now()` with `lastNotificationSentAt`.
- **Action:** If the difference is **< 30 minutes**, the transaction MUST throw an Exception. This prevents bypass via device-clock manipulation.

### 2.3 Observability (Testing Mode)
- **Required Logs:** 
    - `[DEBUG] Raw Pool Size: X`
    - `[DEBUG] Excluded (Medical Blocker): Y`
    - `[DEBUG] Excluded (Already Notified): Z`
    - `[DEBUG] Final Batch UIDs: [uid1, uid2...]`
    - `[DEBUG] Cooldown Validation: [Success/Failure (Remaining Secs)]`

---

## Phase 3: The Donor Flow (Routing & Landing)
Currently, donors have no specific destination for emergency alerts. This phase fixes the "Dead End" navigation.

### 3.1 Notification Deep-Linking Router
- **Location:** `main.dart` or `NotificationService` initialization.
- **Logic:** Add a handler to `FirebaseMessaging.onMessageOpenedApp`. If `data['requestId']` exists and `type == 'emergency'`, push the `RequestResponseScreen` onto the navigation stack.

### 3.2 `RequestResponseScreen` (New UI)
- **Content:** Display Hospital Name, Patient Name, Blood Group, and needed date.
- **Action 1: Accept:** Opens WhatsApp/Call (existing logic).
- **Action 2: Decline (Replenishment):** 
    - Triggers `declineRequestSlot(requestId, donorId)`.
    - The service removes the donor from the pool and immediately dispatches a notification to the **next 1** best donor.

---

## Phase 4: The Recipient Flow (UI & Cooldown)
The recipient needs a control center within their request list.

### 4.1 `StagedCooldownBanner` Component
- **State A (Active):** Button disabled, showing `MM:SS` (synced to server timestamp + 30 mins).
- **State B (Ready):** Button enabled ("Notify 10 More Donors").
- **State C (Processing):** Loading spinner.
- **State D (Exhausted):** Button disabled ("All compatible donors notified").

### 4.2 Integration Strategy
- **File:** `lib/screens/requests/requests_list_screen.dart`.
- **Visibility:** Only show if `isVerified == true` AND `status` is not `done`/`completed`.
- **Vertical Optimization:** Embed the banner inside an `ExpansionTile` or as a slim card above primary actions.

---

## Phase 5: Localization Strictness
- **Rule:** Zero hardcoded strings.
- **Requirement:** Update `app_en.arb` and `app_ar.arb` with:
    - `stagedNotifiedCount(count)`
    - `stagedCooldownTimer(time)`
    - `notifyMoreButton`
    - `allDonorsNotified`
    - `declineSuccessSnackbar`

---
*Status: Approved Blueprint*
