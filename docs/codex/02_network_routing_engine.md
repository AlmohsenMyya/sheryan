# Network Routing Engine Deep Dive

Phase 2 technical analysis of Sheryan's distributed notification and routing layer. Target files:

- `lib/services/notification_service.dart`
- `lib/services/staged_notification_service.dart`
- `lib/events/notification_engine.dart`

This document treats the notification subsystem as a distributed messaging pipeline composed of local event producers, an in-app routing engine, Firestore-backed state synchronization, Firebase Cloud Messaging (FCM) transport, and client-side edge orchestration.

## 1. System-Level Communication Model

Sheryan's messaging layer is not a simple "send notification" utility. It is a multi-stage routing engine:

```text
Domain action inside app
        |
        v
AppEvent object
        |
        v
NotificationEngine
        |
        +--> NotificationService
        |       |
        |       +--> Firestore inbox write
        |       +--> FCM HTTP v1 push packet
        |       +--> Local notification rendering
        |       `--> Navigation/routing from message data
        |
        `--> StagedNotificationService
                |
                +--> Firestore transaction as coordination lock
                +--> donor candidate filtering and ranking
                +--> batch selection
                `--> downstream NotificationService calls
```

From a Systems and Network Engineering perspective, this design mixes:

- **Distributed Messaging:** FCM is used as the packet delivery substrate between app instances.
- **Stateful Coordination:** Firestore stores notification state, request state, donor eligibility state, cooldown metadata, and inbox records.
- **Edge Computing:** A client device performs orchestration normally associated with a backend worker: selecting donors, enforcing cooldowns, committing coordination state, and dispatching outgoing push messages.
- **Event-Driven Routing:** local domain events are converted into transport-specific push operations.

## 2. NotificationService: Transport and Packet Layer

`NotificationService` is the central transport adapter. It owns FCM token handling, local notification rendering, Firebase HTTP v1 calls, Firestore inbox persistence, and navigation behavior after packet reception.

### 2.1 Singleton Transport Instance

`notification_service.dart` defines a singleton service at lines 35-38. This ensures all screens and engines share one logical transport object:

```text
NotificationService()
  -> FirebaseFirestore instance
  -> FirebaseMessaging instance
  -> FlutterLocalNotificationsPlugin instance
```

The service binds three layers together:

- **Control Plane:** OAuth2 service account token generation, FCM token registration.
- **Data Plane:** FCM HTTP v1 packet emission.
- **Presentation Plane:** local notification display and tap routing.

### 2.2 FCM HTTP v1 Authentication

Lines 61-73 define a service account JSON structure from `.env` variables. Lines 75-91 use `googleapis_auth` to exchange that service account for an OAuth2 access token scoped to:

```text
https://www.googleapis.com/auth/firebase.messaging
```

The network implication is that the client constructs authenticated HTTP v1 requests directly to:

```text
https://fcm.googleapis.com/v1/projects/{projectId}/messages:send
```

This is implemented in `_sendV1NotificationWithToken()` at lines 513-535 using `http.post`, `Authorization: Bearer <accessToken>`, `Content-Type: application/json`, and a JSON-encoded FCM message packet.

Academic note: this creates a **client-originated trusted sender** model. In conventional production architectures, FCM service account credentials usually reside on a backend server or Cloud Function. In this codebase, the Flutter client can act as a privileged packet sender. This enables edge orchestration but increases the importance of credential protection and rule-based authorization.

### 2.3 Receive Path: FCM Lifecycle Hooks

The receive path is initialized in `initializeNotificationHandlers()` at lines 95-119:

- Lines 96-98 initialize local notification support and register the background handler.
- Lines 100-105 handle foreground FCM packets.
- Lines 107-110 handle packets tapped from background state.
- Lines 112-118 handle the terminated-state launch packet.

The background handler is declared at lines 25-33 with `@pragma('vm:entry-point')`, making it callable by the runtime when the application is not active. It creates a `NotificationService`, initializes local notifications for background operation, and renders the received packet manually.

This matters because the system intentionally supports **data-only packets**, where the operating system does not automatically display a notification. Instead, the application receives packet data and renders a local notification itself.

### 2.4 State Shield and Tap Routing

Lines 136-158 implement a small packet-to-navigation router:

- `_updateEmergencyState()` extracts `requestId` and `type` from the FCM data map.
- If `type == 'emergency'`, it updates the global Riverpod state `lastEmergencyRequestIdProvider`.
- `_handleRouting()` reuses that state update, then navigates to `RequestResponseScreen(requestId: requestId)` for emergency packets.

This is a two-step routing model:

```text
Incoming FCM data packet
        |
        +--> update global emergency state
        |
        `--> route user to response screen when packet is opened
```

In network terms, the FCM packet contains an application-layer routing header:

```text
type: emergency
requestId: <blood_request_document_id>
click_action: FLUTTER_NOTIFICATION_CLICK
```

The app uses these fields as a lightweight routing protocol over FCM.

## 3. FCM Payload Architecture

The codebase uses two payload strategies:

1. **Pure data-only payloads** for emergency messaging.
2. **Hybrid notification + data payloads** for non-emergency direct messages.

### 3.1 Data-Only Emergency Broadcast Packets

`sendEmergencyNotification()` begins at line 295. It constructs a recipient segment by querying Firestore users:

- Role filter: donor users only.
- Optional city filter.
- Optional blood compatibility filter using `BloodLogic.getCompatibleDonors()`.

At lines 361-378, each donor with an FCM token receives an FCM HTTP v1 message shaped as:

```json
{
  "message": {
    "token": "<donor_fcm_token>",
    "data": {
      "requestId": "<request_id>",
      "type": "emergency",
      "bloodGroup": "<blood_group>",
      "titleEn": "...",
      "titleAr": "...",
      "bodyEn": "...",
      "bodyAr": "...",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    }
  }
}
```

The important technical property is the absence of a top-level `notification` block. The code comment at lines 365-366 explicitly identifies this as a "Data-only payload."

Technical reasoning:

- A `notification` payload can be intercepted and displayed by the mobile operating system, especially when the app is in background.
- OS-level interception reduces application control over localization, state mutation, navigation, deduplication, and custom rendering.
- A data-only payload forces the application layer to interpret the packet and render a local notification through `FlutterLocalNotificationsPlugin`.
- This allows the app to update Riverpod emergency state and encode navigation behavior before or during local presentation.

In thesis language, the emergency packet is an **application-managed data packet** rather than an OS-managed notification packet. It shifts responsibility from the platform notification daemon to the Sheryan application runtime.

### 3.2 Local Rendering of Data Packets

Lines 211-242 implement `_showLocalNotification()`. The method supports both packet types:

- If `message.notification != null`, title/body are read from the OS notification object.
- Otherwise, title/body are extracted from `message.data['titleEn']`, `message.data['titleAr']`, `message.data['bodyEn']`, and `message.data['bodyAr']`.

The local notification stores `jsonEncode(message.data)` as its payload at line 239. When the local notification is tapped, `_setupLocalNotifications()` decodes this payload and passes it to `_handleRouting()` at lines 191-195.

This creates a full loop:

```text
FCM data packet
    -> app receives packet
    -> app extracts title/body
    -> app displays local notification
    -> local notification stores original data map as payload
    -> tap decodes payload
    -> app routes to request screen
```

The original data packet therefore survives the conversion from FCM transport to local OS notification UI.

### 3.3 Hybrid Direct Notification Packets

`sendDirectNotification()` begins at line 451. It looks up a target user's FCM token, obtains an OAuth2 access token, and constructs an FCM packet.

Lines 470-478 define the key branch:

```text
isEmergency = type == NotificationType.emergency

if not emergency:
    include "notification": {"title": titleEn, "body": bodyEn}

always include "data": {...}
```

So non-emergency direct notifications are hybrid packets:

```json
{
  "message": {
    "token": "<target_fcm_token>",
    "notification": {
      "title": "...",
      "body": "..."
    },
    "data": {
      "requestId": "...",
      "type": "...",
      "titleEn": "...",
      "titleAr": "...",
      "bodyEn": "...",
      "bodyAr": "...",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    }
  }
}
```

For emergency direct notifications, the `notification` block is omitted, preserving the data-only behavior.

This dual architecture indicates a priority model:

- **Emergency traffic:** application-controlled packet handling.
- **Routine traffic:** platform-assisted notification display plus application metadata.

### 3.4 Firestore Inbox as Durable Message Store

Every direct notification also persists an `AppNotification` document under:

```text
users/{uid}/notifications/{notificationId}
```

This happens at lines 495-508 in `sendDirectNotification()`. Emergency broadcasts write inbox records through a Firestore batch at lines 351-356 before sending FCM futures.

The result is a dual-channel messaging architecture:

- **Volatile push path:** FCM packet delivery to device token.
- **Durable inbox path:** Firestore notification document persisted for later retrieval.

The Firestore inbox compensates for FCM limitations such as token expiry, device offline state, notification permission denial, or packet loss.

## 4. Decentralized Orchestration: StagedNotificationService

`StagedNotificationService` is the most important edge-computing component in this subsystem. It does not merely call `NotificationService`; it coordinates batch selection, eligibility rules, cooldown validation, and request state mutation.

### 4.1 Service Role

Lines 8-16 define another singleton with:

- `FirebaseFirestore _fs`
- `UserService _userService`
- `NotificationService _notifService`

This places the service at the intersection of:

- Firestore coordination state.
- User/donor discovery.
- FCM notification transport.

### 4.2 Batch Dispatch Algorithm

`dispatchNextBatch(String requestId)` begins at line 21. Its documented contract at lines 18-20 is precise:

- Dispatch up to 10 donors.
- Enforce a 30-minute server-side cooldown.
- Execute side effects outside the Firestore transaction.

The algorithm is:

```text
Input: requestId

1. Create reference to blood_requests/{requestId}
2. Open Firestore transaction
3. Read request document
4. Abort if request does not exist
5. Abort if request status is done/completed
6. Validate cooldown using lastNotificationSentAt + 30 minutes
7. Read request city and bloodGroup
8. Read notifiedDonorIds and declinedDonorIds
9. Compute compatible blood groups
10. Query compatible donors through UserService
11. Filter out previously notified donors
12. Filter out declined donors
13. Filter out medically ineligible donors based on recent donation date
14. Rank donors
15. Select top 10
16. Atomically update request notification metadata
17. Commit transaction
18. After transaction success, send FCM messages to selected donors
```

The Firestore transaction block is lines 31-113. The side-effect block is lines 115-119.

### 4.3 Firestore Transaction as Coordination Lock

The transaction is used as a distributed coordination primitive. It atomically updates:

- `notifiedDonorIds`
- `lastNotificationSentAt`
- `notificationBatchCount`
- `isVerified`

These updates occur at lines 103-109.

This prevents multiple clients from safely selecting the same donor batch under normal Firestore transaction retry semantics. The document `blood_requests/{requestId}` acts as a coordination record. The fields inside it are effectively protocol state:

```text
notifiedDonorIds          -> membership history
declinedDonorIds          -> exclusion list
lastNotificationSentAt    -> rate-limit timestamp
notificationBatchCount    -> sequence counter
isVerified                -> request lifecycle marker
```

### 4.4 Cooldown Enforcement

Lines 42-52 validate `lastNotificationSentAt` against a 30-minute interval. If the current device time is earlier than `lastSent + 30 minutes`, the service throws an exception and aborts the batch.

The design intent is rate limiting:

```text
if now < lastNotificationSentAt + 30 minutes:
    reject dispatch
else:
    allow next batch
```

The cooldown field is written using `FieldValue.serverTimestamp()` at line 106, which improves consistency for the stored timestamp. However, the comparison uses `DateTime.now()` on the client at line 45. Architecturally, this is a hybrid time model:

- **Stored time:** server-generated.
- **Comparison time:** client-generated.

For documentation, this is best described as "Firestore-backed cooldown enforcement executed by an edge client." For stricter distributed-system correctness, a backend clock would be preferable, but the current code relies on client-side evaluation over a server-authored timestamp.

### 4.5 Candidate Discovery, Medical Filtering, and Ranking

Lines 55-65 extract request metadata and retrieve compatible donors:

- City from request document.
- Blood group from request document.
- Compatible donor groups from `BloodLogic.getCompatibleDonors()`.
- Donor pool from `UserService.getCompatibleDonors()`.

Lines 68-84 apply eligibility filters:

- Exclude already notified donors.
- Exclude declined donors.
- Exclude donors whose `lastDonated` timestamp is within the last 60 days.

Lines 86-92 rank candidates:

- Verified blood group donors first.
- Higher points donors second.

Line 95 selects up to 10 donors. This creates a deterministic edge-side scheduling algorithm:

```text
eligible_donors
    -> sort(verified desc, points desc)
    -> take(10)
    -> atomically mark selected donors as notified
    -> send packets
```

### 4.6 Side Effects Outside the Transaction

The service intentionally stores the selected batch in `batchToNotify` at line 112 and sends FCM only after transaction success at lines 115-119. This is technically important.

Firestore transactions may retry. If network side effects were executed inside the transaction, retries could duplicate FCM packets. By committing only state mutations inside the transaction and performing network calls afterward, the system reduces duplicate external sends.

However, `_fireBatchNotifications()` at lines 205-224 schedules a `Future.microtask` and does not await it. The implication is:

- `dispatchNextBatch()` can complete before all FCM HTTP calls complete.
- FCM failures are decoupled from the transaction result.
- The request may record donors as notified even if a later FCM send fails.

This is a common edge-orchestration tradeoff: state consistency is prioritized over guaranteed transport completion.

### 4.7 Decline Replenishment Algorithm

`declineRequestSlot()` begins at line 128. It implements a smaller version of the batch algorithm:

```text
Input: requestId, donorId

1. Open transaction on blood_requests/{requestId}
2. Mark donorId as declined
3. Rebuild compatible candidate pool
4. Exclude notified, declined, and the declining donor
5. Apply 60-day medical filter
6. Rank by verification and points
7. Pick one replacement donor
8. Add replacement to notifiedDonorIds
9. Commit transaction
10. Send FCM to replacement donor outside transaction
```

This is dynamic replenishment. The donor network behaves like a rolling window: as one recipient node declines, the edge orchestrator selects the next best node and emits a new packet.

### 4.8 Edge-Orchestrator Interpretation

The staged service makes the Flutter client behave as an edge orchestration node. It:

- Reads distributed state from Firestore.
- Computes eligibility and priority locally.
- Writes coordination metadata atomically.
- Dispatches FCM packets through `NotificationService`.
- Performs replacement scheduling after donor decline.

This is not centralized backend orchestration. The computation lives at the application edge. Firestore acts as the distributed state substrate, and FCM acts as the packet transport layer.

## 5. Event-Driven Routing Through NotificationEngine

`NotificationEngine` is the application-layer router. Its responsibility is to translate domain-level events into one or more messaging operations.

### 5.1 Event Router Design

Lines 18-24 define a singleton engine with a `NotificationService` dependency. Lines 29-48 expose `dispatch(AppEvent event)`, which performs a typed switch over event subclasses:

- `BloodRequestCreatedEvent`
- `BloodRequestVerifiedEvent`
- `DonationRegisteredEvent`
- `BloodRequestClosedEvent`
- `BloodGroupVerifiedEvent`
- `AdminBroadcastEvent`

The dispatch function catches and logs errors instead of rethrowing them. This intentionally makes notification routing **non-blocking** relative to the domain action. A donation, request creation, or verification workflow should not crash only because a push operation fails.

### 5.2 Routing Table

The engine can be represented as a routing table:

| Event | Handler | Outgoing network action |
|---|---|---|
| `BloodRequestCreatedEvent` | `_onRequestCreated()` | Notify hospital admins assigned to the target hospital |
| `BloodRequestVerifiedEvent` | `_onRequestVerified()` | Notify requester directly, then dispatch staged donor batch |
| `DonationRegisteredEvent` | `_onDonationRegistered()` | Notify donor and optionally requester |
| `BloodRequestClosedEvent` | `_onRequestClosed()` | Find matched donor and send closure confirmation |
| `BloodGroupVerifiedEvent` | `_onBloodGroupVerified()` | Notify donor of medical verification |
| `AdminBroadcastEvent` | `_onAdminBroadcast()` | Send emergency broadcast to donor segment |

### 5.3 Request Creation Route

Lines 52-65 handle `BloodRequestCreatedEvent`. The engine converts the event into a hospital-admin packet through:

```text
NotificationService.sendToHospitalAdmins()
```

The event payload contains the hospital ID, hospital name, patient name, blood group, and request ID. The engine constructs bilingual packet copy and uses the request ID as routing metadata.

### 5.4 Request Verification Route

Lines 67-96 handle `BloodRequestVerifiedEvent`. This is the most important route:

1. If a requester ID exists, send the requester a direct verification notification.
2. Dispatch `StagedNotificationService().dispatchNextBatch(e.requestId)`.
3. Execute both operations concurrently through `Future.wait`.

This route bridges local administrative verification to distributed donor notification. It changes a local app event into network fan-out.

Architecturally:

```text
Hospital admin verifies request
        |
        v
BloodRequestVerifiedEvent
        |
        +--> direct requester packet
        |
        `--> staged donor fan-out algorithm
```

### 5.5 Donation Registration Route

Lines 98-135 handle `DonationRegisteredEvent`. The engine emits:

- A gratitude packet to the donor.
- A fulfillment packet to the requester if requester ID is available.

This is a multi-recipient event fan-out. The same domain event results in two separate FCM/inbox operations.

### 5.6 Closure, Verification, and Broadcast Routes

Lines 137-141 route request closure through `sendRequestClosedNotification()`, which uses Firestore to find a donation record for the request and infer the donor target.

Lines 143-156 route donor blood group verification into a direct notification.

Lines 158-171 route SuperAdmin broadcast events into `sendEmergencyNotification()`, which performs donor segmentation and sends pure data-only emergency packets.

## 6. End-to-End Packet Flows

### 6.1 Emergency Request Verification Flow

```text
Hospital admin verifies blood request
        |
        v
BloodRequestVerifiedEvent
        |
        v
NotificationEngine._onRequestVerified()
        |
        +--> sendDirectNotification(requester, verification)
        |
        `--> StagedNotificationService.dispatchNextBatch(requestId)
                  |
                  +--> Firestore transaction on blood_requests/{requestId}
                  +--> candidate pool query
                  +--> medical eligibility filter
                  +--> ranking and top-10 selection
                  +--> atomic request metadata update
                  `--> NotificationService.sendDirectNotification(donor, emergency)
                            |
                            +--> FCM HTTP v1 data-only packet
                            +--> Firestore inbox document
                            `--> local notification on donor device
```

### 6.2 Donor Device Receive Flow

```text
FCM packet arrives on donor device
        |
        +-- foreground --> FirebaseMessaging.onMessage
        |                  |
        |                  +--> update emergency state
        |                  `--> show local notification
        |
        +-- background --> firebaseMessagingBackgroundHandler
        |                  |
        |                  `--> show local notification manually
        |
        `-- tapped/opened --> _handleRouting(data)
                              |
                              +--> update emergency state
                              `--> navigate to RequestResponseScreen
```

## 7. Technical Observations for Thesis Documentation

### Strengths

- The system uses an explicit event router, reducing the need for every screen to know transport details.
- Emergency traffic is treated as application-controlled data packets, enabling custom routing and consistent local behavior.
- Firestore provides a durable inbox channel in parallel with volatile push delivery.
- Staged notifications reduce donor overload by batching dispatches rather than broadcasting to all compatible donors at once.
- Transaction-first, side-effect-second design reduces duplicate sends caused by transaction retries.
- The donor selection algorithm incorporates medical eligibility, previous notification state, decline state, verification status, and point ranking.

### Architectural Risks and Limitations

- FCM service account credentials are assembled inside the Flutter client. This grants the edge client privileged send capability and should be described carefully as a prototype or controlled-deployment tradeoff.
- Cooldown validation compares a server-written timestamp with client-local time. This can be affected by device clock skew.
- `_fireBatchNotifications()` is scheduled as a microtask and is not awaited, so transport failures do not roll back or visibly affect the transaction result.
- Donors may be marked as notified even if an FCM HTTP call fails after the Firestore transaction commits.
- Emergency direct notifications sent through `sendDirectNotification()` are data-only, but `sendEmergencyNotification()` performs its own broadcast implementation. The code therefore has two emergency packet construction paths.
- Data-only packets require reliable background handling and local notification setup; platform-specific restrictions can affect delivery behavior.

## 8. Academic Framing

Sheryan's notification subsystem can be described as a **client-assisted distributed messaging architecture**. Instead of relying entirely on a centralized backend scheduler, the application uses Firestore as a shared coordination database and allows authenticated clients to perform edge-side scheduling and packet emission.

The most technically distinctive component is `StagedNotificationService`: it converts a blood request into a sequence of controlled donor batches. Each batch is a distributed message wave, rate-limited by Firestore metadata and materialized as FCM data packets. This design reflects an edge-computing pattern where local devices participate in orchestration while cloud services provide state synchronization and packet transport.

`NotificationEngine` supplies the event-driven routing layer, translating domain events into concrete network operations. `NotificationService` supplies the transport layer, transforming routing decisions into FCM HTTP v1 packets and durable Firestore inbox records. Together, the three files form a layered messaging subsystem:

```text
Domain Event Layer     -> NotificationEngine
Coordination Layer     -> StagedNotificationService + Firestore
Transport Layer        -> NotificationService + FCM HTTP v1
Presentation Layer     -> Local Notifications + in-app routing
```

For the graduation thesis, this subsystem should be documented not merely as "notifications", but as a distributed routing engine that uses data packets, durable inbox persistence, edge orchestration, and event-driven fan-out to coordinate emergency blood donation workflows.
