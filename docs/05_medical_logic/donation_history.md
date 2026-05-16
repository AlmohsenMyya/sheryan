# Sheryan — Donation History Feature: Technical Documentation

## Overview

The Donation History screen provides donors with a complete, real-time log of all blood donations they have performed through the Sheryan platform. It transforms raw Firestore records into a readable, visually engaging timeline that gives donors a sense of pride and impact.

---

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Screen | `DonationHistoryScreen` |
| Data Source | Firestore `donations` collection |
| Query Filter | `donorId == currentUser.uid` |
| Sort Order | `timestamp` descending (most recent first) |
| Access | Tapped from a banner card in the Donor Profile screen |
| Real-time | Yes — uses `StreamBuilder<QuerySnapshot>` |

---

## Firestore Data Model

Donation records are created by hospital admins when they register a completed donation via the scanner flow in `HospitalDashboard._completeDonation()`.

### Collection: `donations`

```json
{
  "donorId":     "String — UID of the donor",
  "requestId":   "String — ID of the fulfilled blood_request",
  "hospitalId":  "String — ID of the hospital",
  "hospitalName":"String — Display name of the hospital",
  "timestamp":   "Timestamp — FieldValue.serverTimestamp()",
  "verifiedBy":  "String — UID of the hospital admin who registered it"
}
```

> **Note:** Blood volume per donation is a fixed standard value of **450 mL**, consistent with WHO blood donation guidelines. It is not stored in the document but computed at render time.

---

## Screen Structure

### 1. Summary Banner

Displayed at the top of the screen, the banner shows:

- **Total donation count** (large number)
- **Singular/plural label** in the current language
- **Total blood donated** = `count × 450 mL`
- Gradient styling identical to the profile header for visual consistency

```
┌─────────────────────────────────────────────────────┐
│  🩸    3                              1,350 mL       │
│        Donations                  Total blood donated│
└─────────────────────────────────────────────────────┘
```

### 2. Donation Cards

Each card represents one completed donation event:

```
┌─|───────────────────────────────────────────────────┐
│ ║  ❤️  Donation #3               ✅ Completed        │
│ ║      King Fahad Medical City                       │
│ ║  ─────────────────────────────────────────────── │
│ ║  📅 14 Jan 2025   🕐 10:30 AM        💧 450 mL   │
└─|───────────────────────────────────────────────────┘
```

- **Left red border strip** — uses the `ClipRRect` + `IntrinsicHeight` + `Row` pattern (consistent with notification cards; avoids Flutter's `Border` with `borderRadius` limitation)
- **Donation number** — reversed index so `#1` is the oldest and `#N` is the newest
- **Hospital name** — from `hospitalName` field
- **Date** — localized month name (Arabic/English)
- **Time** — 12-hour format with AM/PM
- **Volume chip** — always `450 mL` in red

### 3. Empty State

Shown when no donations exist:

```
        🩸 (icon)

   You haven't donated blood yet.
   Once a hospital registers your
   donation, it will appear here.
```

---

## Navigation

The `DonationHistoryScreen` is accessed from a card at the bottom of `DonorProfileScreen` (in `donors_profile.dart`):

```dart
_buildDonationHistoryCard(l10n, theme)
```

Tapping opens a full-screen push navigation:

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => const DonationHistoryScreen(),
));
```

No return value is expected (read-only screen).

---

## Real-time Updates

The screen uses `StreamBuilder<QuerySnapshot>` which means:

- If a hospital admin registers a new donation while the screen is open, the list **updates automatically** without requiring a pull-to-refresh
- The summary banner count and total volume update in real time as well

### Firestore Query

```dart
FirebaseFirestore.instance
    .collection('donations')
    .where('donorId', isEqualTo: uid)
    .orderBy('timestamp', descending: true)
    .snapshots()
```

> **Firestore Index Required:** The query uses both a `where` filter and an `orderBy` on different fields. A composite index on `(donorId ASC, timestamp DESC)` is needed. Firebase will automatically prompt creation of this index on first query if it does not exist.

---

## Localization

New strings added to `app_en.arb` and `app_ar.arb`:

| Key | English | Arabic |
|-----|---------|--------|
| `donationHistory` | Donation History | سجل التبرعات |
| `donationHistoryInfo` | Populated by hospital admins when… | يتم ملؤه من قِبل إدارة المستشفى... |
| `noDonationsYet` | You haven't donated blood yet | لم تتبرع بالدم بعد |
| `noDonationsYetSubtitle` | Once a hospital registers… | بمجرد أن يسجل المستشفى... |
| `donationSingular` | Donation | تبرع |
| `donationPlural` | Donations | تبرعات |
| `totalBloodDonated` | Total blood donated | إجمالي الدم المتبرع به |
| `donation` | Donation | تبرع |
| `completed` | Completed | مكتمل |
| `unknownHospital` | Unknown Hospital | مستشفى غير معروف |
| `viewDonationHistory` | View Donation History | عرض سجل التبرعات |

---

## Impact Calculation

The screen encourages donors by showing the total volume contributed:

```
Total mL = donation_count × 450
```

**Why 450 mL?** This is the standard whole blood donation volume per WHO and international blood banking guidelines. A single donation of 450 mL can potentially help up to 3 patients when separated into its components (red cells, plasma, platelets).

This figure is displayed prominently in the summary banner to give donors a tangible sense of their life-saving contribution.

---

## File Reference

| File | Purpose |
|------|---------|
| `lib/screens/donor_dashboard/donation_history_screen.dart` | Full donation history UI |
| `lib/screens/donor_dashboard/donors_profile.dart` | Hosts the history entry card |
| `lib/screens/hospital/hospital_dashboard.dart` | Creates donation records (`_completeDonation`) |
| `lib/l10n/app_en.arb` | English localization strings |
| `lib/l10n/app_ar.arb` | Arabic localization strings |
