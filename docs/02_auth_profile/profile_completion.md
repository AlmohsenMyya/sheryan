# Sheryan — Donor Profile Completion System: Technical Documentation

## Overview

This document describes the progressive profile completion system implemented for donors in the Sheryan blood donation application. The system is inspired by professional platforms such as LinkedIn and health applications, encouraging donors to provide enriched information in a structured, non-overwhelming manner.

---

## Design Philosophy

Rather than demanding all information at registration time, the system:

1. Collects **minimal data at signup** (name, phone, city, blood group)
2. Displays a **visual progress bar** motivating the donor to continue
3. Organizes additional data into **clearly separated sections**, each with its own dedicated screen
4. Introduces **hospital-verified blood group** as the highest-value completion step, tying the digital profile to a real-world medical verification

---

## Profile Completion Sections

### Weight Distribution

| # | Section | Fields Required | Weight |
|---|---------|----------------|--------|
| 1 | Basic Information | name, phone, city, bloodGroup | **20%** |
| 2 | Health Profile | height, weight, gender, smokingStatus | **20%** |
| 3 | Medical History | lastDonated | **15%** |
| 4 | Emergency Contact | emergencyContactName, emergencyContactPhone | **10%** |
| 5 | Blood Group Verification | bloodGroupVerified == true | **35%** |

**Total: 100%**

---

## Section Details

### Section 1 — Basic Information (20%)

Collected at signup. Fields: `name`, `phone`, `city`, `bloodGroup`.

This section is shown in read-only mode on the profile screen. To change these values, the donor edits them inline in the form fields already present. It is considered complete if all four fields are non-empty strings.

**Completion logic:**
```dart
static bool basicComplete(Map<String, dynamic> d) =>
    _filled(d['name']) && _filled(d['phone']) &&
    _filled(d['city']) && _filled(d['bloodGroup']);
```

---

### Section 2 — Health Profile (20%)

**Screen:** `lib/screens/donor_dashboard/profile_sections/health_info_screen.dart`

**Fields added to Firestore `users/{uid}`:**

| Field | Type | Description |
|-------|------|-------------|
| `height` | `double` | Height in centimeters |
| `weight` | `double` | Weight in kilograms |
| `gender` | `String` | `'male'` or `'female'` |
| `smokingStatus` | `String` | `'never'`, `'former'`, or `'current'` |

**UI:** Numeric text fields for height/weight with unit suffixes; `ChoiceChip` groups for gender and smoking status.

**Completion logic:**
```dart
static bool healthComplete(Map<String, dynamic> d) =>
    d['height'] != null && d['weight'] != null &&
    _filled(d['gender']) && _filled(d['smokingStatus']);
```

---

### Section 3 — Medical History (15%)

**Screen:** `lib/screens/donor_dashboard/profile_sections/medical_history_screen.dart`

**Fields added to Firestore `users/{uid}`:**

| Field | Type | Description |
|-------|------|-------------|
| `lastDonated` | `String` | Date string `yyyy-MM-dd` |
| `chronicDiseases` | `String` | Free-text, optional |
| `allergies` | `String` | Free-text, optional |

**Note:** Only `lastDonated` is required for section completion. `chronicDiseases` and `allergies` are optional enrichment fields.

**Completion logic:**
```dart
static bool medicalComplete(Map<String, dynamic> d) =>
    _filled(d['lastDonated']);
```

---

### Section 4 — Emergency Contact (10%)

**Screen:** `lib/screens/donor_dashboard/profile_sections/emergency_contact_screen.dart`

**Fields added to Firestore `users/{uid}`:**

| Field | Type | Description |
|-------|------|-------------|
| `emergencyContactName` | `String` | Full name of trusted person |
| `emergencyContactPhone` | `String` | Phone number of trusted person |

This section provides safety coverage in case a donor experiences complications during donation. Both fields are required.

**Completion logic:**
```dart
static bool emergencyComplete(Map<String, dynamic> d) =>
    _filled(d['emergencyContactName']) &&
    _filled(d['emergencyContactPhone']);
```

---

### Section 5 — Blood Group Verification (35%)

This is the **most valuable** section (35%) because it introduces a trust layer that cannot be self-reported. It requires a physical hospital visit.

**Field added to Firestore `users/{uid}`:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `bloodGroupVerified` | `bool` | `false` | Set to `true` only by hospital admin |

**Flow:**

```
Donor                       Hospital Admin              Firestore
  │                               │                        │
  │─ Shows QR card from profile ─▶│                        │
  │                               │─ Opens "Verify Donor   │
  │                               │   Blood Group" screen  │
  │                               │─ Scans donor QR ──────▶│ reads users/{uid}
  │                               │◀── Donor info shown ───│
  │                               │─ Presses "Confirm" ───▶│ bloodGroupVerified: true
  │◀── Push notification ─────────│                        │
  │   "Blood group verified ✅"   │                        │
```

**Completion logic:**
```dart
static bool bloodVerified(Map<String, dynamic> d) =>
    d['bloodGroupVerified'] == true;
```

---

## Core Utility: `ProfileCompletion`

**File:** `lib/core/utils/profile_completion.dart`

This static utility class centralizes all completion logic. It is intentionally decoupled from UI so it can be reused anywhere in the app.

### Key Methods

```dart
// Returns 0-100 total completion percentage
ProfileCompletion.calculate(Map<String, dynamic> userData) → int

// Returns true/false for each section
ProfileCompletion.basicComplete(data)
ProfileCompletion.healthComplete(data)
ProfileCompletion.medicalComplete(data)
ProfileCompletion.emergencyComplete(data)
ProfileCompletion.bloodVerified(data)

// Returns ordered list of ProfileSection objects for UI rendering
ProfileCompletion.getSections(data) → List<ProfileSection>
```

### `ProfileSection` Model

```dart
class ProfileSection {
  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;
  final int weight;          // Contribution to total percentage
  final bool isComplete;     // Derived from user data
  final bool requiresHospital; // Cannot be completed in-app
}
```

---

## Profile Screen: Updated Design

**File:** `lib/screens/donor_dashboard/donors_profile.dart`

### Visual Structure

```
┌─────────────────────────────────────────────────────┐
│  [Avatar]  Ahmed Mohammed           A+ ◉ Verified   │  ← Gradient header
│            Riyadh                                    │
│                                                      │
│  Profile Completion            65%                   │
│  ████████████████░░░░░░░░░                          │  ← Color-coded bar
│  "Almost there — great progress!"                   │
└─────────────────────────────────────────────────────┘

  Complete your profile

  ✅  Basic Information           +20%  ✓
  ✅  Health Profile              +20%  ✓
  ⚠️   Medical History            +15%  ›   ← Tappable
  ⚠️   Emergency Contact          +10%  ›   ← Tappable
  🏥  Blood Group Verification    +35%  🏥  ← Hospital only

  [   Show QR Donor Card   ]
```

### Progress Bar Color Logic

| Completion | Bar Color |
|-----------|-----------|
| 80–100% | `Colors.greenAccent` |
| 50–79% | `Colors.yellowAccent` |
| 0–49% | `Colors.white` |

### Navigation

Tapping an incomplete section navigates to its dedicated screen. The screen returns `true` on save, triggering a `_loadProfile()` refresh. Sections 1 (basic) and 5 (hospital) are non-navigable from the donor's side.

---

## Hospital Dashboard: New Button

**File:** `lib/screens/hospital/hospital_dashboard.dart`

A third action button **"Verify Donor Blood Group"** was added below the existing two buttons (Verify Request / Register Donation).

### `BloodGroupVerificationScreen`

A new `ConsumerStatefulWidget` that:

1. Opens `MobileScanner` (same plugin used for donation flow)
2. On scan: fetches `users/{uid}` from Firestore
3. Validates `role == 'donor'`
4. Presents a dialog showing: donor name, blood group, city
5. If admin confirms: sets `bloodGroupVerified: true` in Firestore
6. Sends a `NotificationType.verification` push to the donor via `NotificationService`

---

## Firestore Schema Changes

All new fields are added to the existing `users/{uid}` document:

```json
{
  "name": "String",
  "phone": "String",
  "city": "String",
  "bloodGroup": "String",
  "email": "String",
  "role": "String",
  "fcmToken": "String",
  "lastDonated": "String (yyyy-MM-dd)",

  // NEW — Section 2
  "height": "double (cm)",
  "weight": "double (kg)",
  "gender": "String ('male' | 'female')",
  "smokingStatus": "String ('never' | 'former' | 'current')",

  // NEW — Section 3 (additional)
  "chronicDiseases": "String (optional)",
  "allergies": "String (optional)",

  // NEW — Section 4
  "emergencyContactName": "String",
  "emergencyContactPhone": "String",

  // NEW — Section 5
  "bloodGroupVerified": "boolean (default: false)"
}
```

---

## Localization

New strings added to both `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`:

| Key | English | Arabic |
|-----|---------|--------|
| `profileCompletion` | Profile Completion | اكتمال الملف الشخصي |
| `healthInfoTitle` | Health Profile | البيانات الصحية |
| `medicalHistoryTitle` | Medical History | السجل الطبي |
| `emergencyContactTitle` | Emergency Contact | جهة الاتصال الطارئة |
| `verifyDonorBloodGroup` | Verify Donor Blood Group | توثيق زمرة دم متبرع |
| `bloodGroupVerifiedSuccess` | Blood group verified successfully! | تم توثيق زمرة الدم بنجاح! |
| `completionFull` | Your profile is 100% complete! | ملفك الشخصي مكتمل 100%! |
| ... | ... | ... |

---

## File Reference

| File | Purpose |
|------|---------|
| `lib/core/utils/profile_completion.dart` | Central completion logic |
| `lib/screens/donor_dashboard/donors_profile.dart` | Updated profile screen with progress UI |
| `lib/screens/donor_dashboard/profile_sections/health_info_screen.dart` | Health data form |
| `lib/screens/donor_dashboard/profile_sections/medical_history_screen.dart` | Medical history form |
| `lib/screens/donor_dashboard/profile_sections/emergency_contact_screen.dart` | Emergency contact form |
| `lib/screens/hospital/hospital_dashboard.dart` | Blood group verification scanner |
| `lib/l10n/app_en.arb` | English strings |
| `lib/l10n/app_ar.arb` | Arabic strings |
