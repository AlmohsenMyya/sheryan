# Implementation Log: Staged Manual Notification Dispatch

## 1. Feature Overview
The "Staged Manual Notification Dispatch" feature replaces the global broadcast pattern with a controlled, multi-batch approach. This prevents notification fatigue among donors and allows recipients to gradually reach out to more matching donors if initial responses are insufficient.

## 2. Technical Architectural Flow
1. **Trigger:** Hospital Admin verifies a request.
2. **Initial Batch:** System automatically picks the "Top 10" donors and notifies them.
3. **Cooldown:** A 30-minute cooldown period is enforced before the next batch can be sent.
4. **Manual Dispatch:** Recipient can manually trigger subsequent batches of 10 donors each after the cooldown expires.

## 3. Database Schema Changes (`blood_requests` collection)
- **`lastNotificationSentAt` (Timestamp):** Tracks when the most recent batch was dispatched.
- **`notifiedDonorIds` (Array<String>):** Stores unique UIDs of notified donors to prevent duplicate pings.
- **`notificationBatchCount` (Number):** Total number of batches sent.
- **`isVerified` (Boolean):** The feature is only active for verified requests.

## 4. Backend Logic: `StagedNotificationService`
Located in `lib/services/staged_notification_service.dart`, the service handles:
- **[Security] Cooldown Validation:** Inside the Firestore Transaction, the service compares the current server time with `lastNotificationSentAt`. It strictly throws an exception if 30 minutes haven't passed, preventing UI-bypass attacks.
- **Candidate Pool Fetching:** Queries compatible blood types in the request's city.
- **In-Memory Filtering (Hard Blocker):** 
    - Excludes donors who donated in the last **60 days**.
    - Excludes donors already present in `notifiedDonorIds`.
- **Ranking System:** 
    1. **Verified Donors** (`bloodGroupVerified == true`) take priority.
    2. **User Tier** (based on `points`) is the secondary sort factor (Platinum > Gold > Silver > Bronze).
- **Atomic Dispatch:** Uses a **Firestore Transaction** to ensure data integrity during the selection and marking process.
- **Direct Messaging:** Fires direct FCM v1 pushes to the selected batch.

## 5. UI & State Management: `StagedCooldownBanner`
- **Localization:** All UI states and button labels are fully localized using `AppLocalizations` (supporting AR/EN).
- **Real-time Monitoring:** Uses `requestStreamProvider` (Riverpod `StreamProvider.family`) to monitor the request document.
- **Live Countdown:** A `Timer.periodic` calculates the remaining cooldown by comparing the current local time with the server-side `lastNotificationSentAt`.
- **Button States:**
    - **Cooldown Active:** Shows time remaining (MM:SS).
    - **Ready:** Enabled button "Notify 10 More Donors".
    - **Loading:** Circular indicator during async dispatch.
    - **Pool Exhausted:** Disabled button "All compatible donors notified".
- **Visibility Guards:** Banner is hidden if the request status is `done` or `completed`, or if it hasn't been verified by a hospital yet.

## 6. Testing & Debugging (Phase 1)
To ensure visibility during the initial deployment phase, the system includes extensive debug logging:
- Logs raw candidate counts from Firestore vs. filtered counts.
- Logs specific reasons for exclusion (medical blocker vs. already notified).
- Logs backend cooldown validation results and remaining seconds.
- Logs the final ranked UID list selected for each batch.

## 7. Edge Case Handling
- **Empty/Small Pools:** If fewer than 10 donors remain, the system notifies all remaining matches. If 0 remain, the "Exhausted" state is triggered.
- **Time Drift:** The countdown logic relies on the difference between two timestamps (target and now), ensuring survival across app restarts. The backend verification ensures security regardless of device clock discrepancies.
- **Offline Mode:** UI actions are disabled if the device has no internet connection.

---
*Date: May 2026*
*Status: Feature Fully Deployed with Security Hardening*
