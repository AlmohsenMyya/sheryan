# Scalability and Network Traffic Model

Phase 10 cloud systems engineering analysis of Sheryan under high-load conditions, such as a natural disaster scenario with 100,000 concurrent users.

Primary subsystems:

- Firestore NoSQL data model
- `NotificationEngine`
- `StagedNotificationService`
- `NotificationService`
- `FirebaseDonationRepository.registerDonationBatch`
- `PointsService`

This document focuses on throughput, latency, contention, network bandwidth, and cloud operation cost.

## 1. System Load Model

In a normal day, Sheryan behaves like a moderate mobile CRUD and notification application. During a disaster, the load profile changes:

```text
100,000 concurrent users
        |
        +-- many donors receiving emergency alerts
        +-- recipients creating urgent requests
        +-- hospital admins verifying requests
        +-- hospital admins registering donations
        +-- donors opening request response screens
        +-- sponsors/rewards traffic remains secondary
```

The high-stress workflows are:

1. Hospital verifies a blood request.
2. Staged notification routing selects and notifies donors.
3. Many donor clients read request details.
4. Multiple hospital admins register donations against the same request.

The main cloud resources under pressure are:

- Firestore document reads,
- Firestore document writes,
- Firestore transaction retries,
- FCM HTTP v1 sends,
- mobile uplink/downlink bandwidth,
- Firestore listener fan-out.

## 2. Network Traffic and Payload Efficiency

### 2.1 Data-Only FCM Payloads

Emergency notifications use a data-only payload shape. The packet contains routing and display data:

```json
{
  "message": {
    "token": "<fcm-token>",
    "data": {
      "requestId": "<request-id>",
      "type": "emergency",
      "bloodGroup": "O-",
      "titleEn": "Emergency Blood Request",
      "titleAr": "...",
      "bodyEn": "Urgent! O- blood needed in ...",
      "bodyAr": "...",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    }
  }
}
```

Compared with a full Firestore document read, this packet is compact. It carries only:

- route key,
- message type,
- medical matching hint,
- bilingual display text,
- click action.

Approximate payload size:

```text
requestId                  20-40 bytes
type/bloodGroup/action      40-80 bytes
English title/body          80-180 bytes
Arabic title/body           120-300 bytes UTF-8 dependent
JSON key overhead           150-250 bytes
FCM wrapper overhead        100-200 bytes
---------------------------------------------
Estimated logical payload   ~500-1,000 bytes
```

On 3G/4G mobile networks, keeping the emergency packet near the sub-kilobyte range is valuable because it reduces:

- radio transmission time,
- packet loss sensitivity,
- app wake-up cost,
- mobile data usage,
- time to first notification display.

### 2.2 Data-Only vs Notification Payload

A notification payload delegates display to the operating system. A data-only payload gives the app control over:

- local notification rendering,
- emergency state cache update,
- request routing,
- bilingual fallback handling,
- foreground state refresh.

From a bandwidth perspective, the data-only model avoids sending redundant OS notification metadata and application data separately for emergency traffic. The same small data packet acts as both:

```text
routing header + display payload
```

### 2.3 NoSQL Denormalization and Mobile Latency

Firestore documents intentionally duplicate display fields:

```text
blood_requests.hospital
donations.hospitalName
rewards.sponsorName
redemptions.rewardTitle
```

This reduces client read amplification.

Without denormalization:

```text
Open request card
    -> read blood_requests/{requestId}
    -> read hospitals/{hospitalId}
    -> maybe read users/{requesterId}
```

With denormalization:

```text
Open request card
    -> read blood_requests/{requestId}
```

For mobile networks, this matters because extra document reads mean:

- more round trips,
- more TLS/HTTP2 stream activity,
- higher tail latency,
- more billable reads,
- more UI loading states.

In NoSQL systems, duplicating a small string such as `hospitalName` is cheaper than forcing every client to execute another remote read. This is especially important during disaster traffic where thousands of users may open the same request details over constrained mobile links.

### 2.4 Request Document as an Aggregate Packet

The `blood_requests` document stores:

```text
patientName
hospital / hospitalId
city
bloodGroup
requiredUnits
fulfilledUnits
status
isVerified
phone
neededAt
notifiedDonorIds
declinedDonorIds
notificationBatchCount
lastNotificationSentAt
```

This document is an aggregate state packet. It gives donor and hospital screens enough information to render lifecycle state without scanning donations, hospitals, or notification logs.

Tradeoff:

- Better read latency.
- More writes to one aggregate document.
- Higher contention risk under simultaneous updates.

## 3. Firestore Read/Write Cost Model

This section models the workflow "Hospital verifies a donation." In the app, this means a hospital admin confirms that a donor fulfilled a request. The core path is:

```text
ManualFulfillDialog / scanner
        |
        v
HospitalRequestsController.completeManualDonation()
        |
        v
DonationService.registerDonation()
        |
        v
FirebaseDonationRepository.registerDonationBatch()
        |
        v
PointsService.awardDonationPoints()
        |
        v
NotificationEngine.dispatch(DonationRegisteredEvent)
```

Exact counts vary because the notification path depends on requester ID, existing FCM token, and donation history. The model below separates minimum and expanded cost.

## 3.1 Core Donation Registration Transaction

`registerDonationBatch()` transaction:

```text
Read:
1. blood_requests/{requestId}

Writes:
1. update blood_requests/{requestId}
2. update users/{donorId}
3. create donations/{donationId}
```

Estimated Firestore operations:

```text
Reads  = 1
Writes = 3
```

What is updated:

- `fulfilledUnits`,
- `status`,
- donor `lastDonated`,
- donor `isLedgerLocked`,
- donation audit document.

Scalability value:

- request counter and status are updated atomically,
- no separate query is needed to count donations,
- no scan is needed to decide partial vs complete.

## 3.2 Post-Transaction Reads

After the transaction, `DonationService.registerDonation()` reads:

```text
1. users/{donorId}
2. blood_requests/{requestId}
```

Estimated operations:

```text
Reads = 2
```

Purpose:

- get donor blood group,
- determine if request is urgent,
- get requester ID for notification event.

Optimization opportunity:

Some of this data is already known by the workflow or could be returned from transaction state, reducing post-transaction reads.

## 3.3 Points Award Transaction

`PointsService.awardDonationPoints()` calls `awardPoints()` for donation registration.

Base award transaction:

```text
Reads:
1. users/{donorId}

Writes:
1. update users/{donorId}.points/tier/hasDonated
2. create users/{donorId}/pointsHistory/{eventId}
```

Estimated operations:

```text
Reads  = 1
Writes = 2
```

Then the code checks previous donation history:

```text
users/{donorId}/pointsHistory where event == donation_registered limit 1
```

Estimated:

```text
Reads = 0 or 1 returned document
```

If a consecutive donation bonus applies, another `awardPoints()` transaction occurs:

```text
Reads  = 1
Writes = 2
```

Therefore points cost:

```text
Minimum:
Reads  = 1 user transaction read + up to 1 history query read
Writes = 2

With consecutive bonus:
Reads  = 2 user transaction reads + up to 1 history query read
Writes = 4
```

## 3.4 Notification Event Cost

`DonationRegisteredEvent` may send:

1. a thank-you notification to the donor,
2. a fulfillment notification to the requester if requester ID exists.

Each direct notification performs:

```text
Read:
1. users/{targetUid} to get fcmToken

Writes:
1. users/{targetUid}/notifications/{notificationId}

Network:
1. FCM HTTP v1 POST, if fcmToken exists
```

For two targets:

```text
Reads  = 2
Writes = 2
FCM sends = 2
```

If requester ID is missing:

```text
Reads  = 1
Writes = 1
FCM sends = 1
```

## 3.5 Total Theoretical Cost: Donation Verification

Minimum likely path:

```text
Core donation transaction       Reads 1, Writes 3
Post-transaction donor/request  Reads 2, Writes 0
Donation points                 Reads 1-2, Writes 2
Notifications, donor only       Reads 1, Writes 1, FCM 1
--------------------------------------------------------
Approx total                    Reads 5-6, Writes 6, FCM 1
```

Expanded path with requester notification and consecutive bonus:

```text
Core donation transaction       Reads 1, Writes 3
Post-transaction donor/request  Reads 2, Writes 0
Donation points + bonus         Reads 2-3, Writes 4
Notifications, donor+requester  Reads 2, Writes 2, FCM 2
--------------------------------------------------------
Approx total                    Reads 7-8, Writes 9, FCM 2
```

These counts do not include:

- active snapshot listeners that are re-billed when documents change,
- security rule document reads,
- retry costs if a transaction conflicts,
- index write amplification,
- client-side reads caused by UI refresh.

## 4. Cost Model: Hospital Verifies Request and Staged Notification

A separate high-load workflow is request verification:

```text
Hospital Admin verifies request
        |
        v
blood_requests/{requestId}.isVerified = true
        |
        v
NotificationEngine
        |
        v
StagedNotificationService.dispatchNextBatch()
```

Approximate core operations:

```text
markVerified:
Writes = 1

notify requester:
Reads = 1 user
Writes = 1 notification
FCM = 1

staged transaction:
Reads = 1 blood_request
Reads = up to N compatible donor query results
Writes = 1 blood_request update

batch notification to 10 donors:
For each donor:
  Reads = 1 user document for sendDirectNotification token lookup
  Writes = 1 user notification document
  FCM = 1
```

If the compatible donor query returns 500 donors but only 10 are selected, the current client-side ranking still reads the candidate pool returned by `UserService.getCompatibleDonors()`.

This is a potential scale issue:

```text
large candidate pool -> high Firestore reads -> high mobile downlink -> client CPU sorting
```

## 5. Architectural Bottlenecks

### 5.1 Single Document Contention

Firestore documentation warns that high read/write rates to a single document can cause high latency and contention errors. The exact maximum update rate for a single document depends on workload, index configuration, and write shape. Older engineering rules often cite approximately one sustained write per second per document; the current official guidance is more nuanced: load-test and avoid hot documents.

In Sheryan, hot documents can appear at:

```text
blood_requests/{requestId}
```

because both systems update it:

- `StagedNotificationService.dispatchNextBatch()`,
- `StagedNotificationService.declineRequestSlot()`,
- `registerDonationBatch()`,
- `markVerified()`,
- `updateStatus()`.

Under disaster load, one request may attract:

- many donor declines,
- many hospital admin actions,
- repeated staged batches,
- multiple donation confirmations.

These all converge on one document.

### 5.2 Contention in StagedNotificationService

`StagedNotificationService` uses `blood_requests/{requestId}` as a coordination lock. It reads and updates:

```text
notifiedDonorIds
declinedDonorIds
lastNotificationSentAt
notificationBatchCount
isVerified
```

This design is safe for correctness but can bottleneck throughput.

Example contention scenario:

```text
50 donors decline the same request in a short time window
        |
        v
50 clients call declineRequestSlot()
        |
        v
50 transactions attempt to update blood_requests/{requestId}
        |
        v
Firestore retries some transactions
        |
        v
latency increases; some operations may fail after retry exhaustion
```

Retry behavior protects consistency, but it does not create infinite throughput. It trades failures/lost updates for latency and possible contention aborts.

### 5.3 Contention in registerDonationBatch

`registerDonationBatch()` is also centered on:

```text
blood_requests/{requestId}
```

For partial fulfillment, every donation increments:

```text
fulfilledUnits
```

If many hospital nodes register donations against the same request simultaneously:

```text
Node A reads fulfilledUnits = x
Node B reads fulfilledUnits = x
Node C reads fulfilledUnits = x
```

Firestore will retry conflicting transactions so each successful commit sees the latest value. However, under heavy concurrency this creates:

- transaction retries,
- increased completion latency,
- possible `ABORTED: Too much contention` errors,
- repeated reads billed for retried attempts.

The transaction is correct, but the single request document is a throughput ceiling.

### 5.4 Large Array Fields

The request document stores:

```text
notifiedDonorIds
declinedDonorIds
```

as arrays.

This is convenient at small scale, but for large emergency events:

- arrays grow over time,
- document size grows,
- every update rewrites index/document metadata,
- membership checks are client-side in memory,
- the document approaches Firestore document size limits if abused.

A disaster request that touches thousands of donors should not keep all routing state in one document forever.

### 5.5 Client-Side Edge Orchestration Bandwidth

The current staged notification algorithm runs on the client. That means the client performing dispatch downloads the donor candidate pool, sorts it, and sends FCM HTTP requests.

At small scale this is pragmatic. At disaster scale it creates:

- high mobile downlink for donor candidate reads,
- high mobile uplink for FCM HTTP calls,
- battery pressure,
- variable latency depending on client network quality,
- service account exposure risk,
- inconsistent performance across devices.

Cloud-side orchestration would reduce mobile bandwidth and make latency more predictable.

### 5.6 Listener Fan-Out

Firestore real-time listeners are useful, but at 100,000 concurrent users they can become expensive:

```text
one write to popular document/query
        |
        v
many active listeners receive updates
        |
        v
many billable document change reads
```

If many donors are watching request lists or notification inboxes, each request update can fan out into many client updates.

## 6. Network Bandwidth Model Under Disaster Load

Assume one verified emergency request triggers one staged batch of 10 donors.

Per batch:

```text
1 request transaction
candidate donor query
10 direct notifications
10 FCM HTTP POSTs
10 notification inbox writes
```

If each FCM data packet is about 0.5-1.0 KB logical JSON:

```text
10 donors  -> ~5-10 KB payload body
1,000 donors in waves -> ~500 KB-1 MB payload body
```

This is efficient for downlink delivery. The bigger risk is not FCM packet size; it is:

```text
candidate pool reads + client-side orchestration + Firestore listener fan-out
```

Denormalization helps because once a donor opens a request, one request document contains most rendering data.

## 7. Current Optimizations Already Present

### 7.1 Batch Size Limiting

Staged notification selects up to 10 donors per dispatch. This reduces:

- initial blast radius,
- FCM sends per event,
- notification fatigue,
- write pressure on notification inboxes.

### 7.2 Cooldown Window

`lastNotificationSentAt` enforces a 30-minute cooldown between batches. This rate-limits:

- donor notification fan-out,
- request document updates,
- repeated FCM waves.

### 7.3 Denormalized Read Model

The request document stores enough data for UI rendering. This lowers:

- mobile round trips,
- document reads per screen,
- latency over 3G/4G.

### 7.4 Transaction Before Side Effects

Staged notifications commit routing state before sending FCM. Donation registration commits data integrity state before notification/points continuation.

This reduces duplicated side effects during transaction retries.

## 8. Future Scalability Roadmap

### Upgrade 1: Move Staged Notification Orchestration to Cloud Functions

Current:

```text
Flutter client reads donor pool
Flutter client ranks donors
Flutter client writes request state
Flutter client sends FCM HTTP v1
```

Future:

```text
Cloud Function / Cloud Run worker reads donor pool
worker ranks donors near Firestore
worker writes request state
worker sends FCM using server credentials
```

Benefits:

- lower mobile bandwidth,
- lower client battery cost,
- lower latency variance,
- service account stays server-side,
- easier retry/backoff,
- centralized observability.

### Upgrade 2: Replace Large Arrays with Routing Subcollections

Current:

```text
blood_requests/{requestId}.notifiedDonorIds = [...]
blood_requests/{requestId}.declinedDonorIds = [...]
```

Future:

```text
blood_requests/{requestId}/routing/{donorId}
  status = notified | declined | accepted | expired
  batchNumber
  notifiedAt
  respondedAt
```

Benefits:

- avoids unbounded array growth,
- distributes writes across many documents,
- supports per-donor audit trail,
- enables query-based routing analytics,
- reduces hot-document pressure.

### Upgrade 3: Sharded Counters and Aggregate Documents

Current:

```text
blood_requests/{requestId}.fulfilledUnits
notificationBatchCount
```

Future for extreme load:

```text
blood_requests/{requestId}/fulfillmentShards/{shardId}
blood_requests/{requestId}/routingBatchShards/{shardId}
```

or a server-owned aggregate updated asynchronously.

Benefits:

- reduces contention on one request document,
- supports higher write throughput,
- keeps user-facing aggregate eventually consistent,
- improves disaster-scale resilience.

### Upgrade 4: Precomputed Donor Segments

Current:

```text
query users by role + city + bloodGroup
sort compatible donors client-side
```

Future:

```text
donor_segments/{city}_{bloodGroup}/members/{uid}
```

or BigQuery/Cloud Run based matching indexes.

Benefits:

- faster donor lookup,
- smaller reads per dispatch,
- easier batching,
- improved throughput during regional emergencies.

## 9. Final Scalability Assessment

Sheryan's current architecture is efficient for moderate load because it uses:

- compact data-only FCM packets,
- denormalized Firestore documents,
- staged donor batches,
- cooldown-based rate limiting,
- transactions for correctness,
- durable inbox records.

At massive scale, the likely bottlenecks are not payload size. The likely bottlenecks are:

```text
single-document contention
large candidate pool reads
client-side orchestration bandwidth
Firestore listener fan-out
unbounded array growth
transaction retries under hot-document pressure
```

The current design favors correctness and simplicity. The next scalability step is to move orchestration from mobile clients to cloud workers, distribute hot routing state across subcollections or shards, and keep mobile devices focused on receiving compact packets and rendering denormalized request state.

## 10. Sources

Official Firebase documentation used to verify current Firestore scaling guidance:

- [Cloud Firestore best practices](https://firebase.google.com/docs/firestore/best-practices)
- [Understand reads and writes at scale](https://firebase.google.com/docs/firestore/understand-reads-writes-scale)
- [Transaction serializability and isolation](https://firebase.google.com/docs/firestore/transaction-data-contention)
- [Cloud Firestore quotas and limits](https://firebase.google.com/docs/firestore/quotas)
