# Sheryan — Blood Compatibility Guide: Technical Documentation

## Overview

The Blood Compatibility Guide is an interactive educational screen accessible from the Donor Profile. It visualizes which blood groups the donor can **donate to** and **receive from**, based on internationally accepted ABO/Rh compatibility rules. The screen reuses the existing `BloodLogic` utility class, ensuring a single source of truth across the app.

---

## Feature Summary

| Aspect | Detail |
|--------|--------|
| Screen | `BloodCompatibilityScreen` |
| Navigation | Tapped from Donor Profile screen |
| Input | `donorBloodGroup` — passed as constructor argument from profile |
| Logic Source | `lib/core/utils/blood_logic.dart` (no duplication) |
| Languages | Arabic / English (via ARB) |
| Tabs | 2 tabs: Can Donate To / Can Receive From |

---

## Screen Structure

### 1. Donor Badge (Header)

A gradient header card showing:

- **Blood group in a circle** — large, prominent
- **Special badges** (conditional):
  - `O-` → "Universal Donor" badge with star icon
  - `AB+` → "Universal Recipient" badge with star icon
- **Stat chips** — count of types they can donate to / receive from

```
┌─────────────────────────────────────────────────────┐
│   (O-)    Your Blood Group           Donate: 8      │
│           O-                         Receive: 1     │
│           ⭐ Universal Donor                         │
└─────────────────────────────────────────────────────┘
```

---

### 2. TabBar — Two Views

#### Tab 1: Can Donate To
Shows all 8 blood types in a 4-column grid.
- Compatible types → colored cell with ✓ icon (red)
- Incompatible types → grey cell with ✗ icon
- The donor's own type → amber dot indicator in top-right corner

#### Tab 2: Can Receive From
Same grid layout.
- Compatible types → colored cell with ✓ icon (deep purple)
- Incompatible types → grey cell with ✗ icon

Grid animation uses staggered `AnimatedContainer` with per-item delay (`200 + i*30ms`) for a smooth entrance effect.

---

### 3. Summary Table (Bottom)

Fixed below the tab view, always visible:

```
📋 Summary

🩸 Can Donate To:    [A+] [AB+]
💜 Can Receive From: [A+] [A-] [O+] [O-]
```

Uses `Wrap` to handle multiple chips gracefully in any language/screen size.

---

## Blood Compatibility Logic

All compatibility rules are delegated to the **existing** `BloodLogic` class:

```dart
// What types can this donor give blood to?
BloodLogic.getCompatibleRecipients(donorBloodGroup)

// What types can give blood to this donor?
BloodLogic.getCompatibleDonors(donorBloodGroup)
```

**No new logic was added** — the screen is purely a visualization layer on top of `BloodLogic`.

### ABO/Rh Compatibility Reference

| Donor | Can Donate To |
|-------|--------------|
| O- | All types (Universal Donor) |
| O+ | O+, A+, B+, AB+ |
| A- | A-, A+, AB-, AB+ |
| A+ | A+, AB+ |
| B- | B-, B+, AB-, AB+ |
| B+ | B+, AB+ |
| AB- | AB-, AB+ |
| AB+ | AB+ only |

| Recipient | Can Receive From |
|-----------|----------------|
| AB+ | All types (Universal Recipient) |
| AB- | AB-, A-, B-, O- |
| A+ | A+, A-, O+, O- |
| A- | A-, O- |
| B+ | B+, B-, O+, O- |
| B- | B-, O- |
| O+ | O+, O- |
| O- | O- only |

---

## Navigation

Entry point: the Donor Profile screen (`donors_profile.dart`), via a new card placed after the sections list.

```dart
// In donors_profile.dart
_buildCompatibilityCard(bloodGroup, l10n, theme)
```

Tapping navigates with:

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => BloodCompatibilityScreen(
    donorBloodGroup: bloodGroup,
  ),
));
```

The `bloodGroup` string is the exact value from Firestore (`"A+"`, `"O-"`, etc.), passed directly to `BloodLogic` methods.

---

## Special Cases

| Blood Group | Special Property | UI Treatment |
|-------------|-----------------|--------------|
| `O-` | Universal Donor | ⭐ badge in header |
| `AB+` | Universal Recipient | ⭐ badge in header |
| All others | Standard | No special badge |

---

## Localization

New strings added to `app_en.arb` and `app_ar.arb`:

| Key | English | Arabic |
|-----|---------|--------|
| `bloodCompatibilityTitle` | Blood Compatibility Guide | دليل توافق الدم |
| `compatCanDonateTo` | Can Donate To | يمكنه التبرع لـ |
| `compatCanReceiveFrom` | Can Receive From | يمكنه الاستقبال من |
| `yourBloodGroup` | Your Blood Group | زمرة دمك |
| `universalDonor` | Universal Donor | متبرع عالمي |
| `universalRecipient` | Universal Recipient | مستقبل عالمي |
| `canDonateTo` | Donate To | يتبرع لـ |
| `canReceiveFrom` | Receive From | يستقبل من |
| `compatSummary` | Compatibility Summary | ملخص التوافق |
| `compatNone` | None | لا يوجد |
| `viewCompatibilityGuide` | Blood Compatibility Guide | دليل توافق الدم |

---

## Design Decisions

### Why pass `bloodGroup` as a constructor argument?
The profile screen already fetches the full user document. Passing the blood group avoids a redundant Firestore read from the compatibility screen.

### Why reuse `BloodLogic` instead of hardcoding?
Compatibility rules are used in 3+ places (notification targeting, request matching, this screen). Centralizing them in `BloodLogic` means a single edit propagates everywhere.

### Why no `StreamBuilder`?
Compatibility rules are static medical facts — they don't change after launch. A simple stateless rendering is sufficient and more efficient than a live Firestore listener.

### Grid layout (4 columns)
8 blood types ÷ 4 columns = 2 rows. This fits cleanly on any phone screen without scrolling, keeping all types visible simultaneously for easy comparison.

---

## File Reference

| File | Purpose |
|------|---------|
| `lib/screens/donor_dashboard/blood_compatibility_screen.dart` | Full compatibility guide UI |
| `lib/core/utils/blood_logic.dart` | Compatibility logic (unchanged, reused) |
| `lib/screens/donor_dashboard/donors_profile.dart` | Entry point card |
| `lib/l10n/app_en.arb` | English localization strings |
| `lib/l10n/app_ar.arb` | Arabic localization strings |
