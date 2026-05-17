# System Workflows and End-to-End Lifecycle

Phase 9 synthesis of Sheryan's business workflows and user journeys. This document connects human actors to the technical routing, notification, database, and gamification layers documented in earlier phases.

Primary actors:

- Recipient
- Hospital Admin
- Donor
- Sponsor Organization
- Super Admin

Primary technical modules:

- `RequestBloodScreen`
- `RequestService`
- `FirebaseRequestRepository`
- `RequestDetailSheet`
- `HospitalRequestsController`
- `NotificationEngine`
- `StagedNotificationService`
- `NotificationService`
- `RequestResponseScreen`
- `DonationService`
- `FirebaseDonationRepository`
- `PointsService`
- `RewardsScreen`
- `ScanRedeemScreen`

## 1. Blood Request Lifecycle

### 1.1 High-Level Flowchart

```text
Recipient creates request
        |
        v
blood_requests/{requestId}
status = pending
isVerified = false
fulfilledUnits = 0
        |
        v
Hospital Admin verifies request
        |
        v
BloodRequestVerifiedEvent
        |
        +--> notify requester
        |
        `--> StagedNotificationService.dispatchNextBatch()
                  |
                  v
          compatible donor batch selected
                  |
                  v
          FCM emergency packets delivered
                  |
                  v
Donor opens RequestResponseScreen
        |
        +--> Accept: contact recipient by phone/WhatsApp
        |
        `--> Decline: mark donor declined and notify replacement
                  |
                  v
Hospital Admin registers donation
        |
        v
Firestore transaction increments fulfilledUnits
        |
        +--> partially_fulfilled
        |
        `--> completed / done
```

## 2. Stage 1: Creation by Recipient

### 2.1 Human Action

The recipient opens the blood request creation screen and enters:

- patient name,
- hospital,
- city,
- blood group,
- required units,
- phone,
- needed date/time.

Primary screen:

```text
lib/screens/requests/create_request_screen.dart
```

### 2.2 Online Path

When connectivity is available, the screen calls:

```text
RequestService().create(...)
```

`RequestService` enriches the payload with system fields:

```text
createdAt = serverTimestamp
status = pending
isVerified = false
```

`FirebaseRequestRepository.create()` then adds:

```text
fulfilledUnits = 0
requiredUnits = data.requiredUnits or 1
```

and creates:

```text
blood_requests/{requestId}
```

### 2.3 Offline Path

If the device is offline, the screen calls:

```text
PendingActionsService().saveRequest(...)
```

The request is serialized into the local SharedPreferences queue. Later, `HomeController.syncPendingRequests()` replays it through `RequestService.create()` and then dispatches the same request-created event.

### 2.4 Event Dispatch

After successful online creation or offline replay, the app dispatches:

```text
BloodRequestCreatedEvent
```

`NotificationEngine` handles this by calling:

```text
NotificationService.sendToHospitalAdmins(...)
```

Result:

```text
Hospital admins attached to the target hospital receive a new-request notification.
```

## 3. Stage 2: Pending State

The newly created request is in the initial operational state:

```text
status = pending
isVerified = false
fulfilledUnits = 0
requiredUnits = N
```

Hospital dashboards and request lists observe this document through Firestore streams, typically filtered by:

```text
hospitalId
status
createdAt
```

The request is visible to hospital admins but is not yet fully activated for staged donor broadcast until verification occurs.

## 4. Stage 3: Verification by Hospital Admin

### 4.1 Human Action

The hospital admin opens a request card and views `RequestDetailSheet`.

Primary files:

```text
lib/screens/hospital/requests/request_card.dart
lib/screens/hospital/requests/request_detail_sheet.dart
lib/screens/hospital/controllers/hospital_requests_controller.dart
```

If the request is not verified, the detail sheet exposes a verification action.

### 4.2 Technical Action

The UI calls:

```text
ref.read(hospitalRequestsProvider).markVerified(context, requestDoc)
```

`HospitalRequestsController.markVerified()` performs:

```text
RequestService.markVerified(requestId)
```

which updates:

```text
blood_requests/{requestId}.isVerified = true
```

Then it dispatches:

```text
BloodRequestVerifiedEvent(
  requestId,
  requesterId,
  city,
  bloodGroup
)
```

### 4.3 Resulting Active State

After verification, the request becomes active for donor routing:

```text
isVerified = true
status remains pending until donation fulfillment changes it
```

This stage is the bridge between hospital validation and distributed donor notification.

## 5. Stage 4: Routing Through the Staged Notification Engine

### 5.1 Event Routing

`NotificationEngine._onRequestVerified()` performs two actions:

1. If `requesterId` exists, send a direct verification notification to the requester.
2. Call:

```text
StagedNotificationService().dispatchNextBatch(requestId)
```

### 5.2 Batch Selection

`StagedNotificationService` reads:

```text
blood_requests/{requestId}
```

It extracts:

- `city`,
- `bloodGroup`,
- `notifiedDonorIds`,
- `declinedDonorIds`,
- `lastNotificationSentAt`.

Then it computes compatible donor blood groups through:

```text
BloodLogic.getCompatibleDonors(bloodGroup)
```

and queries donor users by:

```text
role = donor
city = request city
bloodGroup in compatible types
```

### 5.3 Filtering and Ranking

Candidate donors are filtered to exclude:

- previously notified donors,
- previously declined donors,
- donors who donated within the medical cooldown window.

Candidates are ranked by:

1. medically verified blood group first,
2. higher points second.

The engine selects up to 10 donors per batch.

### 5.4 State Commit

The service updates the request document inside a transaction:

```text
notifiedDonorIds = arrayUnion(selected donor IDs)
lastNotificationSentAt = serverTimestamp
notificationBatchCount = increment(1)
isVerified = true
```

Only after transaction success does it fire network side effects.

### 5.5 Delivery to Donors

Selected donors receive emergency notifications through:

```text
NotificationService.sendDirectNotification(...)
```

For emergency messages, the FCM packet is data-oriented and contains:

```text
requestId
type = emergency
title/body in Arabic and English
click_action
```

The donor device receives the packet, updates the local emergency provider, shows a local notification, and routes the donor to the response screen when opened.

## 6. Stage 5: Donor Response

Primary file:

```text
lib/screens/donors/request_response_screen.dart
```

The donor sees:

- blood group,
- patient name,
- hospital,
- city,
- fulfilled units vs required units,
- needed time,
- accept and decline actions.

### 6.1 Accept Path

Current implementation:

```text
Accept
  -> show bottom sheet
  -> donor chooses phone call or WhatsApp
  -> app opens tel: or WhatsApp message
```

Important technical note:

```text
The current accept path does not write an "acceptedDonorIds" or formal acceptance record to Firestore.
```

Acceptance is therefore an operational communication action rather than a database state transition. The donor contacts the recipient directly.

### 6.2 Decline Path

If the donor declines, `RequestResponseScreen` calls:

```text
StagedNotificationService().declineRequestSlot(requestId, donorId)
```

The service:

1. Adds the donor to `declinedDonorIds`.
2. Recomputes the compatible donor pool.
3. Excludes notified and declined donors.
4. Selects one replacement donor.
5. Adds replacement donor to `notifiedDonorIds`.
6. Sends an emergency notification to that replacement.

This keeps the donor notification window replenished.

## 7. Stage 6: Fulfillment by Hospital Admin

### 7.1 Human Action

After a donor arrives or is confirmed, the hospital admin registers the donation through:

- scanner workflow, or
- manual fulfillment dialog.

Manual path files:

```text
lib/screens/hospital/requests/manual_fulfill_dialog.dart
lib/screens/hospital/controllers/hospital_requests_controller.dart
```

The admin enters or scans a donor ID, confirms the donor, then submits fulfillment.

### 7.2 Technical Action

The controller calls:

```text
DonationService.registerDonation(...)
```

This calls:

```text
FirebaseDonationRepository.registerDonationBatch(...)
```

### 7.3 Atomic Partial Fulfillment

The repository opens a Firestore transaction:

```text
read blood_requests/{requestId}
required = requiredUnits
fulfilled = fulfilledUnits
newFulfilled = fulfilled + 1

if newFulfilled >= required:
    status = completed
else:
    status = partially_fulfilled
```

The same transaction:

- updates `fulfilledUnits`,
- updates `status`,
- locks donor medical ledger with `lastDonated` and `isLedgerLocked`,
- creates a `donations/{donationId}` audit record.

### 7.4 Notification and Points After Fulfillment

After donation registration, `DonationService` awards points:

```text
PointsService.awardDonationPoints(...)
```

Then `HospitalRequestsController` dispatches:

```text
DonationRegisteredEvent
```

`NotificationEngine` sends:

- a thank-you notification to the donor,
- a fulfillment notification to the requester when requester ID is available.

## 8. Stage 7: Final Closure

The request becomes final when:

```text
fulfilledUnits >= requiredUnits
```

At that point:

```text
status = completed
```

Some user flows also use:

```text
status = done
```

Both `done` and `completed` are treated as fulfilled/closed states in multiple screens and services.

Closed requests block further donor action in `RequestResponseScreen`, which displays a fulfilled banner instead of accept/decline actions.

## 9. Donor Gamification Lifecycle

### 9.1 High-Level Flowchart

```text
Donor signs up
        |
        v
users/{uid} created
role = donor
hasDonated = false
        |
        v
account_created points awarded
        |
        v
Donor completes profile sections
        |
        v
profile milestone points awarded
        |
        v
Hospital verifies blood group
        |
        v
bloodGroupVerified = true
verification points awarded
        |
        v
Donor completes verified donation
        |
        v
donation points + possible bonuses
hasDonated = true
        |
        v
Donor browses sponsor rewards
        |
        v
Sponsor scans donor QR
        |
        v
PointsService.deductPoints()
        |
        v
redemptions/{redemptionId} created
```

## 10. Donor Stage 1: Sign-Up and Initial Identity

Primary file:

```text
lib/screens/auth/sign_up_screen.dart
```

The donor selects donor role and submits:

- name,
- email,
- password,
- phone,
- city,
- blood group,
- optional last donation date.

The app calls:

```text
AuthService.registerUser(...)
```

which creates:

```text
users/{uid}
```

with:

```text
role = donor
hasDonated = false
fcmToken = current device token
createdAt = serverTimestamp
```

After successful sign-up, donor users receive:

```text
PointsEvent.accountCreated
```

through:

```text
PointsService.awardPoints(...)
```

## 11. Donor Stage 2: Profile Completion

The donor completes profile sections:

- basic info,
- health info,
- medical history,
- emergency contact.

Each section updates fields in:

```text
users/{uid}
```

Then the screen calls:

```text
PointsService.checkAndAwardProfileMilestones(uid, profile)
```

Possible milestone awards:

- basic info complete,
- health info complete,
- medical history complete,
- emergency contact complete,
- full profile bonus when all required milestones plus verification are complete.

These awards create documents under:

```text
users/{uid}/pointsHistory/{pointsHistoryId}
```

and update:

```text
users/{uid}.points
users/{uid}.tier
```

## 12. Donor Stage 3: Medical Blood Group Verification

Hospital admins can verify a donor's blood group through scanner workflows.

Relevant technical path:

```text
UserService.markBloodGroupVerified(uid)
```

This updates:

```text
users/{uid}.bloodGroupVerified = true
```

Then milestone logic may award:

```text
PointsEvent.bloodGroupVerified
```

The system also dispatches:

```text
BloodGroupVerifiedEvent
```

which `NotificationEngine` turns into a confirmation notification to the donor.

## 13. Donor Stage 4: Donation and Points Growth

When the donor completes a hospital-verified donation, the system calls:

```text
DonationService.registerDonation(...)
```

This performs:

1. request fulfillment update,
2. donation audit creation,
3. donor medical ledger lock,
4. points award.

The points award uses:

```text
PointsService.awardDonationPoints(...)
```

Base and bonus logic:

- verified donation base points,
- emergency multiplier if request is urgent,
- rare blood type bonus for rare donor groups,
- consecutive donation bonus if the donor already has previous donation history.

The donor's profile is updated:

```text
hasDonated = true
```

This is important because reward redemption is locked until the donor has donated at least once.

## 14. Donor Stage 5: Reward Discovery

Primary file:

```text
lib/screens/donor_dashboard/rewards_screen.dart
```

The donor sees:

- current points,
- tier,
- tier progress,
- points history,
- active rewards filtered by city,
- redemption lock if `hasDonated == false`.

Rewards are loaded through:

```text
cityRewardsProvider(city)
```

which reads active rewards from:

```text
rewards/{rewardId}
```

## 15. Donor Stage 6: Reward Redemption

The donor-facing rewards screen shows a QR code for redemption, but the actual point deduction occurs through the sponsor-side scan workflow.

Primary file:

```text
lib/screens/sponsor/scan_redeem_screen.dart
```

The sponsor scans or enters the donor ID and calls:

```text
PointsService.deductPoints(...)
```

The transaction:

1. Reads `users/{donorUid}`.
2. Checks current points.
3. Checks `hasDonated`.
4. Rejects if points are insufficient or donor has never donated.
5. Deducts points.
6. Recomputes tier.
7. Creates:

```text
redemptions/{redemptionId}
```

This prevents double-spending and records the sponsor reward redemption as an audit event.

## 16. Workflow Summary

### Blood Request Workflow

```text
Recipient intent
  -> Firestore request
  -> hospital verification
  -> event dispatch
  -> staged donor routing
  -> donor response
  -> hospital fulfillment
  -> transaction-based partial/final closure
```

### Donor Gamification Workflow

```text
donor identity
  -> profile completion
  -> medical verification
  -> donation
  -> points ledger
  -> tier growth
  -> sponsor reward redemption
```

## 17. Architectural Interpretation

These workflows show that Sheryan is not only a CRUD application. It is a lifecycle-driven system where human actions trigger distributed technical flows:

- recipient actions create request state,
- hospital actions validate and mutate medical workflow state,
- notification engines route requests to compatible donor nodes,
- donor actions affect routing continuation,
- donation transactions update fulfillment and medical ledger state,
- gamification transactions maintain incentive integrity.

For the thesis, the key framing is:

```text
Human workflow events are transformed into database state transitions,
domain events, FCM data packets, and transactional ledger updates.
```

This connects the software engineering user journeys with the networking, concurrency, data modeling, and domain logic layers documented in previous phases.
