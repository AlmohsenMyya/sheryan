# Hospital Admin Dashboard — Phase 1 Implementation

**Date:** 2026-05-02  
**Branch:** main  
**Commit scope:** `lib/screens/hospital/hospital_dashboard.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`

---

## Overview

Phase 1 transforms the Hospital Admin dashboard from a single-purpose QR scanner launcher into a full request-management and donation-tracking interface. Four features were delivered:

1. **Stats Bar** — live, real-time counters at the top of the screen
2. **Tappable Request Detail Sheet** — every request card opens a full-detail bottom sheet
3. **Manual Status Override** — hospital admins can verify or fulfil a request without a QR scan
4. **Donation History Tab** — a second tab showing all donations recorded at the hospital

---

## Architecture Changes

### Widget tree (before → after)

```
Before:
HospitalDashboard (ConsumerWidget)
  └─ Scaffold > Column
       ├─ 3 ElevatedButton (scanner launchers)
       └─ StreamBuilder > ListView > simple ListTile

After:
HospitalDashboard (ConsumerStatefulWidget + SingleTickerProviderStateMixin)
  └─ Scaffold (AppBar + TabBar)
       └─ Column
            ├─ _StatsBar              ← NEW
            ├─ Divider
            └─ TabBarView
                 ├─ Tab 0: _RequestsTab        ← REBUILT
                 │    ├─ Action button row (3 buttons)
                 │    └─ StreamBuilder > ListView > _RequestCard (tappable)
                 │         └─ [onTap] → _RequestDetailSheet  ← NEW
                 │              └─ [button] → _ManualFulfillDialog  ← NEW
                 └─ Tab 1: _DonationHistoryTab  ← NEW
```

### State management

| Widget | Type | Reason |
|---|---|---|
| `HospitalDashboard` | `ConsumerStatefulWidget` | Needs `TabController` (vsync) |
| `_RequestDetailSheet` | `ConsumerStatefulWidget` | Tracks `_loading` bool for verify button |
| `_ManualFulfillDialog` | `StatefulWidget` | `_donorIdCtrl`, `_donorName`, `_loading` |
| Everything else | `StatelessWidget` | No local mutable state needed |

---

## Feature 1: Stats Bar (`_StatsBar`)

### Location
Top of the dashboard body, above the `TabBarView`, always visible regardless of active tab.

### Implementation

```dart
class _StatsBar extends StatelessWidget {
  final String hospitalId;
  Stream<int> _count(Query q) => q.snapshots().map((s) => s.docs.length);
  ...
}
```

Four `_HospitalStatCard` widgets arranged in a `Row`, each powered by its own Firestore stream:

| Card | Label key | Firestore query |
|---|---|---|
| Total | `totalRequests` | `blood_requests` where `hospitalId == myId` |
| Pending | `openRequests` | + `status == 'pending'` |
| Verified | `verifiedLabel` | + `isVerified == true` |
| Fulfilled | `fulfilledLabel` | + `status in ['done', 'completed']` |

### Design
- Background: `color.withOpacity(0.07)`, border: `color.withOpacity(0.2)`
- Icon + large bold number + small label below
- Cards are `Expanded` so they fill the row equally at any screen width
- Numbers display `'…'` while the stream hasn't emitted yet

### Data notes
- **Verified count** includes fulfilled ones (all fulfilled were verified first). This is intentional — it shows the cumulative verification throughput.
- The `whereIn` clause for fulfilled (`['done', 'completed']`) handles both status values used across app versions.

---

## Feature 2: Tappable Request Card & Detail Sheet

### `_RequestCard` changes
Each card in the requests list is now wrapped in `InkWell`. Tapping calls `_showDetailSheet(context)` which opens a `DraggableScrollableSheet` via `showModalBottomSheet`.

**Visual indicators on the card:**
- Blood group badge (red box, top-left)
- Urgent pill badge (red outline, top-right of patient name row)
- Status icon (right side): `Icons.pending` orange / `Icons.verified` blue / `Icons.check_circle` green

### `_RequestDetailSheet`

```dart
class _RequestDetailSheet extends ConsumerStatefulWidget { ... }
```

Opened via:
```dart
showModalBottomSheet(
  isScrollControlled: true,
  useSafeArea: true,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
  builder: (_) => _RequestDetailSheet(...),
);
```

**Content displayed:**
| Field | Source |
|---|---|
| Status chip | `status` field + `isVerified` flag |
| Urgent badge | `isUrgent` field |
| Blood group (hero) | `bloodGroup` field |
| Patient name | `patientName` field |
| Units required | `units` field |
| City | `city` field |
| Request date | `createdAt` Timestamp → formatted `dd/MM/yyyy HH:mm` |
| Contact phone | `phone` or `contactPhone` field (whichever is present) |

**`_StatusChip` widget:**
- `done` / `completed` → green, uses `l10n.statusCompleted`
- `verified` (isVerified==true) → blue, uses `l10n.statusVerified`
- default → orange, uses `l10n.statusUnverified`

**`_DetailRow` widget:**
Reusable row: `Icon + grey label + bold value`. Used for all info fields.

---

## Feature 3: Manual Status Override

### Design rationale
QR scanning requires the physical QR card to be present. In real hospital settings, cards may be forgotten, torn, or the patient may be unconscious. The manual override provides a fallback that still creates the same Firestore records and triggers the same points/notifications as the QR flow.

### Two-stage override flow

#### Stage A — Mark as Verified (no QR)
Available when: `isVerified == false` AND `isDone == false`

Button: `FilledButton` blue, label `l10n.markAsVerified`

On press:
1. Sets `isVerified: true` on the blood request document
2. Sends FCM notification to requester: "Your request has been verified"
3. Calls `NotificationService().sendEmergencyNotification(city, bloodGroup, requestId)` to broadcast to eligible donors in that city
4. Shows success snackbar and closes the sheet

```dart
await widget.doc.reference.update({'isVerified': true});
```

#### Stage B — Mark as Fulfilled / Register Donation Manually
Available when: `isVerified == true` AND `isDone == false`

Button: `FilledButton` green, label `l10n.manualDonationTitle`

On press → opens `_ManualFulfillDialog`

### `_ManualFulfillDialog`

**UI:**
- `TextFormField` for donor UID (required validator)
- Search `IconButton` — calls `_lookupDonor()` to validate UID exists in Firestore
- If donor found: green confirmation card shows donor name
- Submit button (`l10n.markAsDone`) → `_completeDonation()`

**`_lookupDonor()` logic:**
```dart
final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
if (!doc.exists) throw Exception(l10n.donorNotFound);
setState(() => _donorName = doc.data()?['name'] ?? uid);
```

**`_completeDonation()` logic — 5-step batch:**

```dart
// Step 1 — Request status
batch.update(requestRef, {'status': 'done'});

// Step 2 — Donor lastDonated timestamp
batch.update(donorRef, {'lastDonated': DateTime.now().toIso8601String()});

// Step 3 — Donation record (with manualOverride: true flag)
batch.set(donationRef, {
  'donorId': donorId,
  'requestId': requestId,
  'hospitalId': hospitalId,
  'hospitalName': hospitalName,
  'timestamp': FieldValue.serverTimestamp(),
  'verifiedBy': adminUid,
  'manualOverride': true,   // ← distinguishes from QR donations
});

await batch.commit();

// Step 4 — Points (post-batch, needs donor bloodGroup)
await PointsService().awardDonationPoints(
  donorId, hospitalName,
  isEmergency: isUrgent,
  donorBloodGroup: donorBloodGroup,
);

// Step 5 — Notifications to donor and requester
NotificationService().sendDirectNotification(targetUid: donorId, ...);
NotificationService().sendDirectNotification(targetUid: recipientUid, ...);
```

**`manualOverride: true`** flag in the donation document:
- Allows analytics to distinguish QR-based vs manual donations
- Displayed as an amber "Manual" / "يدوي" badge in the Donation History tab
- Does not affect points or notifications — donor receives full rewards regardless

---

## Feature 4: Donation History Tab (`_DonationHistoryTab`)

### Firestore query
```dart
FirebaseFirestore.instance
    .collection('donations')
    .where('hospitalId', isEqualTo: hospitalId)
    .orderBy('timestamp', descending: true)
    .snapshots()
```

### Per-record display
Each donation card contains:

| Element | Source | How fetched |
|---|---|---|
| Donor name | `donorId` → `users` collection | `FutureBuilder<DocumentSnapshot>` |
| Donor blood group badge | same `users` doc | Same future |
| Patient name | `requestId` → `blood_requests` collection | Second `FutureBuilder<DocumentSnapshot>` |
| Date + time | `timestamp` Timestamp | Formatted inline |
| "Manual" badge | `manualOverride == true` | Inline conditional |

The two `FutureBuilder`s per card are independent — they fire in parallel. While loading, the donor name shows `'…'` (not a spinner, to avoid layout jumps).

### Empty state
Shows `Icons.history` (64px grey) + `l10n.noDonationsYet` text when the collection returns 0 documents for the hospital.

---

## Localisation (l10n)

9 new keys added to both `app_en.arb` and `app_ar.arb`:

| Key | English | Arabic |
|---|---|---|
| `requestDetails` | "Request Details" | "تفاصيل الطلب" |
| `markAsVerified` | "Mark as Verified" | "تحديد كموثق" |
| `manualDonationTitle` | "Register Donation Manually" | "تسجيل تبرع يدوي" |
| `enterDonorId` | "Enter the donor's ID to look them up." | "أدخل معرف المتبرع للبحث عنه." |
| `urgentLabel` | "URGENT" | "طارئ" |
| `requestDate` | "Date" | "التاريخ" |
| `fulfilledLabel` | "Fulfilled" | "مكتملة" |
| `verifiedLabel` | "Verified" | "موثقة" |
| `manualOverrideNote` | "QR unavailable? Use the buttons below to update manually." | "رمز QR غير متاح؟ استخدم الأزرار أدناه للتحديث يدوياً." |
| `manualBadge` | "Manual" | "يدوي" |

Existing keys reused (no duplication):
- `totalRequests`, `openRequests` (stat bar labels)
- `verifyRequest`, `registerDonation`, `verifyDonorBloodGroup` (action buttons)
- `patientName`, `units`, `city`, `phone`, `donorId` (detail rows)
- `markAsDone`, `confirmDonationTitle`, `confirmDonationBody`, `confirm`, `cancel`
- `donationSuccess`, `verifySuccess`, `donorNotFound`, `requiredField`
- `noDonationsYet`, `noRequestsFound`
- `statusCompleted`, `statusVerified`, `statusUnverified`

---

## Firestore Indexes Required

The following composite indexes are required by the new queries. If they don't exist, Firestore will return an error with a link to create them automatically:

| Collection | Fields | Order |
|---|---|---|
| `blood_requests` | `hospitalId` ASC, `createdAt` DESC | For requests tab stream |
| `blood_requests` | `hospitalId` ASC, `status` ASC | For stats bar pending count |
| `blood_requests` | `hospitalId` ASC, `isVerified` ASC | For stats bar verified count |
| `blood_requests` | `hospitalId` ASC, `status` ASC (whereIn) | For stats bar fulfilled count |
| `donations` | `hospitalId` ASC, `timestamp` DESC | For donation history stream |

---

## Data Flow Diagram

```
Hospital Admin opens dashboard
│
├─ [Tab 0: Requests]
│   ├─ _StatsBar: 4 parallel streams → live counts
│   ├─ StreamBuilder → ListView
│   │   └─ _RequestCard (tap)
│   │        └─ _RequestDetailSheet (bottom sheet)
│   │             ├─ [pending] → "Mark as Verified" button
│   │             │    └─ Firestore update + FCM notify requester
│   │             │         + sendEmergencyNotification to donors
│   │             └─ [verified] → "Register Donation Manually" button
│   │                  └─ _ManualFulfillDialog
│   │                       ├─ Lookup donor UID → validate
│   │                       └─ Confirm → 5-step batch commit
│   │                            ├─ request.status = 'done'
│   │                            ├─ donor.lastDonated = now
│   │                            ├─ donations/new {manualOverride: true}
│   │                            ├─ PointsService.awardDonationPoints()
│   │                            └─ FCM → donor + requester
│   └─ Action buttons → ScannerScreen / BloodGroupVerificationScreen
│
└─ [Tab 1: History]
    └─ StreamBuilder on donations (hospitalId, desc timestamp)
         └─ ListView
              └─ Card
                   ├─ FutureBuilder → users/{donorId} → name + bloodGroup
                   └─ FutureBuilder → blood_requests/{requestId} → patientName
```

---

## QR Flow Preservation

The existing `ScannerScreen` and `BloodGroupVerificationScreen` classes are **unchanged**. They are preserved verbatim at the bottom of `hospital_dashboard.dart`. The manual override is purely additive — it provides a fallback path that does not interfere with the QR path.

Both flows produce identical Firestore records, with one difference:
- QR donations: no `manualOverride` field (absent = false)
- Manual donations: `manualOverride: true`

---

## What Is NOT Included in Phase 1

| Feature | Phase |
|---|---|
| Donor search by name/phone | Phase 2 |
| In-app notification panel | Phase 2 |
| Hospital profile editing | Phase 2 |
| Analytics charts (fl_chart) | Phase 3 |
| Blood inventory tracking | Phase 3 |
| Web-compatible manual ID fallback for QR scanner | Phase 3 |

See `hospital_admin_proposal.md` for the full roadmap.
