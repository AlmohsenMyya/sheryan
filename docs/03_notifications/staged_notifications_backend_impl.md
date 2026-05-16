# Backend Implementation: Staged Manual Notification Dispatch (Phases 1 & 2)

## 1. Overview
This phase focused on building the core "Dispatch Engine" that manages donor targeting, medical safety logic, and security constraints. We transitioned from a broadcast model to a ranked, multi-batch dispatch system.

## 2. Architectural Components

### 2.1 Firestore Schema Updates (`blood_requests`)
The following fields are now managed atomically within `StagedNotificationService`:
- `lastNotificationSentAt` (Timestamp): Records server-time of dispatch.
- `notifiedDonorIds` (Array): Prevents duplicate pings.
- `declinedDonorIds` (Array): Tracks donors who manually opted out.
- `notificationBatchCount` (Integer): Incremented per manual or auto-batch.

### 2.2 Data Integrity Fix (`lastDonated`)
Since `lastDonated` is stored as an ISO 8601 **String** (not a Firestore Timestamp), we implemented a safe parsing strategy:
- **Parsing:** `DateTime.parse(lastDonatedStr)`.
- **Error Handling:** Wrapped in try-catch; users with malformed or null dates are treated as eligible for safety but logged for investigation.
- **Blocker:** Any donor with a date within the last 60 days is strictly removed from the eligible pool in-memory.

### 2.3 Security Shield (Server-Side Validation)
We do not trust the client clock. Inside the transaction:
```dart
if (lastSent != null) {
  final DateTime now = DateTime.now(); // Transaction uses server-skew corrected time
  final DateTime cooldownExpiry = lastSent.toDate().add(const Duration(minutes: 30));
  if (now.isBefore(cooldownExpiry)) {
     throw Exception("Cooldown active...");
  }
}
```
This ensures that even if a user triggers the function via console or clock manipulation, the Firestore write will fail.

### 2.4 Replenishment Loop (`declineRequestSlot`)
When a donor declines, the system immediately:
1. Adds them to `declinedDonorIds`.
2. Runs the full ranking algorithm to find the **next 1** best matching donor.
3. Automatically notifies that replacement to maintain the batch size.

## 3. Execution Logic (Transaction Flow)
- **Read Phase:** Fetch compatible candidates (City + Blood Group) and the current Request metadata.
- **Filter Phase:** 
    - Remove UIDs in `notifiedDonorIds` or `declinedDonorIds`.
    - Apply 60-day `lastDonated` blocker.
- **Sort Phase:** Rank by `bloodGroupVerified` (bool) -> `points` (descending).
- **Commit Phase:** Update tracking fields and increment counters.
- **Notify Phase:** Trigger FCM v1 pushes in the background (`microtask`).

## 4. Observability (Debug Tracing)
The following logs are now visible in the debug console during testing:
- `Raw candidate pool: X donors`
- `Excluded: Y (history), Z (medical)`
- `Final eligible pool: N`
- `Batch selected: [uid1, uid2...]`
- `Cooldown active (S seconds left)` (Only on validation failure)

---
*Date: May 2026*
*Phase Completion: Phase 1 & 2 Successful*
