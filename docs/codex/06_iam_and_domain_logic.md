# IAM, RBAC, and Domain Logic Deep Dive

Phase 6 technical analysis of identity management, role-based access control, blood compatibility rules, and secure gamification in Sheryan.

Target files:

- `lib/core/enums/user_role.dart`
- `lib/services/auth_service.dart`
- `lib/services/points_service.dart`
- `lib/core/utils/blood_logic.dart`

Note: the requested path `lib/utils/blood_logic.dart` does not exist in the current repository. The actual implementation is located at `lib/core/utils/blood_logic.dart`.

## 1. Architectural Overview

Sheryan's IAM and domain-logic layer combines:

- **Identity Management:** Firebase Authentication establishes the authenticated user identity.
- **Application Role Metadata:** Firestore `users/{uid}` documents store role, hospital affiliation, FCM token, medical profile fields, and account metadata.
- **RBAC Model:** `UserRole` defines the role vocabulary used by the app.
- **Business Rules:** `BloodLogic` defines transfusion compatibility sets.
- **Secure Gamification:** `PointsService` uses Firestore transactions to mutate point balances and redemption records atomically.

At a high level:

```text
Firebase Auth identity
        |
        v
users/{uid} profile document
        |
        +--> role-based UI and workflow routing
        +--> hospitalId tenant binding for hospital admins
        +--> fcmToken for messaging
        +--> points/tier/hasDonated gamification state
        `--> medical profile data
```

## 2. Role-Based Access Control (RBAC)

### 2.1 Role Vocabulary

`user_role.dart` defines the role universe:

```dart
enum UserRole {
  donor,
  recipient,
  hospitalAdmin,
  superAdmin,
  sponsorOrg,
}
```

This enum is small but important. It gives the application a normalized internal representation for access contexts:

| Role | Domain meaning |
|---|---|
| `donor` | Can view donor-facing emergency requests, profile, rewards, and donation-related flows |
| `recipient` | Can create blood requests and search donors |
| `hospitalAdmin` | Can verify requests, register donations, scan donors, and operate inside a hospital context |
| `superAdmin` | Can manage system-level administrative entities and broadcasts |
| `sponsorOrg` | Can manage rewards and redemption-related sponsor workflows |

The enum itself does not enforce permissions. It defines the RBAC vocabulary used by providers, routing, dashboards, and controllers.

### 2.2 Identity Creation and Profile Binding

`AuthService.registerUser()` creates the Firebase Auth account and then writes an application profile document.

The identity workflow is:

```text
email/password registration
        |
        v
FirebaseAuth.createUserWithEmailAndPassword()
        |
        v
users/{uid}.set(...)
```

The Firestore profile includes:

```text
uid
name
email
bloodGroup
city
role
phone
lastDonated
hospitalId
hasDonated
fcmToken
createdAt
```

The `uid` is the primary binding between Firebase Authentication and the Firestore user record. The `role` field is the RBAC claim used by the app layer. The `hospitalId` field is the tenant boundary attribute for hospital administrators.

### 2.3 Multi-Tenant Boundary Attributes

The most important RBAC fields written by `auth_service.dart` are:

```text
role
hospitalId
uid
```

Their intended security semantics are:

- `uid`: identifies the authenticated principal.
- `role`: identifies the authorization class.
- `hospitalId`: scopes hospital-admin operations to one hospital tenant.

For a hospital administrator, `hospitalId` acts as a tenant key:

```text
hospitalAdmin principal
        |
        v
users/{uid}.hospitalId
        |
        v
allowed hospital-scoped data
```

This is the foundation for multi-tenant isolation. Hospital admins should only operate on requests, donations, scanner workflows, and dashboard data associated with their hospital.

### 2.4 FCM Token as Identity-Adjacent Routing Metadata

During registration and login, `AuthService` stores or updates `fcmToken`.

Registration:

```text
FirebaseMessaging.getToken()
users/{uid}.fcmToken = token
```

Login:

```text
FirebaseMessaging.getToken()
users/{uid}.update(fcmToken, lastLogin)
```

This binds an authenticated account to a current messaging endpoint. It is not an authorization primitive, but it is identity-adjacent routing metadata used by the notification subsystem.

### 2.5 RBAC Enforcement Reality

The target files establish the RBAC data model, but they do not by themselves provide complete access enforcement. They:

- define roles,
- write the selected role to Firestore,
- attach hospital admins to a `hospitalId`,
- update login metadata,
- expose identity state through Firebase Auth.

Strict enforcement must be completed by:

- Riverpod role-aware routing,
- feature dashboards,
- service/query filters,
- Firestore Security Rules,
- and, ideally, backend validation for privileged operations.

For thesis accuracy, the current code should be described as:

```text
application-level RBAC metadata and role-aware workflow separation,
requiring Firestore Security Rules for authoritative server-side enforcement.
```

This is an important distinction. Client code can guide users into the correct role-specific workflows, but hard security boundaries must exist in the database rules layer because modified clients can bypass UI checks.

## 3. Blood Compatibility Algorithm

### 3.1 Domain Representation

`blood_logic.dart` defines the complete ABO/Rh blood group set:

```text
A+, A-, B+, B-, AB+, AB-, O+, O-
```

This is represented as:

```dart
static const List<String> allTypes = [
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
];
```

The service provides two directional compatibility mappings:

1. `getCompatibleDonors(recipientType)`
2. `getCompatibleRecipients(donorType)`

These are inverse-oriented lookup tables.

### 3.2 Compatible Donor Function

`getCompatibleDonors(String recipientType)` returns the donor blood types that can donate to a recipient.

The mapping is:

| Recipient | Compatible donors |
|---|---|
| `AB+` | all blood types |
| `AB-` | `AB-`, `A-`, `B-`, `O-` |
| `A+` | `A+`, `A-`, `O+`, `O-` |
| `A-` | `A-`, `O-` |
| `B+` | `B+`, `B-`, `O+`, `O-` |
| `B-` | `B-`, `O-` |
| `O+` | `O+`, `O-` |
| `O-` | `O-` |

This follows the standard red blood cell compatibility logic:

- `O-` is the universal red-cell donor.
- `AB+` is the universal red-cell recipient.
- Rh-negative recipients cannot receive Rh-positive blood.
- ABO compatibility restricts donor antigens against recipient antibodies.

Mathematically, this function is a lookup over a compatibility relation:

```text
CanDonateTo(donorType, recipientType) = true
```

`getCompatibleDonors(recipientType)` returns:

```text
{ donorType | CanDonateTo(donorType, recipientType) }
```

### 3.3 Compatible Recipient Function

`getCompatibleRecipients(String donorType)` returns recipient blood types that can receive from a donor.

The mapping is:

| Donor | Compatible recipients |
|---|---|
| `O-` | all blood types |
| `O+` | `O+`, `A+`, `B+`, `AB+` |
| `A-` | `A-`, `A+`, `AB-`, `AB+` |
| `A+` | `A+`, `AB+` |
| `B-` | `B-`, `B+`, `AB-`, `AB+` |
| `B+` | `B+`, `AB+` |
| `AB-` | `AB-`, `AB+` |
| `AB+` | `AB+` |

This function is useful for donor-facing request discovery. Instead of asking "who can donate to this recipient?", it asks "which recipients can this donor help?"

Mathematically:

```text
getCompatibleRecipients(donorType)
    = { recipientType | CanDonateTo(donorType, recipientType) }
```

### 3.4 Perfect Match Predicate

`isPerfectMatch(type1, type2)` returns:

```text
type1 == type2
```

This is not a broad compatibility check. It only identifies exact blood group equality.

### 3.5 Algorithmic Character

The blood compatibility algorithm is deterministic, finite, and table-driven:

- constant input domain,
- constant output sets,
- no network dependency,
- O(1) switch lookup over eight possible types,
- safe fallback to `[inputType]` for unknown values.

In thesis terminology, it is a rule-based medical decision function encoded as static domain logic.

## 4. Gamification Engine: Points System

### 4.1 Points Event Taxonomy

`PointsEvent` defines gamification event identifiers:

```text
account_created
basic_info_complete
health_info_complete
medical_history_complete
emergency_contact_complete
blood_group_verified
profile_100_bonus
donation_registered
consecutive_donation_bonus
blood_rarity_bonus
emergency_donation_bonus
general_donation
```

These event strings are stored in the user's `pointsHistory` subcollection. They function as a ledger event type system.

### 4.2 Points Value Table

`PointsValue` defines the reward schedule:

| Event | Points |
|---|---:|
| Account created | 20 |
| Basic info complete | 30 |
| Health info complete | 30 |
| Medical history complete | 20 |
| Emergency contact complete | 20 |
| Blood group verified | 100 |
| Profile complete | 50 |
| Verified donation | 200 |
| General donation | 150 |
| Consecutive donation | 50 |
| Rare blood type bonus | 100 |
| Emergency donation bonus / multiplier concept | 200 |

The point schedule encodes business incentives:

- reward profile completeness,
- reward medical verification,
- reward donation events,
- reward emergency participation,
- reward rare blood group availability,
- reward repeated donations.

### 4.3 Tier Function

`tierForPoints(int points)` maps a numeric score into a status tier:

```text
>= 2000 -> platinum
>= 1000 -> gold
>= 500  -> silver
else    -> bronze
```

This is a deterministic classification function:

```text
tier = f(points)
```

It is recalculated whenever points are awarded or deducted.

## 5. Secure Points Increment Transactions

### 5.1 `awardPoints()` Transaction

`awardPoints()` is the central points increment method.

It creates:

- `userRef = users/{uid}`
- `historyRef = users/{uid}/pointsHistory/{autoId}`

Then it runs a Firestore transaction:

```text
1. Read users/{uid}
2. Read current points
3. Compute newTotal = current + points
4. Compute tier = tierForPoints(newTotal)
5. Update user points and tier
6. Optionally set hasDonated = true for donation_registered
7. Create immutable history event document
```

This protects against lost updates when multiple events award points concurrently.

Without a transaction:

```text
Event A reads points = 200
Event B reads points = 200
Event A writes 230
Event B writes 300
```

One increment can be lost.

With transaction semantics:

```text
Event A reads 200 -> writes 230
Event B retries -> reads 230 -> writes 330
```

The user's points balance and point-history record are committed as one logical unit.

### 5.2 Ledger Integrity

The `pointsHistory` document includes:

```text
event
points
descriptionAr
descriptionEn
total
createdAt
```

The `total` field stores the post-transaction balance. This makes each history entry a ledger snapshot, not merely a delta.

The `createdAt` field uses `FieldValue.serverTimestamp()`, giving the ledger a server-side time anchor.

The resulting invariant is:

```text
points balance update
    <=> pointsHistory event creation
```

This is important for auditability and dispute resolution.

## 6. Profile Milestone Business Rules

`checkAndAwardProfileMilestones()` computes profile completion conditions:

- basic info complete,
- health info complete,
- medical history complete,
- emergency contact complete,
- blood group verified,
- complete profile bonus.

Before awarding each one-time milestone, it calls `hasEarnedEvent(uid, event)`.

This attempts to enforce:

```text
one milestone event -> one award
```

Important implementation note: the duplicate check and later `awardPoints()` call are separate operations. `awardPoints()` itself does not check uniqueness of event types. Under unusual concurrent calls, duplicate milestone awards may still be possible unless additional uniqueness constraints or transaction-level event checks are added.

For thesis accuracy, this can be described as application-level duplicate prevention, with transaction-secured balance mutation.

## 7. Donation Reward Logic

`awardDonationPoints()` begins with base donation points:

```text
base = 200
```

It then applies:

- emergency multiplier: base points doubled when `isEmergency == true`,
- rare blood type bonus: +100 if donor blood group is one of `O-`, `AB-`, `B-`, `A-`,
- consecutive donation bonus: +50 if previous donation exists.

The method then delegates actual balance mutation to `awardPoints()`, preserving transaction safety for each award event.

Logical flow:

```text
donation verified
        |
        v
calculate donation score
        |
        v
awardPoints(donation_registered)
        |
        +--> update users/{uid}.points
        +--> update users/{uid}.tier
        +--> set hasDonated = true
        `--> append pointsHistory entry
        |
        v
if previous donation exists:
        awardPoints(consecutive_donation_bonus)
```

## 8. Secure Reward Redemption

### 8.1 `deductPoints()` Transaction

`deductPoints()` handles point redemption for sponsor rewards.

It accepts:

- donor UID,
- sponsor UID,
- reward ID,
- reward title,
- required points.

Inside a Firestore transaction:

```text
1. Read users/{donorUid}
2. Read current points
3. Read hasDonated flag
4. Reject if current < pointsRequired
5. Reject if hasDonated == false
6. Compute newTotal = current - pointsRequired
7. Compute new tier
8. Update user points and tier
9. Create redemptions/{autoId}
10. Return success
```

This prevents race conditions where two reward redemptions spend the same points simultaneously.

Without a transaction:

```text
Reward A reads 500 points
Reward B reads 500 points
Reward A deducts 400 -> 100
Reward B deducts 400 -> 100
```

The user receives two rewards while only paying once.

With transaction conflict detection:

```text
Reward A reads 500 -> writes 100
Reward B retries -> reads 100 -> rejects
```

This is secure gamification: the balance check and deduction are atomic.

### 8.2 Redemption Audit Record

The redemption document stores:

```text
donorId
sponsorId
rewardId
rewardTitle
pointsDeducted
redeemedAt
```

`redeemedAt` uses `FieldValue.serverTimestamp()`. This makes redemption events auditable and prevents relying on client-local time.

## 9. Business Rule Security Observations

### Strengths

- Points increment and redemption use Firestore transactions.
- Point balance and tier are updated together.
- Points history creates an auditable event ledger.
- Reward redemption checks both point sufficiency and donation eligibility.
- Blood compatibility logic is deterministic and centralized.
- RBAC roles are normalized into a fixed enum.
- User profile documents bind authentication identity to role, tenant, and FCM routing data.

### Limitations

- `AuthService.registerUser()` accepts `role` as an input parameter. Strict production RBAC should prevent ordinary users from self-registering as privileged roles unless controlled by admin workflows or security rules.
- `hospitalId` is written to the user profile, but true multi-tenant isolation requires Firestore Security Rules or backend checks that compare the authenticated user's hospitalId against the target resource.
- `PointsService.hasEarnedEvent()` duplicate checks are outside the award transaction, so one-time milestone awards are not fully race-proof under concurrent execution.
- A module-level client implementation can guide and structure authorization, but cannot be the final security boundary against modified clients.

## 10. Academic Framing

Sheryan's IAM layer can be described as Firebase Auth identity plus Firestore-backed RBAC metadata. The application defines a fixed role vocabulary and binds each authenticated user to role-specific attributes such as `hospitalId`, blood group, city, and FCM token. This enables role-aware workflows and tenant-scoped behavior.

The blood compatibility layer is a deterministic business-rule engine. It encodes ABO/Rh transfusion compatibility as finite lookup tables, allowing both recipient-centric donor discovery and donor-centric request discovery.

The gamification layer is a transaction-protected points economy. Point awards and reward redemptions are implemented as atomic Firestore transactions to prevent lost updates and double spending. The points history and redemption collections act as audit ledgers for the incentive system.

For the thesis, the combined model can be summarized as:

```text
Identity Management      -> Firebase Auth + users/{uid}
RBAC Metadata            -> UserRole + role/hospitalId fields
Medical Business Rules   -> BloodLogic compatibility relation
Secure Gamification      -> PointsService transactions + history ledger
Auditability             -> server timestamps + event records
```

This architecture demonstrates how a healthcare-oriented Flutter/Firebase application can combine identity metadata, role-aware workflows, deterministic domain rules, and transaction-protected incentive mechanisms.
