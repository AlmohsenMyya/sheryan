# Database Schema and NoSQL Modeling

Phase 8 technical analysis of Sheryan's Firestore data layer, collection hierarchy, data dictionary, and NoSQL entity relationships.

Target areas:

- `lib/repositories/firebase/`
- repository interfaces
- `lib/core/models/app_notification.dart`
- services and screens that create or enrich Firestore documents

Sheryan uses Cloud Firestore as a document-oriented NoSQL database. The schema is therefore flexible, query-driven, and partially denormalized rather than normalized like a relational database.

## 1. Collection Hierarchy

Observed root collections:

```text
Firestore
|-- users/{uid}
|   |-- notifications/{notificationId}
|   `-- pointsHistory/{pointsHistoryId}
|-- blood_requests/{requestId}
|-- donations/{donationId}
|-- hospitals/{hospitalId}
|-- cities/{cityId}
|-- rewards/{rewardId}
|-- redemptions/{redemptionId}
`-- announcements/{announcementId}
```

### 1.1 Root Collections

| Collection | Purpose | Primary access pattern |
|---|---|---|
| `users` | User profile, IAM/RBAC metadata, donor medical state, FCM token, points state | by `uid`, by `role`, by `role + city + bloodGroup`, by `hospitalId` |
| `blood_requests` | Blood request lifecycle and fulfillment state | by `hospitalId`, by `userId`, by `status`, by `isVerified` |
| `donations` | Donation audit records | by `hospitalId`, by `requestId`, by donor history screens |
| `hospitals` | Hospital directory | all hospitals, by `city` |
| `cities` | Supported city/village list | ordered by `name` |
| `rewards` | Sponsor reward catalog | by `sponsorId`, by `city`, by `isActive`, ordered by points |
| `redemptions` | Reward redemption audit records | by `sponsorId`; also logically by donor |
| `announcements` | Admin broadcast/announcement records | recent announcements ordered by `createdAt` |

### 1.2 Subcollections

| Path | Purpose |
|---|---|
| `users/{uid}/notifications` | Durable notification inbox for a user |
| `users/{uid}/pointsHistory` | User-specific gamification ledger |

Subcollections are embedded under `users` because they are user-owned, high-cardinality records. This avoids storing all point events and notification inbox items in a global collection that every user must filter aggressively.

## 2. Core Data Dictionary

The following data dictionary is inferred from repository creation/update code, service code, and feature screens.

## 2.1 User Document

Path:

```text
users/{uid}
```

Primary source files:

- `lib/services/auth_service.dart`
- `lib/repositories/firebase/firebase_user_repository.dart`
- `lib/screens/donor_dashboard/profile_sections/*.dart`
- `lib/services/points_service.dart`
- `lib/repositories/firebase/firebase_donation_repository.dart`
- `lib/services/notification_service.dart`

| Field | Type | Purpose |
|---|---|---|
| `uid` | `String` | Firebase Auth user ID duplicated into the profile document for direct reads and UI use |
| `name` | `String` | Display name |
| `email` | `String` | Login/contact email |
| `phone` | `String` | User phone number, often Syrian `+963...` format |
| `role` | `String` | RBAC role: `donor`, `recipient/user`, `hospitalAdmin`, `superAdmin`, `sponsorOrg` |
| `hospitalId` | `String?` | Tenant boundary for hospital admins |
| `bloodGroup` | `String?` | ABO/Rh group used for donor matching |
| `bloodGroupVerified` | `bool?` | Whether a hospital verified the blood group |
| `city` | `String?` | City/village used for geo-local filtering |
| `lastDonated` | `String?` | Last donation date/time; used for medical cooldown filtering |
| `isLedgerLocked` | `bool?` | Locks medical donation date after verified donation |
| `hasDonated` | `bool` | Whether donor has donated through the app; also gates reward redemption |
| `fcmToken` | `String?` | Device messaging endpoint for FCM |
| `createdAt` | `Timestamp` | Server-side account creation time |
| `lastLogin` | `Timestamp?` | Server-side login update time |
| `points` | `int?` | Current gamification balance |
| `tier` | `String?` | Derived from points: `bronze`, `silver`, `gold`, `platinum` |
| `dateOfBirth` | `String?` | Profile demographic field |
| `height` | `double?` | Health profile field |
| `weight` | `double?` | Health profile field |
| `gender` | `String?` | Health profile field |
| `smokingStatus` | `String?` | Health profile field |
| `chronicDiseases` | `String?` | Medical history text |
| `allergies` | `String?` | Medical history text |
| `emergencyContactName` | `String?` | Emergency contact profile field |
| `emergencyContactPhone` | `String?` | Emergency contact phone |

Important indexes implied by queries:

```text
role
role + hospitalId
role + city
role + city + bloodGroup
```

## 2.2 BloodRequest Document

Path:

```text
blood_requests/{requestId}
```

Primary source files:

- `lib/services/request_service.dart`
- `lib/repositories/firebase/firebase_request_repository.dart`
- `lib/screens/requests/create_request_screen.dart`
- `lib/services/staged_notification_service.dart`
- `lib/repositories/firebase/firebase_donation_repository.dart`

| Field | Type | Purpose |
|---|---|---|
| `userId` | `String` | Recipient/request creator UID |
| `patientName` | `String` | Patient name for request context |
| `hospitalId` | `String` | Target hospital document ID |
| `hospital` | `String` | Denormalized hospital display name captured at request creation |
| `city` | `String` | Denormalized city for filtering donors and hospitals |
| `bloodGroup` | `String` | Recipient blood group required |
| `requiredUnits` | `int` | Units required for fulfillment |
| `fulfilledUnits` | `int` | Units fulfilled incrementally by donation transactions |
| `phone` | `String` | Contact phone for the request |
| `neededAt` | `String` | Human-readable requested time |
| `createdAt` | `Timestamp` | Server-side creation time |
| `status` | `String` | Lifecycle state: commonly `pending`, `partially_fulfilled`, `completed`, `done` |
| `isVerified` | `bool` | Whether the hospital/admin verification happened |
| `isUrgent` | `bool?` | Emergency/urgent marker used by donation points and UI |
| `_syncedFromOffline` | `bool?` | Indicates request was replayed from local offline queue |
| `notifiedDonorIds` | `List<String>?` | Donors already targeted by staged notification batches |
| `declinedDonorIds` | `List<String>?` | Donors who declined request slots |
| `lastNotificationSentAt` | `Timestamp?` | Cooldown timestamp for staged notifications |
| `notificationBatchCount` | `int?` | Number of staged batches dispatched |

Important indexes implied by queries:

```text
hospitalId + createdAt desc
userId + createdAt desc
status + createdAt desc
hospitalId + status
hospitalId + isVerified
```

## 2.3 Donation Document

Path:

```text
donations/{donationId}
```

Primary source file:

- `lib/repositories/firebase/firebase_donation_repository.dart`

| Field | Type | Purpose |
|---|---|---|
| `donorId` | `String` | Donor user UID |
| `requestId` | `String?` | Linked blood request ID; `null` for general donation |
| `hospitalId` | `String` | Hospital where donation was verified |
| `hospitalName` | `String` | Denormalized hospital display name |
| `timestamp` | `Timestamp` | Server-side donation registration time |
| `verifiedBy` | `String` | Hospital admin UID that verified donation |
| `manualOverride` | `bool?` | Present when manual verification override is used |
| `type` | `String?` | Present as `general` for general donations |

Important access patterns:

```text
hospitalId + timestamp desc
requestId
```

## 2.4 Hospital Document

Path:

```text
hospitals/{hospitalId}
```

Primary source file:

- `lib/repositories/firebase/firebase_hospital_repository.dart`

| Field | Type | Purpose |
|---|---|---|
| `name` | `String` | Hospital display name |
| `city` | `String` | City for filtering and request selection |
| `phone` | `String?` | Optional hospital contact phone |
| `address` | `String?` | Optional hospital address |
| `createdAt` | `Timestamp` | Server-side creation time |

Access patterns:

```text
order by name
where city == selected city
```

## 2.5 City Document

Path:

```text
cities/{cityId}
```

Primary source file:

- `lib/repositories/firebase/firebase_city_repository.dart`

| Field | Type | Purpose |
|---|---|---|
| `name` | `String` | City/village name |
| `createdAt` | `Timestamp` | Server-side creation time |

Access pattern:

```text
order by name
```

## 2.6 Notification Document

Path:

```text
users/{uid}/notifications/{notificationId}
```

Primary source files:

- `lib/core/models/app_notification.dart`
- `lib/services/notification_service.dart`

| Field | Type | Purpose |
|---|---|---|
| `titleAr` | `String` | Arabic title |
| `titleEn` | `String` | English title |
| `bodyAr` | `String` | Arabic message body |
| `bodyEn` | `String` | English message body |
| `timestamp` | `Timestamp` | Server-side notification creation time |
| `isRead` | `bool` | Inbox read/unread state |
| `type` | `String` | Notification type: `emergency`, `verification`, `gratitude`, `newRequest`, `requestClosed`, `general` |
| `requestId` | `String?` | Optional blood request route key |

Access patterns:

```text
users/{uid}/notifications ordered by timestamp
users/{uid}/notifications where isRead == false
```

## 2.7 Points History Document

Path:

```text
users/{uid}/pointsHistory/{pointsHistoryId}
```

Primary source file:

- `lib/services/points_service.dart`

| Field | Type | Purpose |
|---|---|---|
| `event` | `String` | Points event type, such as `donation_registered` |
| `points` | `int` | Delta awarded for this event |
| `descriptionAr` | `String` | Arabic ledger description |
| `descriptionEn` | `String` | English ledger description |
| `total` | `int` | User's total points after the transaction |
| `createdAt` | `Timestamp` | Server-side event time |

Access pattern:

```text
users/{uid}/pointsHistory order by createdAt desc limit 50
users/{uid}/pointsHistory where event == eventName limit 1
```

## 2.8 Reward Document

Path:

```text
rewards/{rewardId}
```

Primary source files:

- `lib/repositories/firebase/firebase_reward_repository.dart`
- `lib/screens/sponsor/manage_reward_screen.dart`

| Field | Type | Purpose |
|---|---|---|
| `title` | `String` | Reward title |
| `description` | `String` | Reward details |
| `pointsRequired` | `int` | Points cost |
| `sponsorPhone` | `String` | Sponsor contact phone |
| `sponsorAddress` | `String` | Sponsor address |
| `sponsorId` | `String` | Sponsor user UID |
| `sponsorName` | `String` | Denormalized sponsor display name |
| `city` | `String` | City filter for donor reward catalog |
| `isActive` | `bool` | Reward availability flag |
| `createdAt` | `Timestamp?` | Server-side creation time |
| `updatedAt` | `Timestamp` | Server-side modification time |

Access patterns:

```text
sponsorId + createdAt desc
isActive + city + pointsRequired asc
```

## 2.9 Redemption Document

Path:

```text
redemptions/{redemptionId}
```

Primary source file:

- `lib/services/points_service.dart`

| Field | Type | Purpose |
|---|---|---|
| `donorId` | `String` | Donor user UID |
| `sponsorId` | `String` | Sponsor user UID |
| `rewardId` | `String` | Redeemed reward ID |
| `rewardTitle` | `String` | Denormalized reward title at redemption time |
| `pointsDeducted` | `int` | Cost paid |
| `redeemedAt` | `Timestamp` | Server-side redemption time |

Access pattern:

```text
sponsorId
```

## 2.10 Announcement Document

Path:

```text
announcements/{announcementId}
```

Primary source files:

- `lib/services/announcement_service.dart`
- `lib/repositories/firebase/firebase_announcement_repository.dart`

| Field | Type | Purpose |
|---|---|---|
| `titleAr` | `String` | Arabic title |
| `titleEn` | `String` | English title |
| `bodyAr` | `String` | Arabic body |
| `bodyEn` | `String` | English body |
| `target` | `String` | Target audience descriptor |
| `targetCity` | `String?` | Optional city targeting |
| `targetBloodGroup` | `String?` | Optional blood group targeting |
| `createdAt` | `Timestamp` | Server-side creation time |

Access pattern:

```text
order by createdAt desc limit 20
```

## 3. Entity Relationships

Firestore does not enforce foreign keys, but the application maintains logical references.

```text
users/{uid}
  1 ── many blood_requests via blood_requests.userId
  1 ── many donations via donations.donorId
  1 ── many users/{uid}/notifications
  1 ── many users/{uid}/pointsHistory
  1 ── many rewards via rewards.sponsorId
  1 ── many redemptions via redemptions.donorId

hospitals/{hospitalId}
  1 ── many blood_requests via blood_requests.hospitalId
  1 ── many donations via donations.hospitalId
  1 ── many hospital admin users via users.hospitalId

blood_requests/{requestId}
  1 ── many donations via donations.requestId
  1 ── many notifications logically via notifications.requestId

rewards/{rewardId}
  1 ── many redemptions via redemptions.rewardId
```

In relational terms, these are foreign-key-like fields, but Firestore does not provide referential integrity. The app code maintains consistency through services and transactions.

## 4. NoSQL Design Decisions

### 4.1 Denormalized Display Names

The schema stores human-readable names alongside IDs:

```text
blood_requests.hospital
donations.hospitalName
rewards.sponsorName
redemptions.rewardTitle
```

This is intentional NoSQL denormalization.

Instead of reading:

```text
blood_requests/{requestId}
    -> hospitals/{hospitalId}
```

for every request card, the UI can display the hospital name directly from the request. This reduces read amplification, latency, and cost.

### 4.2 Query-Optimized Documents

Firestore queries are collection-oriented and index-driven. Sheryan stores fields directly on documents to support common query filters:

```text
users.role
users.city
users.bloodGroup
users.hospitalId
blood_requests.userId
blood_requests.hospitalId
blood_requests.status
blood_requests.isVerified
rewards.city
rewards.sponsorId
rewards.isActive
```

This favors read-time efficiency over normalization.

### 4.3 User-Owned Subcollections

Notifications and points history are embedded under users:

```text
users/{uid}/notifications
users/{uid}/pointsHistory
```

This has several advantages:

- natural ownership boundary,
- easier security rules,
- smaller per-user queries,
- reduced need for global filters,
- scalable inbox and ledger storage.

### 4.4 Durable Inbox Plus Push Transport

FCM is not treated as the only notification store. Notification documents are persisted under each user. This creates a durable message inbox:

```text
FCM packet = real-time delivery channel
Firestore notification = durable user-visible record
```

This is a NoSQL/edge-networking pattern: transient network delivery is paired with cloud-persisted state so the client can recover missed messages.

### 4.5 Aggregated State on Parent Documents

`blood_requests` stores:

```text
requiredUnits
fulfilledUnits
status
notifiedDonorIds
declinedDonorIds
notificationBatchCount
lastNotificationSentAt
```

These fields avoid computing request status by scanning all donations or notification events. The request document becomes a stateful aggregate root.

This improves mobile read performance:

```text
one request document read -> enough data to render lifecycle state
```

### 4.6 Audit Records as Append-Style Collections

The system creates append-like records for:

```text
donations
redemptions
users/{uid}/pointsHistory
users/{uid}/notifications
announcements
```

These records preserve event history and support auditability while parent documents store current state.

## 5. Data Integrity Notes

The schema uses several transaction-protected relationships:

- donation registration updates `blood_requests`, `users`, and `donations`,
- points awards update `users` and `users/{uid}/pointsHistory`,
- redemptions update `users` and `redemptions`.

This design separates:

```text
current state      -> user/request document fields
historical events  -> donations, redemptions, pointsHistory, notifications
```

That separation is appropriate for Firestore because mobile clients can read current state cheaply while still retaining audit logs.

## 6. Thesis Framing

Sheryan's Firestore model is a query-driven NoSQL schema. It intentionally duplicates selected display and routing fields to reduce joins, minimize client round trips, and support real-time UI streams. This is aligned with Firestore's document model, where application performance often depends on reading exactly the document shape needed by the screen.

The most important modeling principle is:

```text
documents are shaped around application read paths, not relational normalization.
```

For the thesis, the data layer can be summarized as:

```text
Identity/Profile Aggregate   -> users/{uid}
Request Aggregate            -> blood_requests/{requestId}
Donation Audit Log           -> donations/{donationId}
Hospital Directory           -> hospitals/{hospitalId}
Geographic Lookup            -> cities/{cityId}
Reward Catalog               -> rewards/{rewardId}
Redemption Audit Log         -> redemptions/{redemptionId}
User Inbox                   -> users/{uid}/notifications/{notificationId}
Gamification Ledger          -> users/{uid}/pointsHistory/{pointsHistoryId}
Admin Broadcast Log          -> announcements/{announcementId}
```

This model supports edge-oriented mobile performance by reducing cross-document lookups, enabling real-time streams, and preserving durable audit trails for medically significant and gamification-related events.
