# Technical Execution Plan: Staged Manual Notification Dispatch

## 1. Database Schema & Architecture Changes
To track notification history and cooldowns per request, the `blood_requests` collection in Firestore requires the following additions:

### New Fields in `blood_requests/{requestId}`:
- **`lastNotificationSentAt` (Timestamp|null):** Tracks the exact time the last batch was dispatched. Initialized as `null`. Set upon hospital verification (first batch) and subsequent manual dispatches.
- **`notifiedDonorIds` (Array<String>):** Stores the UIDs of donors who have already received a notification for this specific request. This ensures strictly unique targeting in subsequent batches.
- **`notificationBatchCount` (Integer):** Tracks how many batches have been sent (useful for analytics and UI labeling).

### Architecture Alignment:
- **Service Layer:** Introduce `StagedNotificationService` to handle the heavy lifting of ranking and exclusion logic.
- **Repository Layer:** Update `RequestRepository` and its Firebase implementation to support atomic updates for the new fields.

---

## 2. Querying & Ranking Logic (The "Top 10")
Finding the "best" donors while respecting Firestore's query limitations requires a hybrid approach (Query + In-memory filtering).

### Ranking Criteria (Descending Priority):
1. **Medical Eligibility:** Blood type compatibility (via `BloodLogic.getCompatibleDonors`) and City match.
2. **Verification Status:** `bloodGroupVerified == true` donors prioritized.
3. **User Tier:** Sorted by `points` (Platinum > Gold > Silver > Bronze).
4. **Recency:** `lastDonated` (Ascending) – Prioritize donors who haven't donated recently to avoid over-burdening frequent donors.

### Execution Strategy:
1. **Fetch Candidate Pool:** Query Firestore for donors matching `city` and `bloodGroup` (whereIn compatible types).
2. **Memory Filter:** Exclude UIDs present in the request's `notifiedDonorIds` list.
3. **Batch Selection:** Sort the remaining pool by the ranking criteria and select the top 10.
4. **Atomic Update:** Use a **Firestore Transaction** to:
   - Add the 10 selected UIDs to `notifiedDonorIds`.
   - Update `lastNotificationSentAt` to `FieldValue.serverTimestamp()`.
   - Increment `notificationBatchCount`.
5. **Dispatch:** Trigger FCM v1 pushes to the selected 10 tokens.

---

## 3. UI & State Management (Riverpod)
The Recipient needs real-time feedback on the notification status and cooldown.

### State Management:
- **`NotificationCooldownProvider`:** A `StreamProvider.family` that listens to a specific request's `lastNotificationSentAt`.
  - It calculates the `Duration` remaining until the 30-minute window expires.
  - It emits a `TimerState` (Active/Expired/Idle).
- **`StagedNotificationController`:** An `AsyncNotifier` to manage the "Notify More" action, handling loading states and error reporting.

### UI Modifications:
- **`RequestsListScreen` / New `RequestDetailScreen`:**
  - **Status Banner:** Displays "Notifications sent to [X] donors".
  - **Cooldown Widget:** A linear progress bar or text countdown (e.g., "Next batch available in 14:22").
  - **Action Button:** "Notify More Donors" — Enabled only when `TimerState == Expired` and compatibility pool is not exhausted.

---

## 4. Potential Challenges & Edge Cases

### Edge Case: The "Empty Pool"
- **Scenario:** The city has fewer than 10 compatible donors, or all compatible donors have already been notified.
- **Solution:** The UI should detect when the pool is exhausted (after a query returns 0 new candidates) and change the button text to "All compatible donors notified".

### Edge Case: Time Drift
- **Scenario:** User changes their device clock to bypass the 30-minute cooldown.
- **Solution:** **Never** rely on local device time for the cooldown logic. The `NotificationCooldownProvider` must calculate the difference between the Firestore `serverTimestamp` and the current time by either fetching a "Current Time" from a lightweight Cloud Function or using the device's offset relative to the initial Firestore fetch.

### Challenge: Firestore `whereNotIn` Limits
- **Scenario:** `notifiedDonorIds` exceeds 10 items (Firestore's limit for `whereNotIn`).
- **Solution:** We will not use `whereNotIn` in the Firestore query. Instead, we query compatible donors by city and blood type and perform the "Exclusion" filtering in the application logic (Service layer) before selecting the top 10. This is efficient for batches of this size.

### Challenge: Concurrency
- **Scenario:** A user has the app open on two devices and clicks "Notify" on both simultaneously.
- **Solution:** The Firestore Transaction ensures that only one batch can be registered and dispatched for a specific timestamp, preventing duplicate notifications.
