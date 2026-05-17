# Concurrency and Data Integrity Deep Dive

Phase 3 technical analysis of distributed concurrency, atomic donation registration, and medical ledger integrity in Sheryan.

Target files:

- `lib/repositories/firebase/firebase_donation_repository.dart`
- `lib/screens/donor_dashboard/profile_sections/medical_history_screen.dart`

This document focuses on concurrency management, Firestore transaction behavior, partial fulfillment integrity, medical cooldown data, and ledger locking.

## 1. Concurrency Model Overview

The donation subsystem operates in a distributed environment where multiple hospital administrator devices may interact with the same blood request at nearly the same time. From a Systems and Network Engineering perspective, each hospital device is a separate client node issuing write operations against shared cloud state in Firestore.

The main concurrency-sensitive object is:

```text
blood_requests/{requestId}
```

The main medically sensitive object is:

```text
users/{donorId}
```

The append-only audit-style record is:

```text
donations/{donationId}
```

The critical operation is `registerDonationBatch()` in `firebase_donation_repository.dart`, which updates all three logical records inside one Firestore transaction.

## 2. Concurrency Control: Atomic Transactions

### 2.1 Target Method

`registerDonationBatch()` is defined in:

```text
lib/repositories/firebase/firebase_donation_repository.dart:25-74
```

The method receives:

- `donorId`
- `requestId`
- `hospitalId`
- `hospitalName`
- `adminUid`
- `manualOverride`

It represents a hospital-confirmed donation event linked to a specific blood request.

### 2.2 Transaction Boundary

The method opens a Firestore transaction at line 33:

```dart
await _fs.runTransaction((transaction) async {
```

Inside that transaction, the code creates references to:

- `blood_requests/{requestId}` at line 34.
- `users/{donorId}` at line 35.
- a new `donations/{autoId}` document at line 36.

This transaction boundary is the concurrency-control mechanism. It groups request fulfillment, donor ledger locking, and donation record creation into a single atomic operation.

### 2.3 Read-Modify-Write on Request Fulfillment

The transaction reads the request document at line 38:

```dart
final requestDoc = await transaction.get(requestRef);
```

If the request does not exist, line 39 throws an exception. This prevents orphan donation records from being created for missing requests.

Lines 41-43 perform the core read-modify-write calculation:

```text
required      = request.requiredUnits or 1
fulfilled     = request.fulfilledUnits or 0
newFulfilled  = fulfilled + 1
```

Lines 45-48 calculate the next request state:

```text
if newFulfilled >= required:
    status = completed
else:
    status = partially_fulfilled
```

Then lines 51-54 update the request document:

```text
fulfilledUnits = newFulfilled
status         = newStatus
```

This is the core of partial fulfillment.

### 2.4 Race Condition Prevented

Consider a request requiring 2 units, currently fulfilled by 1 unit:

```text
requiredUnits  = 2
fulfilledUnits = 1
```

Two hospital admin devices might attempt to register separate donations simultaneously:

```text
Node A reads fulfilledUnits = 1
Node B reads fulfilledUnits = 1
```

Without a transaction, both nodes could compute:

```text
newFulfilled = 2
```

Both would write `fulfilledUnits = 2`, causing a lost update. The database would record two donations but the request counter would increase only once.

Firestore transactions prevent this pattern by detecting concurrent modifications to documents read inside the transaction. Since `requestRef` is read before being updated, concurrent writes to the same request document force Firestore to retry or fail the transaction. The second node must re-read the latest `fulfilledUnits` value before calculating its update.

The intended serializable effect is:

```text
Initial state:
fulfilledUnits = 1

Node A transaction:
read 1 -> write 2

Node B transaction retries:
read 2 -> write 3
```

This protects the incremental counter from the classic lost-update race condition.

### 2.5 Partial Fulfillment as a Concurrent State Machine

The request status acts as a small distributed state machine:

```text
pending / verified
        |
        v
partially_fulfilled
        |
        v
completed
```

The transition is computed inside the transaction:

```text
newFulfilled >= requiredUnits
    -> completed

newFulfilled < requiredUnits
    -> partially_fulfilled
```

Because the counter and status are written together, the request status remains consistent with the fulfillment counter at the moment of transaction commit.

### 2.6 ACID Properties in This Method

Firestore transactions provide a practical subset of ACID behavior suitable for this client-side distributed workflow:

**Atomicity**

The following writes are committed together:

- Request fulfillment update.
- Donor medical ledger lock.
- Donation record creation.

If the transaction fails, none of these transaction writes should commit.

**Consistency**

The request cannot be updated without also creating the donation record and locking the donor ledger. The method maintains the application invariant:

```text
registered donation => request counter updated + donor lastDonated updated + donation audit record created
```

**Isolation**

Concurrent hospital nodes reading and writing the same request document are isolated through Firestore transaction conflict detection and retry behavior.

**Durability**

After commit, the updated request, donor profile, and donation document are persisted in Firestore.

### 2.7 Donation Record as Audit Evidence

Lines 63-72 create the donation record:

```text
donorId
requestId
hospitalId
hospitalName
timestamp
verifiedBy
manualOverride, when applicable
```

The `timestamp` uses `FieldValue.serverTimestamp()` at line 68, which is important for auditability. It records server-side commit time rather than trusting the client clock.

The `verifiedBy` field at line 69 binds the donation event to the hospital admin account that executed it. The optional `manualOverride` flag at line 70 marks exceptional verification paths.

In thesis language, this record contributes to **non-repudiation** because it preserves who verified the donation, where it was verified, which donor and request were involved, and when the cloud backend accepted the write.

## 3. Medical Ledger Locking and Data Integrity

### 3.1 Locking Write Path

The medical ledger lock is written in `registerDonationBatch()` at lines 56-60:

```dart
transaction.update(donorRef, {
  'lastDonated': DateTime.now().toIso8601String(),
  'isLedgerLocked': true,
});
```

This does two things:

- Updates the donor's `lastDonated` field.
- Sets `isLedgerLocked` to `true`.

The same pattern appears in `registerGeneralDonationBatch()` at lines 85-90, where a general donation not linked to a specific request also updates:

```text
lastDonated
isLedgerLocked
```

The design intent is clear: after a hospital-confirmed donation, the user's donation date becomes a protected medical ledger field rather than ordinary self-reported profile data.

### 3.2 Why `lastDonated` Is Security-Sensitive

The `lastDonated` field is not just a profile preference. It affects donor eligibility and medical cooldown logic elsewhere in the system. For example, staged notification filtering excludes donors whose last donation is within a recent cooldown window.

Therefore, if donors could freely edit `lastDonated` after a verified donation, they could shorten or erase the cooldown period and become eligible for emergency requests too early.

The field is medically sensitive because it participates in:

- donor safety,
- recipient safety,
- eligibility filtering,
- emergency request routing,
- integrity of the donation history.

### 3.3 UI-Level Ledger Lock in MedicalHistoryScreen

`MedicalHistoryScreen` reads the lock state in:

```text
lib/screens/donor_dashboard/profile_sections/medical_history_screen.dart:29-33
```

Specifically:

```dart
_lastDonatedCtrl.text = d['lastDonated'] ?? '';
_isLocked = d['isLedgerLocked'] == true;
```

The UI then applies the lock at lines 119-131:

```text
TextFormField for lastDonated
    readOnly: true
    onTap: _isLocked ? null : _pickDate
    suffixIcon: lock icon when locked
    helperText: ledger locked note when locked
```

This disables date selection when `isLedgerLocked` is true. In user-interface terms, the donor can see the locked donation date but cannot open the date picker to change it.

### 3.4 Programmatic Locking Flow

The intended flow is:

```text
Hospital admin confirms donation
        |
        v
registerDonationBatch()
        |
        v
Firestore transaction updates users/{donorId}
        |
        +--> lastDonated = current donation timestamp
        `--> isLedgerLocked = true
        |
        v
MedicalHistoryScreen loads profile data
        |
        v
_isLocked = true
        |
        v
lastDonated UI becomes non-editable
```

This creates an application-level ledger lock. The donor-facing UI treats the hospital-confirmed donation timestamp as immutable.

### 3.5 Non-Repudiation Interpretation

The system stores three linked artifacts:

```text
users/{donorId}.lastDonated
users/{donorId}.isLedgerLocked
donations/{donationId}
```

The donation record includes:

- `donorId`
- `requestId`
- `hospitalId`
- `hospitalName`
- `verifiedBy`
- server timestamp

This means the donor cannot plausibly claim that the cooldown date is merely self-entered profile data. The lock is produced by a hospital-side verification workflow and backed by an audit record.

From a data security standpoint, the lock establishes provenance:

```text
lastDonated value source = hospital-confirmed donation event
```

This supports non-repudiation by linking the medical cooldown timestamp to a verifier, hospital, request, and durable donation record.

### 3.6 Data Integrity Interpretation

The lock protects the integrity of medical cooldown state. Once `isLedgerLocked` is true, the user-facing profile screen does not permit editing the date picker for `lastDonated`.

This preserves the invariant:

```text
hospital-confirmed donation => donor cannot self-adjust last donation date in normal app UI
```

This is significant because distributed donor eligibility depends on trustworthy medical metadata. If `lastDonated` is inaccurate, notification routing may select medically ineligible donors.

## 4. Important Security Limitation

The current implementation provides strong application-level intent, but the target files show only a **client/UI-level lock** on the donor profile screen.

In `medical_history_screen.dart`, `_save()` still sends an update containing:

```dart
'lastDonated': _lastDonatedCtrl.text.trim()
```

This happens at lines 75-79. When `_isLocked` is true, the date picker is disabled, so normal users cannot change the value through the visible UI. However, the method itself does not explicitly remove `lastDonated` from the update payload when locked.

Therefore:

- The visible app UI discourages and blocks normal date editing.
- The donation repository programmatically sets the lock.
- Full tamper resistance still depends on Firestore Security Rules or backend enforcement that prevents donors from changing `lastDonated` and `isLedgerLocked` after lock activation.

For thesis accuracy, this should be described as:

```text
application-level ledger locking with a required backend/security-rules enforcement boundary
```

It should not be overstated as complete cryptographic immutability by itself.

## 5. Distributed Concurrency Scenario

### Scenario: Multiple Hospital Nodes Register Donations

Assume:

```text
requiredUnits  = 3
fulfilledUnits = 1
```

Two hospital admins verify two donors at approximately the same time.

Without transactions:

```text
Node A reads fulfilledUnits = 1
Node B reads fulfilledUnits = 1
Node A writes fulfilledUnits = 2
Node B writes fulfilledUnits = 2
```

The system loses one donation from the aggregate counter.

With `registerDonationBatch()`:

```text
Node A transaction reads fulfilledUnits = 1
Node A writes fulfilledUnits = 2
Node A commits

Node B transaction detects changed request document
Node B retries
Node B reads fulfilledUnits = 2
Node B writes fulfilledUnits = 3
Node B sets status = completed
Node B commits
```

The final state is consistent:

```text
fulfilledUnits = 3
status = completed
two donation records exist
two donor ledgers are locked
```

This is the core distributed concurrency protection in the donation subsystem.

## 6. Integrity Invariants

The current implementation attempts to maintain these invariants:

1. A donation linked to a request increments `fulfilledUnits` exactly once.
2. `status` reflects whether the request has reached `requiredUnits`.
3. A hospital-confirmed donation creates a durable `donations` record.
4. A hospital-confirmed donation locks the donor ledger.
5. A locked donor ledger disables normal UI editing of `lastDonated`.
6. Donation records include verifier and hospital metadata for auditability.

The strongest invariant is the transaction-level relationship between request fulfillment, donor lock, and donation record creation.

The weaker invariant is UI-level immutability of `lastDonated`, because complete enforcement requires Firestore rules or server-side validation not shown in the two target files.

## 7. Academic Framing

Sheryan's donation registration workflow can be described as an **optimistic distributed concurrency control mechanism** implemented through Firestore transactions. Each hospital device behaves as a distributed node that attempts to mutate shared request state. Firestore provides conflict detection, retry behavior, and atomic commit semantics over the request document, donor document, and donation record.

The medical ledger lock is a **data integrity control** that transforms `lastDonated` from user-editable profile data into hospital-verified medical state. When combined with the donation audit record, it supports non-repudiation by binding a medical cooldown timestamp to an authenticated verifier and a persistent donation event.

In ACID terms, `registerDonationBatch()` is the critical consistency boundary. It ensures that partial fulfillment counters, request status, donor cooldown state, and donation audit evidence are committed as one logical unit. In security terms, `isLedgerLocked` is a client-visible integrity flag that should be backed by database security rules to fully prevent tampering in adversarial conditions.
