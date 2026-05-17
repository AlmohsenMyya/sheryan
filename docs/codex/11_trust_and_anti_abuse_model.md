# Trust Architecture, Verification, and Anti-Abuse Model

## 1. Executive Overview

Sheryan is not only a mobile healthcare application; it is a socio-technical routing system where incorrect trust decisions can create real-world harm. A fake emergency request can generate panic, a forged donor profile can mislead hospitals, and an unprotected reward economy can be farmed by malicious users. Therefore, the security model cannot be described only through transport security, authentication, or database access rules. The application also implements a **trust architecture**: a set of application-level mechanisms that decide when human-submitted information becomes operationally trustworthy.

The observed design can be summarized as:

> **Zero-Trust Edge with Verified Anchors**: client devices and user-entered claims are treated as untrusted edge inputs until they are promoted into verified system state by a hospital-controlled workflow and recorded in auditable Firestore documents.

This model appears across request verification, blood group verification, staged notification routing, donation logging, medical cooldown enforcement, and points redemption. The system does not fully eliminate all abuse classes, but it creates several trust gates that prevent unverified claims from immediately triggering high-impact network or economic actions.

## 2. Threat Model: Human-Centric Abuse Surface

The relevant threat surface is primarily social and operational rather than purely cryptographic:

| Abuse Class | Attack Goal | Primary Defense in Code |
|---|---|---|
| Fake emergency request | Trigger mass donor notifications and panic | Hospital verification gate before event dispatch and staged donor routing |
| Forged blood group | Become eligible for incompatible requests or gain credibility | Hospital QR-based blood group verification and verified-donor prioritization |
| Cooldown evasion | Donate repeatedly or bypass medical safety interval | Donation ledger updates `lastDonated` and locks `isLedgerLocked` |
| Empty-profile reward farming | Redeem sponsor rewards without real donation history | `hasDonated` prerequisite during sponsor QR redemption |
| Double spending of points | Redeem the same points concurrently | Firestore transaction in `deductPoints` |
| Notification spam | Repeatedly fan out the same request to donors | 30-minute cooldown, `notifiedDonorIds`, `declinedDonorIds`, and top-10 batch bounds |
| Cross-hospital abuse | Verify or fulfill requests owned by another hospital | Hospital scanner controller checks `requestData['hospitalId']` against admin profile hospital |

These controls form a layered defense model in which no single user-submitted field is sufficient to produce a trusted clinical, network, or economic outcome.

## 3. The Root of Trust: Hospital-Centric Verification

### 3.1 Hospital Admin as the Verified Anchor

The system assigns the `hospitalAdmin` role a special trust position. The hospital admin is not merely another user category; this role acts as the **institutional authority** that promotes untrusted user submissions into trusted operational events.

This is visible in two critical workflows:

1. **Blood request verification**
   - Recipient-created requests begin as pending and unverified.
   - Request creation sets the request into an initial state such as `status: pending` and `isVerified: false`.
   - The hospital admin later calls `markVerified`, either from the request-management controller or through scanner-driven verification.
   - After verification, `BloodRequestVerifiedEvent` is dispatched, which activates the notification engine and staged donor routing.

2. **Donation verification**
   - A donation is not treated as real merely because a donor claims it.
   - The hospital flow records donation completion through `DonationService.registerDonation`.
   - The repository creates a document in the root `donations` collection with `verifiedBy`, `hospitalId`, `hospitalName`, and server-side timestamp metadata.
   - The same transaction updates request fulfillment and donor cooldown state.

In trust-architecture terms, the hospital admin is the **root authority** for two forms of state promotion:

| Untrusted Input | Verified State | Trust Promoter |
|---|---|---|
| Recipient says a request is real | `blood_requests/{id}.isVerified = true` | Hospital admin |
| Donor says their blood group is valid | `users/{uid}.bloodGroupVerified = true` | Hospital admin QR verification |
| Donor says they donated | `donations/{id}` ledger record + donor cooldown update | Hospital admin / hospital workflow |
| Request says it needs fulfillment | `fulfilledUnits` and terminal status updates | Firestore transaction initiated from hospital flow |

This creates a clear trust boundary: **users may submit claims, but hospitals operationalize claims**.

### 3.2 Request Verification Before Network Fan-Out

The request lifecycle deliberately avoids immediate mass notification after a recipient creates a request. Instead, the system requires a hospital verification step before dispatching a `BloodRequestVerifiedEvent`.

The key flow is:

```text
Recipient creates request
        |
        v
Firestore stores request as pending / unverified
        |
        v
Hospital admin reviews or scans request QR
        |
        v
RequestService.markVerified(requestId)
        |
        v
NotificationEngine receives BloodRequestVerifiedEvent
        |
        v
StagedNotificationService.dispatchNextBatch(requestId)
```

This architecture prevents a compromised or malicious recipient account from directly converting a database write into a network broadcast. The request must cross a hospital-controlled trust gate before it reaches donor devices.

### 3.3 Hospital Ownership Boundary

The scanner controller adds another important RBAC boundary: a hospital admin cannot freely verify any request in the system. During QR-based request verification and donation registration, the controller reads the current admin's `hospitalId` from the profile provider and compares it with the scanned request's `hospitalId`. If the values do not match, the flow rejects the operation as an invalid hospital action.

This is a multi-tenant trust constraint:

```text
Admin profile hospitalId == request hospitalId
        |
        +-- true  -> verification or donation can continue
        |
        +-- false -> reject as cross-hospital operation
```

Therefore, the hospital admin is an anchor of trust, but only within the hospital domain assigned to that account.

## 4. Donor Integrity and Medical Tampering Defense

### 4.1 Verified Blood Attributes

The donor profile contains medically meaningful claims such as blood group, city, and last donation date. Some of these values may originate from the donor's own input, so the system distinguishes between **claimed attributes** and **verified attributes**.

The most important verified attribute is `bloodGroupVerified`. Hospital QR verification calls `UserService.markBloodGroupVerified`, converting the donor's blood group from a self-reported claim into a hospital-validated attribute.

This flag is later used inside staged routing:

- compatible donors are selected by city and blood group;
- donors already notified or declined are excluded;
- donors in the medical cooldown window are excluded;
- donors with `bloodGroupVerified == true` are sorted ahead of unverified donors;
- higher-point donors are then prioritized after verification sorting.

This does not mean unverified donors are impossible to contact, but the routing engine gives verified donors a stronger trust score. The architecture therefore supports a gradual trust model rather than a purely binary model.

### 4.2 Medical Ledger Locking

The donor medical profile contains `lastDonated` and `isLedgerLocked`. The important trust transition happens when a hospital-verified donation is registered. The donation repository updates the donor document with:

```text
lastDonated = current verified donation date
isLedgerLocked = true
```

At the UI level, `medical_history_screen.dart` reads `isLedgerLocked` and disables manual manipulation of the donation date picker when the ledger is locked. At the repository level, the lock is produced by a verified hospital donation workflow rather than by donor self-report.

This mechanism protects the medical cooldown model:

```text
Verified donation
        |
        v
Donor lastDonated updated by system
        |
        v
isLedgerLocked set to true
        |
        v
Donor cannot casually edit cooldown state through normal UI
        |
        v
StagedNotificationService filters out recently donated donors
```

From a data-integrity perspective, this is a **non-repudiation control**. Once the donation is written by the hospital workflow, the donor cannot easily deny or rewrite the cooldown state through the normal client experience.

### 4.3 Limits of the Current Lock

The current ledger lock is strong as an application-layer control, but its final authority depends on database enforcement. Because mobile clients are inherently untrusted, complete tamper resistance requires Firestore Security Rules or server-side Cloud Functions that prevent ordinary donor accounts from modifying `lastDonated`, `isLedgerLocked`, `bloodGroupVerified`, and donation-derived fields.

The correct interpretation is:

> The code implements the trust workflow and UI-level lock; the production security boundary should be enforced by database rules or backend functions.

This distinction is important academically because it separates **trust modeling** from **authoritative enforcement**.

## 5. Request Spam and Panic Mitigation

### 5.1 Hospital Gate Before Donor Notification

The first anti-spam mechanism is the hospital verification gate. User-generated requests do not directly trigger donor notification fan-out. They remain pending until a hospital admin verifies them. This significantly reduces the impact of:

- fake emergencies;
- emotionally manipulative requests;
- compromised recipient accounts;
- automated request spam;
- accidental duplicate submissions.

The hospital gate acts as a human-in-the-loop filter before the network layer becomes active.

### 5.2 Staged Notification Cooldown

After verification, Sheryan still avoids broadcasting to all compatible donors at once. The `StagedNotificationService` uses `lastNotificationSentAt` to enforce a 30-minute cooldown between notification batches.

The logic is structurally:

```text
Read request.lastNotificationSentAt
        |
        v
If last batch was less than 30 minutes ago
        |
        +-- abort batch dispatch
        |
        v
Otherwise select next eligible donor batch
```

This cooldown has two anti-abuse effects:

1. **Panic suppression**: the same request cannot repeatedly alert new donor groups in rapid succession.
2. **Network protection**: compromised clients cannot use the staged notification endpoint as a high-frequency push generator.

The cooldown is stored in Firestore using server timestamp semantics, which is stronger than a purely local timer because the batch state travels with the request document.

### 5.3 Bounded Batch Size

The staged notification engine selects only the top 10 eligible donors per batch. This bounded fan-out is a critical network-protection mechanism.

Instead of:

```text
1 verified request -> notify all compatible donors in city
```

the system performs:

```text
1 verified request -> notify top 10 eligible donors
                 -> wait for responses / cooldown
                 -> notify next bounded batch if needed
```

This limits blast radius under both legitimate high-load events and malicious request amplification. It also reduces unnecessary mobile bandwidth, FCM delivery volume, and donor fatigue.

### 5.4 Candidate Exclusion Lists

The request document maintains routing memory:

- `notifiedDonorIds`
- `declinedDonorIds`
- `lastNotificationSentAt`
- `notificationBatchCount`

These fields make the routing process stateful. A donor who already received the request is not repeatedly targeted, and a donor who declined can be replaced without turning the system into a spam loop.

This is a form of **edge routing hygiene**: the mobile orchestration layer remembers prior packet destinations and avoids duplicate notification delivery.

## 6. Gamification Security and Anti-Point Farming

### 6.1 Separation Between Profile Points and Redeemable Trust

The points system supports profile-completion and donation-related rewards. However, redemption is gated by `hasDonated`. In the sponsor scanner flow, the donor QR code is rejected if the donor document does not have `hasDonated == true`.

This is a key economic control. A user may receive low-risk profile incentives, but they cannot redeem sponsor rewards unless the account has crossed the verified donation threshold.

The trust transition is:

```text
New donor account
        |
        v
Profile completion may grant points
        |
        v
No reward redemption while hasDonated == false
        |
        v
Hospital-verified donation occurs
        |
        v
PointsService sets hasDonated = true
        |
        v
Sponsor QR redemption becomes eligible
```

This prevents "empty profile farming", where attackers create accounts, fill profile fields, and immediately redeem sponsor benefits without participating in the real donation lifecycle.

### 6.2 Donation Points Originate from Verified Workflows

The strongest points events are attached to donation registration. Donation registration is initiated from hospital-controlled flows and creates a donation ledger record. `PointsService.awardDonationPoints` is called after the donation workflow, not as a standalone donor-controlled action.

This means the economic layer inherits trust from the hospital verification layer:

```text
Hospital verifies donation
        |
        v
Donation ledger is written
        |
        v
Points are awarded
        |
        v
hasDonated becomes true
```

The reward economy is therefore not independent; it is downstream from verified healthcare events.

### 6.3 Transactional QR Redemption

Sponsor reward redemption uses `PointsService.deductPoints`, which executes inside a Firestore transaction. The transaction reads the donor document, validates the current point balance and `hasDonated`, updates the donor point total and tier, and writes a redemption document.

This protects against double-spending:

```text
Sponsor scans donor QR
        |
        v
Transaction reads donor points and hasDonated
        |
        v
If points are insufficient or hasDonated is false -> reject
        |
        v
Otherwise update points and write redemption atomically
```

If two sponsors or two devices attempt to redeem the same donor points concurrently, Firestore transaction semantics force the operations to re-read current state and serialize the final balance update. This is essential for economic consistency because points are a spendable balance.

### 6.4 Collusion and Auditability

The current design can reduce automated farming and double spending, but collusion remains a higher-level risk. For example, a sponsor operator and donor could coordinate fraudulent scans if they both control valid accounts. The existing redemption ledger helps by recording `donorId`, `sponsorId`, `rewardId`, `rewardTitle`, `pointsDeducted`, and timestamp metadata, making post-event audit possible.

Recommended future controls include:

- anomaly detection for repeated sponsor-donor pairs;
- daily redemption limits per sponsor and donor;
- geolocation or hospital proximity checks for high-value rewards;
- manual review queues for abnormal redemption velocity;
- Cloud Function enforcement for redemption policy.

## 7. Abuse Scenario Matrix

| Scenario | Attack Description | Current Trust Response | Residual Risk |
|---|---|---|---|
| Fake blood emergency | Recipient creates false urgent request | Request remains pending until hospital verification | Pending spam can still clutter hospital review queue |
| Cross-hospital verification | Admin tries to verify another hospital's request | Scanner compares admin `hospitalId` with request `hospitalId` | Requires database rules to enforce outside UI/controller |
| Forged blood group | Donor claims a blood group without proof | `bloodGroupVerified` distinguishes verified from self-reported data | Unverified donors may still exist in candidate set |
| Cooldown evasion | Donor edits last donation date | Verified donation locks `isLedgerLocked` and updates `lastDonated` | Rules should block direct client writes to locked fields |
| Notification spam | Repeated staged dispatch attempts | 30-minute cooldown, top-10 batches, notified/declined lists | Client-side orchestration should eventually move to backend |
| Empty profile farming | User earns profile points then redeems reward | Sponsor scanner requires `hasDonated == true` | Fake verified donations require hospital account compromise |
| Point double-spend | Concurrent QR redemptions | Firestore transaction updates points and writes redemption atomically | Needs monitoring for collusive but technically valid scans |
| Fake donor QR | Non-donor QR used in hospital scanner | Scanner checks target user role is `donor` | Stronger QR signing could prevent copied/static QR abuse |

## 8. Trust State Machine

The entire platform can be modeled as a trust state machine:

```text
[Untrusted Claim]
    User submits profile field, blood request, or QR identity
        |
        v
[Pending Application State]
    Data exists in Firestore but has limited operational authority
        |
        v
[Verified Anchor Action]
    Hospital admin verifies request, blood group, or donation event
        |
        v
[Auditable System State]
    Request is verified, donation ledger is written, donor cooldown is locked
        |
        v
[Network / Economic Activation]
    Notifications dispatch, points are awarded, rewards become redeemable
```

The most important principle is that **network activation and economic activation happen after trust promotion**, not at the moment of user input.

## 9. Architectural Residual Risks and Hardening Roadmap

### 9.1 Move Trust-Critical Mutations to Cloud Functions

Several trust-critical flows are currently orchestrated from the client application. The long-term hardened design should move the following operations to Cloud Functions or another backend authority:

- request verification side effects;
- staged notification batch selection;
- donor cooldown locking;
- points awarding;
- reward redemption policy checks.

This would reduce the trust placed in mobile clients and make the zero-trust model more complete.

### 9.2 Firestore Security Rules as the Enforcement Boundary

The application logic expresses the correct trust policy, but Firestore Security Rules must enforce it. Recommended rule-level protections include:

- donors cannot set `bloodGroupVerified`;
- donors cannot unlock `isLedgerLocked`;
- donors cannot modify donation-derived `lastDonated`;
- ordinary users cannot create donation ledger records;
- only hospital admins can verify requests for their assigned `hospitalId`;
- only sponsor accounts can create redemption attempts, and only through validated transaction paths.

Without these rules, client-side code provides workflow integrity but not absolute authorization integrity.

### 9.3 Signed or Expiring QR Tokens

The current scanner flows treat scanned identifiers as meaningful IDs and then validate the corresponding Firestore user or request. A stronger future model would use signed QR payloads containing:

- subject ID;
- role or purpose;
- issued-at timestamp;
- expiration timestamp;
- nonce;
- server signature.

This would reduce copied QR abuse and make QR scans closer to cryptographic trust artifacts rather than plain identifiers.

### 9.4 Abuse Analytics

The platform should eventually maintain anti-abuse analytics over:

- request creation rate per recipient;
- verification rejection rate per hospital;
- notification batch count per request;
- declined ratio per request;
- donor redemption frequency;
- sponsor redemption velocity;
- repeated donor-sponsor pairs;
- manual override frequency.

These signals would convert the current preventive trust model into an adaptive trust model.

## 10. System Design Conclusion: Zero-Trust Edge with Verified Anchors

Sheryan's trust architecture is best described as **Zero-Trust Edge with Verified Anchors**. The mobile edge is allowed to collect data, initiate workflows, scan QR codes, and request state transitions, but the system does not treat those edge inputs as fully authoritative by default. High-impact actions require promotion through trusted anchors:

- hospital admins verify blood requests before donor routing;
- hospital workflows validate blood groups and donations;
- donation ledger records create auditable medical and economic history;
- staged notifications throttle network fan-out;
- transactional point redemption protects the reward economy from double spending.

This design is especially suitable for a socially critical healthcare platform because it recognizes that the main risks are not only technical intrusions, but also human-centric exploits: panic creation, forged medical claims, reward farming, and institutional impersonation.

The final architectural philosophy is therefore:

> Sheryan treats every user-submitted claim as an untrusted edge packet until it is verified by a hospital anchor, recorded in an auditable ledger, and only then allowed to trigger distributed messaging or economic reward flows.

