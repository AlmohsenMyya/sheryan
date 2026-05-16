# 📑 Audit Report: Donor UX Locking & Decentralized Replenishment

## 1. Decentralized Replenishment Audit (`declineRequestSlot`)

### 1.1 Current Architecture Verification
**Logic Check:** Our implementation in `StagedNotificationService.declineRequestSlot` follows the "Device-as-Orchestrator" pattern. 
*   **Transaction Integrity:** The method correctly wraps the metadata updates (`declinedDonorIds`, `notifiedDonorIds`) and the replacement search within a single Firestore transaction.
*   **Side-Effect Handling:** We have already successfully refactored this method to return the `replacementDonor` **outside** the transaction block. The FCM push is triggered only after the transaction commits successfully.
*   **Conclusion:** The replenishment engine is technically sound and adheres to cloud concurrency standards.

---

## 2. UI Locking & Dead States Analysis (`RequestResponseScreen`)

### 2.1 The Problem: "The Ghost Alert"
Donors can currently interact with requests that are either already fulfilled or that they have previously declined (via old notification entries). This creates data inconsistency and a poor user experience.

### 2.2 Proposed UI Repair Logic
We will implement a "State Lock" inside the `build` method of `RequestResponseScreen` based on the fetched `_requestData`.

#### Scenario A: The "Declined" Lock
*   **Condition:** `declinedDonorIds.contains(currentUser.uid)`.
*   **UI Change:** Hide the [Accept / Decline] row.
*   **Feedback:** Show a localized info banner: *"You have declined this request."*

#### Scenario B: The "Completed" Lock
*   **Condition:** `status == 'done'` or `status == 'completed'`.
*   **UI Change:** Hide the [Accept / Decline] row.
*   **Feedback:** Show a localized success banner: *"This request has been successfully fulfilled."*

---

## 3. Localization Requirements (ARB Updates)

To support the locked states, we need the following keys:
- `requestAlreadyDeclined`: "You have already declined this request."
- `requestAlreadyFulfilled`: "This request has been successfully fulfilled. Thank you!"

---

## 4. Logical Execution Steps

1.  **Refactor `RequestResponseScreen`:** Inject a new helper method `_buildActionArea()` that evaluates the current user's relation to the request and its global status.
2.  **State Management Integration:** Use `FirebaseAuth.instance.currentUser?.uid` to perform the "Declined" check against the `declinedDonorIds` array fetched from Firestore.
3.  **UI Feedback:** Replace the buttons with descriptive alert containers when locked.

---
*Status: Audit Complete. Ready for Implementation.*
