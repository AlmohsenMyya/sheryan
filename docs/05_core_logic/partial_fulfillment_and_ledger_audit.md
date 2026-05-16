# 📑 Architectural Audit: Partial Fulfillment & Donor Ledger Integrity

## 1. Executive Summary
This audit identifies critical logical gaps in the current "Sheryan" donation workflow. Specifically, it addresses the premature closure of blood requests (ignoring multi-unit requirements) and the vulnerability of medical cooldown periods due to unrestricted manual edits of donation dates.

---

## 2. Partial Fulfillment Engine (Incremental Unit Tracking)

### 2.1 Problem Analysis
Currently, a single donation registration triggers a binary state change: the request is moved from `pending` to `done`. This is biologically and logistically inaccurate for recipients requiring multiple units (e.g., surgeries, thalassemia).

### 2.2 Proposed Schema Evolution (`blood_requests` collection)
| Field | Type | Description |
|---|---|---|
| `requiredUnits` | `int` | Total units requested by the recipient (default: 1). |
| `fulfilledUnits` | `int` | Atomic counter of verified donations (default: 0). |
| `status` | `string` | Transitions: `pending` -> `partially_fulfilled` -> `completed`. |

### 2.3 Verification Pipeline Refactor
**File:** `lib/repositories/firebase/firebase_donation_repository.dart`
**Method:** `registerDonationBatch`

**New Atomic Logic:**
1.  Read `requiredUnits` and `fulfilledUnits` inside the transaction/batch.
2.  Execute `FieldValue.increment(1)` on `fulfilledUnits`.
3.  **Conditional Status Switch:**
    - If `fulfilledUnits + 1 < requiredUnits`: Set status to `partially_fulfilled`.
    - If `fulfilledUnits + 1 >= requiredUnits`: Set status to `completed` (or `done`).
4.  **Notification Trigger:** The `StagedNotificationService` must continue dispatching batches as long as the status is NOT `completed`.

---

## 3. Medical Data Integrity (Donation Date Locking)

### 3.1 Problem Analysis
The "Last Donation Date" is a safety-critical field. Allowing donors to edit it manually post-verification enables them to bypass the 60-90 day medical cooldown, posing a risk to both donor health and blood quality.

### 3.2 Proposed Schema Evolution (`users` collection)
| Field | Type | Description |
|---|---|---|
| `isLedgerLocked` | `bool` | Flag set to `true` after the first official system-verified donation. |
| `lastDonated` | `string` | ISO 8601 timestamp. |

### 3.3 Locking Mechanism Strategy
**File:** `lib/screens/donor_dashboard/profile_sections/medical_history_screen.dart`

**Implementation:**
- **Initial State:** If `isLedgerLocked` is `false` (new user), the date picker is enabled for a one-time setup.
- **Lock Trigger:** Inside `registerDonationBatch` (and `registerGeneralDonationBatch`), the `isLedgerLocked` field must be set to `true`.
- **UI Enforcement:** If `isLedgerLocked == true`, the `TextFormField` for `lastDonated` must be rendered as `readOnly: true` with a disabled `onTap` handler. A tooltip or sub-text should explain: *"Locked: Your history is now managed by hospital verifications."*

---

## 4. Impacted Files & Action Plan

### 4.1 Data Layer (Firestore)
- **`FirebaseDonationRepository`**: Refactor `registerDonationBatch` to handle increments and `isLedgerLocked` updates.
- **`FirebaseRequestRepository`**: Ensure `create` initializes `fulfilledUnits: 0` and supports `requiredUnits`.

### 4.2 Presentation Layer (UI)
- **`CreateRequestScreen`**: Add a numeric input for `requiredUnits`.
- **`MedicalHistoryScreen`**: Implement conditional read-only logic for the date picker.
- **`RequestResponseScreen`**: Update "Locked State" banners to reflect partial fulfillment (e.g., "1/3 Units Secured").

---
*Audit Status: Complete. Implementation Phase Pending Approval.*
