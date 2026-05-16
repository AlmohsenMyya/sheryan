# شريان (Sheryan) — Complete Project Documentation

> **Version:** 0.1.0 | **Stack:** Flutter 3.x · Firebase · Riverpod 3 · FCM v1 HTTP API  
> **Supported Languages:** Arabic (default) · English  
> **Supported Themes:** Light · Dark (persisted)  
> **Target Platform:** Web (port 5000) — mobile-ready code  
> **Last updated:** 2026-05-02

---

## Table of Contents

1. [Project Vision & Mission](#1-project-vision--mission)
2. [High-Level Architecture](#2-high-level-architecture)
3. [Folder & File Structure](#3-folder--file-structure)
4. [Firebase Collections (Database Schema)](#4-firebase-collections-database-schema)
5. [User Roles & Access Model](#5-user-roles--access-model)
6. [Application Boot Sequence](#6-application-boot-sequence)
7. [Authentication Flows](#7-authentication-flows)
8. [Role-Based Routing (HomeScreen)](#8-role-based-routing-homescreen)
9. [Donor Dashboard — Full Feature Set](#9-donor-dashboard--full-feature-set)
10. [Recipient Dashboard — Full Feature Set](#10-recipient-dashboard--full-feature-set)
11. [Hospital Admin Dashboard — Full Feature Set](#11-hospital-admin-dashboard--full-feature-set)
12. [SuperAdmin Dashboard — Full Feature Set](#12-superadmin-dashboard--full-feature-set)
13. [Sponsor Org Dashboard — Full Feature Set](#13-sponsor-org-dashboard--full-feature-set)
14. [Blood Request Lifecycle — End to End](#14-blood-request-lifecycle--end-to-end)
15. [Donation Flow — QR vs Manual](#15-donation-flow--qr-vs-manual)
16. [Points & Rewards System](#16-points--rewards-system)
17. [Notification System](#17-notification-system)
18. [Offline Support](#18-offline-support)
19. [State Management (Riverpod)](#19-state-management-riverpod)
20. [Localisation (l10n)](#20-localisation-l10n)
21. [Theming System](#21-theming-system)
22. [Blood Compatibility Logic](#22-blood-compatibility-logic)
23. [Profile Completion System](#23-profile-completion-system)
24. [Services Layer](#24-services-layer)
25. [Core Utilities & Models](#25-core-utilities--models)
26. [Dependencies & Package Map](#26-dependencies--package-map)
27. [Environment Variables & Secrets](#27-environment-variables--secrets)
28. [Build & Run](#28-build--run)
29. [Known Limitations & Future Roadmap](#29-known-limitations--future-roadmap)

---

## 1. Project Vision & Mission

**Sheryan (شريان — "Artery")** is a community-driven blood donation platform designed to close the gap between people who urgently need blood and those who can give it. The name "Artery" reflects the app's role as the vital conduit that keeps the blood donation ecosystem alive.

### Core Problems Solved

| Problem | Solution |
|---|---|
| Patients can't find compatible donors quickly | Real-time city + blood-group filtered donor lists |
| Donors don't know when they are urgently needed | Push notifications the moment a verified request is broadcast |
| Hospital staff spend time on paperwork | QR-based donor verification and donation registration |
| Donors have no incentive to stay engaged | Points, tiers, and a redeemable rewards marketplace |
| No visibility into the local blood supply situation | Live statistics for hospital admins and superadmins |
| Requests are lost when the internet drops | Offline queue with automatic background sync on reconnect |

### Design Principles

- **Real-time first** — All critical data uses Firestore streams, never one-shot fetches.
- **Role isolation** — Every screen checks role from Firestore, never trusts a local variable.
- **Offline resilience** — Blood requests are queued locally and synced automatically.
- **Bilingual by default** — Arabic is the default language; English is a first-class alternative.
- **No hardcoded text** — Every visible string goes through the l10n layer.

---

## 2. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Flutter Web App                                 │
│                                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │  Screens /   │  │  Providers   │  │   Services   │  │    Core    │  │
│  │   Widgets    │  │  (Riverpod)  │  │  (Firebase)  │  │ (theme /   │  │
│  │              │◄─│              │◄─│              │  │  utils /   │  │
│  │  Stateless   │  │ StreamProvider│ │ AuthService  │  │  models /  │  │
│  │  Stateful    │  │ StateNotifier│  │ NotifService │  │   enums)   │  │
│  │  Consumer    │  │ NotifierProv │  │ PointsService│  │            │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                   Firebase Backend                                  │  │
│  │                                                                     │  │
│  │  FirebaseAuth    Firestore (real-time)    FCM v1 HTTP API          │  │
│  │  (email/pwd)     (offline-enabled)        (via googleapis_auth)    │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Key Architectural Decisions

**Firestore offline persistence** is enabled at startup with unlimited cache size:
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```
This means all Firestore reads are served from cache when offline, and writes queue automatically.

**FCM v1 HTTP API** is used instead of the legacy API or Firebase Admin SDK, because Flutter web cannot use the Admin SDK directly. The app holds a Google Service Account JSON (via `.env`), exchanges it for OAuth2 bearer tokens at runtime, and calls the FCM REST endpoint directly.

**Role derivation from Firestore** — `HomeScreen` always reads `profile['role']` from the live Firestore stream, never from a cached local enum. This prevents stale-role bugs after admin role changes.

---

## 3. Folder & File Structure

```
sheryan/
├── lib/
│   ├── main.dart                        # App entry, Firebase init, ProviderScope
│   ├── firebase_options.dart            # Generated Firebase config
│   │
│   ├── core/
│   │   ├── enums/
│   │   │   └── user_role.dart           # UserRole enum (5 roles)
│   │   ├── models/
│   │   │   └── app_notification.dart    # AppNotification model + NotificationType enum
│   │   ├── theme/
│   │   │   ├── app_colors.dart          # All color constants (light/dark, semantic)
│   │   │   ├── app_design_constants.dart # Spacing, radii, icon sizes
│   │   │   ├── app_theme.dart           # lightTheme + darkTheme ThemeData
│   │   │   └── app_typography.dart      # Text styles
│   │   └── utils/
│   │       ├── blood_logic.dart         # Blood compatibility matrix
│   │       ├── points_ui_utils.dart     # Points display helpers
│   │       ├── profile_completion.dart  # Completion %, section breakdown
│   │       ├── qr_dialog.dart           # QR code display dialog
│   │       └── whatsapp_helper.dart     # WhatsApp deep-link builder
│   │
│   ├── l10n/
│   │   ├── app_en.arb                   # English strings (~580+ keys)
│   │   ├── app_ar.arb                   # Arabic strings (~580+ keys)
│   │   ├── app_localizations.dart       # Generated delegate + base class
│   │   ├── app_localizations_en.dart    # Generated EN implementation
│   │   └── app_localizations_ar.dart    # Generated AR implementation
│   │
│   ├── providers/
│   │   ├── auth/
│   │   │   └── auth_provider.dart       # authStateProvider, userProfileProvider, roleProvider
│   │   ├── connectivity/
│   │   │   └── connectivity_provider.dart # connectivityProvider (online/offline bool)
│   │   ├── locale/
│   │   │   └── locale_provider.dart     # localeProvider (AR default, persisted)
│   │   ├── points/
│   │   │   └── points_provider.dart     # pointsProvider, sponsorRewardsProvider, etc.
│   │   └── theme/
│   │       └── theme_provider.dart      # themeModeProvider (persisted Light/Dark)
│   │
│   ├── screens/
│   │   ├── admin/
│   │   │   └── admin_dashboard.dart     # SuperAdmin: 8-section sidebar layout (2652 lines)
│   │   ├── auth/
│   │   │   ├── role_selection_screen.dart # First screen: pick donor/recipient/other
│   │   │   ├── sign_in_screen.dart      # Login form
│   │   │   └── sign_up_screen.dart      # Registration form (role-aware)
│   │   ├── donor_dashboard/
│   │   │   ├── blood_compatibility_screen.dart
│   │   │   ├── donation_history_screen.dart
│   │   │   ├── donors_details.dart      # Single donor full profile view
│   │   │   ├── donor_settings.dart      # Notifications + preferences for donors
│   │   │   ├── donors_list.dart         # Paginated donor list with filters
│   │   │   ├── donors_profile.dart      # Donor's own profile + completion + QR card
│   │   │   ├── nearby_users_req.dart    # All requests from users across the platform
│   │   │   ├── rewards_screen.dart      # Points balance, tier, marketplace, history
│   │   │   ├── see_users_request.dart   # Donor views all blood requests
│   │   │   └── profile_sections/
│   │   │       ├── basic_info_screen.dart
│   │   │       ├── emergency_contact_screen.dart
│   │   │       ├── health_info_screen.dart
│   │   │       └── medical_history_screen.dart
│   │   ├── donors/
│   │   │   ├── donor_detail_screen.dart
│   │   │   ├── donors_list_screen.dart
│   │   │   └── nearby_donors_screen.dart # GPS-based proximity ranking
│   │   ├── home/
│   │   │   └── home_screen.dart         # Role router + shared AppBar + connectivity
│   │   ├── hospital/
│   │   │   └── hospital_dashboard.dart  # Hospital Admin: tabs + stats + QR + manual override
│   │   ├── misc/
│   │   │   ├── awareness_screen.dart    # Blood donation tips & FAQs
│   │   │   ├── notifications_screen.dart # Inbox with 5-tab filter
│   │   │   └── splash_screen.dart       # Animated logo → StartupRouter
│   │   ├── profile/
│   │   │   └── user_profile_screen.dart # Recipient profile view/edit
│   │   ├── requests/
│   │   │   ├── create_request_screen.dart # Create blood request form
│   │   │   └── requests_list_screen.dart  # Recipient's own request history
│   │   ├── settings/
│   │   │   └── userside_settings_screen.dart
│   │   └── sponsor/
│   │       ├── manage_reward_screen.dart  # Sponsor creates/edits rewards
│   │       ├── scan_redeem_screen.dart    # Sponsor scans donor QR to redeem
│   │       └── sponsor_dashboard.dart    # Sponsor overview + reward list
│   │
│   ├── services/
│   │   ├── auth_service.dart            # registerUser(), loginUser(), logoutUser()
│   │   ├── notification_secrets.dart    # FCM service account key management
│   │   ├── notification_service.dart    # Singleton: FCM v1 push + Firestore inbox
│   │   ├── pending_actions_service.dart # Offline queue via SharedPreferences
│   │   └── points_service.dart          # Points arithmetic + Firestore transactions
│   │
│   └── widgets/
│       └── offline_banner.dart          # Red banner shown when connectivityProvider == false
│
├── docs/
│   ├── hospital_admin_proposal.md       # 3-phase hospital admin improvement roadmap
│   ├── hospital_admin_phase1_implementation.md # Phase 1 technical implementation notes
│   └── sheryan_complete_project_documentation.md  # This file
│
├── .env                                 # FCM service account + project secrets
├── pubspec.yaml                         # Dependencies
├── run.sh                               # Build script with package_config.json patch
└── build/web/                           # Production build output (served on port 5000)
```

---

## 4. Firebase Collections (Database Schema)

### `users` collection

The central document for every user, regardless of role.

```
users/{uid}
├── uid: String               # Firebase Auth UID (also the document ID)
├── name: String              # Display name
├── email: String             # Auth email
├── phone: String             # Contact phone (with country code)
├── role: String              # "donor" | "recipient" | "hospitalAdmin" | "superAdmin" | "sponsorOrg"
├── bloodGroup: String?       # "A+" | "A-" | "B+" | "B-" | "O+" | "O-" | "AB+" | "AB-"
├── city: String?             # City name (matches cities collection)
├── hospitalId: String?       # Set for hospitalAdmin — links to hospitals collection
├── fcmToken: String?         # Device FCM token (refreshed on every login)
├── points: int               # Current points balance (default 0)
├── tier: String              # "bronze" | "silver" | "gold" | "platinum"
├── bloodGroupVerified: bool  # True only after hospital admin QR scan
├── lastDonated: String?      # ISO 8601 date of most recent donation
├── lastLogin: Timestamp      # Updated on every sign-in
├── createdAt: Timestamp
│
│   [Health Profile — filled by donor in profile sections]
├── height: num?              # cm
├── weight: num?              # kg
├── gender: String?           # "male" | "female"
├── smokingStatus: String?    # "non-smoker" | "smoker" | "ex-smoker"
├── dateOfBirth: String?      # ISO 8601
│
│   [Medical History]
├── diseases: String?
├── allergies: String?
├── medications: String?
│
│   [Emergency Contact]
├── emergencyContactName: String?
├── emergencyContactPhone: String?
├── emergencyContactRelationship: String?
│
└── [subcollections]
    ├── pointsHistory/{docId}
    │   ├── event: String     # PointsEvent constant
    │   ├── points: int       # Points awarded this event
    │   ├── descriptionAr: String
    │   ├── descriptionEn: String
    │   ├── total: int        # Running total at time of award
    │   └── createdAt: Timestamp
    │
    └── notifications/{docId}
        ├── titleAr: String
        ├── titleEn: String
        ├── bodyAr: String
        ├── bodyEn: String
        ├── type: String      # NotificationType.name
        ├── isRead: bool
        ├── requestId: String?
        └── timestamp: Timestamp
```

### `blood_requests` collection

Created by recipients. Managed by hospital admins.

```
blood_requests/{docId}
├── userId: String            # UID of the recipient who created the request
├── patientName: String       # Name of the patient needing blood
├── bloodGroup: String        # Required blood type
├── units: String             # Number of units needed
├── phone: String             # Contact phone for the requester
├── city: String              # City where blood is needed
├── hospitalId: String        # ID of the destination hospital
├── hospital: String          # Hospital display name (denormalized)
├── neededAt: String?         # Human-readable deadline (formatted with intl)
├── status: String            # "pending" | "done" | "completed"
├── isVerified: bool          # Set to true by hospital admin after QR verify
├── isUrgent: bool?           # Emergency flag (shown as red badge)
├── createdAt: Timestamp
└── _syncedFromOffline: bool? # True if synced from the offline queue
```

### `donations` collection

One document per completed donation event.

```
donations/{docId}
├── donorId: String           # UID of the donor
├── requestId: String         # ID of the blood_requests document
├── hospitalId: String        # Hospital where the donation occurred
├── hospitalName: String      # Denormalized hospital name
├── timestamp: Timestamp      # Server-side donation time
├── verifiedBy: String        # UID of the hospital admin who registered it
└── manualOverride: bool?     # True if registered via manual form (not QR)
```

### `hospitals` collection

```
hospitals/{docId}
├── name: String
├── city: String
└── [any additional fields added by superAdmin]
```

### `cities` collection

```
cities/{docId}
└── name: String
```

### `rewards` collection

Created by sponsor organisations.

```
rewards/{docId}
├── sponsorId: String         # UID of the sponsorOrg user
├── sponsorName: String
├── title: String
├── description: String
├── pointsRequired: int
├── city: String
├── isActive: bool
└── createdAt: Timestamp
```

### `redemptions` collection

```
redemptions/{docId}
├── donorId: String
├── sponsorId: String
├── rewardId: String
├── rewardTitle: String
├── pointsDeducted: int
└── redeemedAt: Timestamp
```

### `announcements` collection

Created by superAdmin for broadcast notifications.

```
announcements/{docId}
├── title: String
├── body: String
├── targetCity: String?       # null = all cities
├── targetBloodGroup: String? # null = all blood groups
├── sentAt: Timestamp
└── sentBy: String            # superAdmin UID
```

---

## 5. User Roles & Access Model

```
┌──────────────┬────────────────────────────────────────────────────────┐
│ Role         │ Capabilities                                            │
├──────────────┼────────────────────────────────────────────────────────┤
│ donor        │ View blood requests, browse donors, manage own profile, │
│              │ view donation history, earn/redeem points              │
├──────────────┼────────────────────────────────────────────────────────┤
│ recipient    │ Create blood requests, track own requests, browse      │
│              │ nearby donors, contact donors via WhatsApp             │
├──────────────┼────────────────────────────────────────────────────────┤
│ hospitalAdmin│ View + manage requests for their hospital only,        │
│              │ QR verify requests, QR register donations, manually    │
│              │ verify/fulfil requests, view donation history          │
├──────────────┼────────────────────────────────────────────────────────┤
│ superAdmin   │ Full CRUD on: hospitals, cities, hospital admins,      │
│              │ sponsor orgs, donors, all blood requests,              │
│              │ broadcast notifications to any segment                 │
├──────────────┼────────────────────────────────────────────────────────┤
│ sponsorOrg   │ Create/manage reward offers, scan donor QR to redeem  │
│              │ points, view their redemption statistics               │
└──────────────┴────────────────────────────────────────────────────────┘
```

Role is stored as a plain string in `users/{uid}.role`. It is read from the live Firestore stream on every `HomeScreen` build — there is no client-side trust of stale local state.

---

## 6. Application Boot Sequence

```
main()
  │
  ├─ WidgetsFlutterBinding.ensureInitialized()
  ├─ dotenv.load(".env")                        # Load FCM secrets
  ├─ Firebase.initializeApp(...)                # Connect to Firebase project
  ├─ FirebaseFirestore.settings(persistenceEnabled: true)  # Enable offline cache
  └─ runApp(ProviderScope(child: MyApp()))
        │
        └─ MyApp (ConsumerWidget)
              │
              ├─ Watches: localeProvider → AR/EN (from SharedPreferences)
              ├─ Watches: themeModeProvider → Light/Dark (from SharedPreferences)
              └─ home: SplashScreen()
                    │
                    ├─ Shows animated Sheryan logo for ~2s
                    └─ Navigator replaces with StartupRouter()
                          │
                          └─ Watches: authStateProvider (FirebaseAuth stream)
                                │
                                ├─ user == null → RoleSelectionScreen (auth entry)
                                └─ user != null → HomeScreen (role-based routing)
```

---

## 7. Authentication Flows

### Registration

```
RoleSelectionScreen
  │ User taps: Donor / Recipient / Hospital Admin / Sponsor Org
  │ (SuperAdmin is created manually in Firestore)
  ▼
SignupScreen(role: selectedRole)
  │
  ├─ Form fields: name, email, password, phone, city
  ├─ Conditional: bloodGroup (donor/recipient), hospitalId (hospitalAdmin)
  │
  └─ Submit → AuthService.registerUser()
        │
        ├─ Firebase.createUserWithEmailAndPassword()
        ├─ FCM.getToken() → fresh device token
        └─ Firestore.users.doc(uid).set({
              uid, name, email, bloodGroup, city, role, phone,
              lastDonated, hospitalId, fcmToken, createdAt
           })
           │
           └─ Success → Navigator replaces to HomeScreen
```

### Login

```
LoginScreen
  │
  └─ AuthService.loginUser(email, password)
        │
        ├─ Firebase.signInWithEmailAndPassword()
        ├─ FCM.getToken() → refreshed token
        └─ Firestore.users.doc(uid).update({
              fcmToken: newToken,
              lastLogin: serverTimestamp()
           })
           │
           └─ authStateProvider emits User → HomeScreen auto-navigates
```

### Logout

```
PopupMenu "Logout"
  │
  └─ HomeScreen._signOutAndGoLogin()
        │
        ├─ NotificationService().logout()
        ├─ AuthService.logoutUser() → FirebaseAuth.signOut()
        ├─ roleProvider.clearRole()
        └─ Navigator.pushAndRemoveUntil → LoginScreen
           (authStateProvider emits null → StartupRouter → RoleSelectionScreen)
```

---

## 8. Role-Based Routing (HomeScreen)

`HomeScreen` is the single point of dispatch after login. It reads the user profile from `userProfileProvider` (a Firestore stream) and derives the role every time the stream emits.

```dart
// Role derived DIRECTLY from Firestore, never from local cache
final roleStr = profile['role'] as String?;
final UserRole role = switch (roleStr) {
  'hospitalAdmin' => UserRole.hospitalAdmin,
  'superAdmin'    => UserRole.superAdmin,
  'sponsorOrg'    => UserRole.sponsorOrg,
  'donor'         => UserRole.donor,
  _               => UserRole.recipient,
};
```

**What each role sees:**

| Role | Dashboard | Bottom Nav Tabs |
|---|---|---|
| `donor` | Donor home: greeting, stats, request cards | Home · Donors · Profile · Rewards |
| `recipient` | Recipient home: request blood, nearby donors | Home · Requests · Donors · Settings |
| `hospitalAdmin` | `HospitalDashboard` (embedded in scaffold) | None (tabs inside HospitalDashboard) |
| `superAdmin` | `AdminDashboard` (sidebar layout) | None (sidebar navigation) |
| `sponsorOrg` | `SponsorDashboard` | None |

**Shared AppBar** (all roles except superAdmin) contains:
- Dark/light mode toggle
- Notification bell with live unread badge (stream from `users/{uid}/notifications` where `isRead == false`)
- Language switcher (bottom sheet: AR / EN)
- Settings + Logout popup menu

---

## 9. Donor Dashboard — Full Feature Set

### Home Tab

- Personalised greeting (Good Morning / Good Afternoon / Good Evening) based on device time
- Motivational quote card (randomly picked from 7 localised quotes)
- Stat cards: blood group, city
- Tappable cards: "Users' Blood Requests", "Nearby Requests", "Awareness Tips"

### Donors Tab (`DonorsListScreen` / `NearbyDonorsScreen`)

- Paginated list of all donors filtered by city and/or blood group
- **Nearby Donors**: uses `geolocator` to get current GPS coordinates, then ranks donors by Haversine distance to their registered city coordinates
- Each donor card shows: name, blood group, city, last donation date, tier badge
- Tap → `DonorDetailScreen`: full profile + WhatsApp contact button

### Profile Tab (`DonorProfileScreen`)

- Circular completion ring (0–100%, 5 weighted sections)
- Blood group badge (red if not verified, green check if hospital-verified)
- QR Card: donor's UID encoded as QR code — scannable by hospital admin and sponsor org
- Points balance + tier chip (Bronze / Silver / Gold / Platinum)
- 5 tappable profile sections (each unlocks points on first completion):

| Section | Weight | Points Awarded |
|---|---|---|
| Basic Info | 20% | 30 pts |
| Health Profile | 20% | 30 pts |
| Medical History | 15% | 20 pts |
| Emergency Contact | 10% | 20 pts |
| Blood Group Verified | 35% | 100 pts |

- `DonationHistoryScreen`: list of past donations with hospital name, date, blood group, patient name

### Rewards Tab (`RewardsScreen`)

- Current points total + tier display
- Points history log (subcollection `users/{uid}/pointsHistory`)
- City-filtered marketplace of active rewards from all sponsor orgs
- Tap a reward → view details → "Redeem" button → generates QR code for sponsor to scan
- Redeeming deducts points via Firestore transaction (atomic — cannot go negative)

---

## 10. Recipient Dashboard — Full Feature Set

### Home Tab

- Greeting + blood group / city stat cards
- Tappable cards: Request Blood, My Requests, Nearby Donors, Awareness Tips

### Create Blood Request (`RequestBloodScreen`)

Full form with:
- Patient name (required)
- City dropdown (live from `cities` collection stream)
- Hospital dropdown (live, filtered by selected city from `hospitals` collection)
- Phone number
- Blood group + units
- Optional "needed by" date + time picker (DatePicker + TimePicker)

On submit:
1. Checks connectivity via `connectivity_plus`
2. **Offline**: saves to `PendingActionsService` (SharedPreferences JSON queue)
3. **Online**: writes to `blood_requests` collection + notifies hospital admins via FCM

### My Requests (`RequestsListScreen`)

- Streams all requests where `userId == currentUser.uid`
- Status filter chips: All / Pending / Verified / Done
- Each card shows status badge, blood group, patient name, date
- Long-press or swipe → delete request option (with confirmation dialog)
- Tapping a done request triggers `NotificationService.sendRequestClosedNotification()` to notify the matched donor

### Nearby Donors (`NearbyDonorsScreen`)

- Requests GPS permission via `permission_handler`
- Lists donors sorted by distance to recipient's location
- Shows compatibility badge (compatible blood group highlighted)
- WhatsApp deep-link contact button (pre-filled message template via `whatsapp_helper.dart`)

---

## 11. Hospital Admin Dashboard — Full Feature Set

All features implemented in `lib/screens/hospital/hospital_dashboard.dart`.

### Layout

```
Scaffold
  AppBar (title + TabBar)
  │
  Column
  ├─ _StatsBar          ← always visible above tabs
  ├─ Divider
  └─ TabBarView
       ├─ Tab 0: _RequestsTab
       └─ Tab 1: _DonationHistoryTab
```

### Stats Bar (Phase 1)

Four live StreamBuilder-powered stat cards filtered by `hospitalId`:

| Card | Color | Firestore Filter |
|---|---|---|
| Total Requests | Blue | `blood_requests` where `hospitalId == myId` |
| Open (Pending) | Orange | + `status == 'pending'` |
| Verified | Blue | + `isVerified == true` |
| Fulfilled | Green | + `status in ['done', 'completed']` |

### Requests Tab

**Action button row** (3 buttons — always visible):
- **Verify Request** → opens `ScannerScreen(isVerifyOnly: true)` — scans request QR
- **Register Donation** → opens `ScannerScreen(isVerifyOnly: false)` — 2-step QR flow
- **Verify Blood Group** → opens `BloodGroupVerificationScreen` — scans donor QR

**Request list** (live stream, descending by `createdAt`):
- Blood group badge (red)
- Patient name + urgent pill badge (if `isUrgent == true`)
- Blood group · units
- Creation date
- Status icon (pending/verified/done)
- **Tappable** → opens `_RequestDetailSheet`

### Request Detail Sheet (Phase 1)

`DraggableScrollableSheet` (0.4 → 0.95 height range):
- Status chip (Pending / Verified & Active / Donation Completed)
- Urgent badge (if applicable)
- Blood group hero display (large, prominent)
- Detail rows: patient name, units, city, date+time, phone
- **Manual override section** (hidden if request is already done):
  - Info banner: "QR unavailable? Use buttons below to update manually."
  - **"Mark as Verified"** (shown if `isVerified == false`): sets `isVerified: true`, notifies requester, broadcasts to compatible donors
  - **"Register Donation Manually"** (shown if `isVerified == true` and `isDone == false`): opens `_ManualFulfillDialog`

### Manual Fulfil Dialog (Phase 1)

- Donor UID text field + search button → validates UID exists in Firestore, shows donor name
- Confirmation dialog before committing
- On confirm: Firestore `batch.commit()` in one atomic write:
  1. `blood_requests/{id}.status = 'done'`
  2. `users/{donorId}.lastDonated = now()`
  3. `donations/{new}.{donorId, requestId, hospitalId, hospitalName, timestamp, verifiedBy, manualOverride: true}`
- Post-batch: `PointsService.awardDonationPoints()` (with emergency × 2 multiplier, rare blood +100, streak +50)
- FCM notifications to donor and requester

### Donation History Tab (Phase 1)

- Streams `donations` where `hospitalId == myId`, ordered by `timestamp` descending
- Per card: donor name + blood group badge (via `FutureBuilder` on `users` collection), patient name (via `FutureBuilder` on `blood_requests`), date+time, "Manual" amber badge if `manualOverride == true`

### QR Scanner Flows

**Verify-only mode** (`isVerifyOnly: true`):
```
Scan request QR → validate hospitalId matches → set isVerified: true
→ FCM notify requester → sendEmergencyNotification() to compatible donors in city
```

**Donation mode** (`isVerifyOnly: false`):
```
Step 1: Scan donor QR → validate donor exists → store donorId
Step 2: Scan request QR → validate hospitalId matches
→ Confirmation dialog
→ batch.commit():
   - request.status = 'done'
   - donor.lastDonated = now
   - donations/{new} created
→ PointsService.awardDonationPoints()
→ FCM → donor + requester
```

**Blood Group Verification mode**:
```
Scan donor QR → load donor doc → show dialog (name, blood group, city)
→ Confirm → users/{uid}.bloodGroupVerified = true
→ PointsService.checkAndAwardProfileMilestones() (awards 100 pts for verification)
→ FCM notify donor
```

---

## 12. SuperAdmin Dashboard — Full Feature Set

8-section sidebar layout (`AdminDashboard` in `admin_dashboard.dart`). Responsive: wide sidebar (210px with labels) on screens > 750px, icon-only (68px) on smaller screens.

### Section 0 — Overview (`_AdminOverview`)

Live stat cards via StreamBuilder:
- Total Donors, Total Hospitals, Open Requests, Total Donations

### Section 1 — Hospital Admin Manager (`HospitalAdminManager`)

- Lists all users with `role == 'hospitalAdmin'`
- Each card shows admin name, email, assigned hospital name (fetched via `FutureBuilder` from `hospitals` collection using `hospitalId`)
- **Delete** with confirmation dialog
- **Edit** dialog: update name, email, hospitalId assignment

### Section 2 — Hospital Manager (`HospitalManager`)

- CRUD for `hospitals` collection
- Add: name + city
- Edit: update name and/or city
- Delete with confirmation

### Section 3 — City Manager (`CityManager`)

- CRUD for `cities` collection
- Add new city
- **Edit** city name (inline dialog, updates live in all dropdowns)
- Delete with confirmation

### Section 4 — Sponsor Org Manager (`SponsorOrgManager`)

- Lists all users with `role == 'sponsorOrg'`
- **Edit** org name and city
- Delete

### Section 5 — Donor Manager (`_DonorManager`)

- Lists all users with `role == 'donor'`
- Shows blood group, city, tier badge
- Delete donor

### Section 6 — Blood Requests Admin (`_BloodRequestsAdmin`)

- Streams ALL blood requests across all hospitals
- Status filter chips: All / Pending / Verified / Done
- Each card: patient name, blood group, city, hospital, date, status badge
- Mark as Done button (with confirmation)
- Delete request

### Section 7 — Broadcast Notifications (`_BroadcastNotif`)

- Compose titleAr, titleEn, bodyAr, bodyEn
- Optional targeting: specific city, specific blood group
- On send: queries matching users from Firestore → loops `sendDirectNotification()` for each
- History list of sent announcements from `announcements` collection

---

## 13. Sponsor Org Dashboard — Full Feature Set

### Header

- Org name
- Active rewards count
- Total redemptions count

### Reward List

- Streams rewards where `sponsorId == currentUid`
- Active/inactive toggle per reward
- Edit → `ManageRewardScreen`
- Delete with confirmation

### Create/Edit Reward (`ManageRewardScreen`)

- Title, description, points required, city, active flag
- Writes to `rewards` collection

### Scan & Redeem (`ScanRedeemScreen`)

- Scans donor's QR card (UID)
- Shows donor's current points balance
- List of this sponsor's active rewards that the donor can afford
- Select a reward → `PointsService.deductPoints()` (Firestore transaction — atomic, cannot go below 0)
- On success: writes `redemptions/{new}` document

---

## 14. Blood Request Lifecycle — End to End

```
RECIPIENT                 FIRESTORE               HOSPITAL ADMIN          DONOR
   │                          │                        │                    │
   │── Create Request ────────►│                        │                    │
   │   (form submit)          │ blood_requests/{id}    │                    │
   │                          │ status: 'pending'      │                    │
   │                          │ isVerified: false      │                    │
   │                          │                        │                    │
   │                          │──── FCM Push ──────────►│                    │
   │                          │   "New blood request"  │                    │
   │                          │                        │                    │
   │                          │       Admin scans      │                    │
   │                          │       request QR ──────►│                    │
   │                          │                        │── isVerified: true ►│
   │◄── FCM "Request          │                        │                    │
   │    Verified" ────────────│                        │                    │
   │                          │                        │                    │
   │                          │──── sendEmergency ─────────────────────────►│
   │                          │   Notification to all  │                 FCM push
   │                          │   compatible donors    │                 "Urgent!"
   │                          │   in same city         │                    │
   │                          │                        │                    │
   │                          │       Admin scans      │                    │
   │                          │       donor QR ────────►│                    │
   │                          │                        │── status: 'done' ──►│
   │                          │   donations/{new}      │                    │
   │◄── FCM "Fulfilled" ──────│                        │                    │
   │                          │                        │                    │
   │                          │──────────────────────────────── FCM ────────►│
   │                          │                        │      "Thank you!"  │
   │                          │                        │    + Points awarded │
```

**Status transitions:**

```
pending
  │
  ├─ isVerified: true  (after admin QR scan or manual verify)
  │
  └─ status: 'done' OR 'completed'  (after donation registered)
```

**Offline path:**
If recipient is offline when submitting, `PendingActionsService.saveRequest()` stores the request JSON in `SharedPreferences`. On next connectivity, `HomeScreen._listenForReconnect()` detects the transition `offline → online` and triggers `PendingActionsService.syncPendingRequests()` which replays all queued requests to Firestore and notifies hospital admins.

---

## 15. Donation Flow — QR vs Manual

### QR Flow (normal — scanner present)

```
ScannerScreen (isVerifyOnly: false)
├── Step 1: Scan donor QR
│   └── Reads: users/{donorId} — validates existence
│
└── Step 2: Scan request QR
    └── Reads: blood_requests/{requestId} — validates hospitalId matches
        └── Confirmation dialog
            └── batch.commit():
                ├── blood_requests/{id}.status = 'done'
                ├── users/{donorId}.lastDonated = now
                └── donations/{new} {manualOverride: absent/false}
```

### Manual Override Flow (QR card unavailable)

```
_RequestDetailSheet → "Register Donation Manually" button
  └── _ManualFulfillDialog
      ├── Admin enters donor UID
      ├── Search button → users/{uid} exists check → shows donor name
      └── Confirm
          └── batch.commit():
              ├── blood_requests/{id}.status = 'done'
              ├── users/{donorId}.lastDonated = now
              └── donations/{new} {manualOverride: true}
```

**Distinction in Firestore:**

| Field | QR Flow | Manual Flow |
|---|---|---|
| `manualOverride` | absent (treated as false) | `true` |
| Points awarded | Same | Same |
| Notifications sent | Same | Same |
| Badge in Donation History | None | Amber "Manual" / "يدوي" |

---

## 16. Points & Rewards System

### Point Values

| Event | Points | Notes |
|---|---|---|
| Account created | 20 | Awarded once at registration |
| Basic info complete | 30 | Name + phone + city + blood group |
| Health info complete | 30 | Height + weight + gender + smoking |
| Medical history complete | 20 | Last donation date filled |
| Emergency contact complete | 20 | Name + phone |
| Blood group verified | 100 | Requires hospital admin QR scan |
| Profile 100% bonus | 50 | All 5 sections done |
| Donation registered | 200 | Base value per donation |
| Emergency donation (×2) | 400 | When `isUrgent == true` |
| Rare blood type bonus | +100 | O-, AB-, B-, A- |
| Consecutive donation streak | +50 | Each donation after the first |

### Tier Thresholds

| Tier | Minimum Points |
|---|---|
| Bronze | 0 |
| Silver | 500 |
| Gold | 1,000 |
| Platinum | 2,000 |

Tier is updated atomically inside the same Firestore transaction that awards points:
```dart
await _fs.runTransaction((tx) async {
  final current = snap.data()?['points'] ?? 0;
  final newTotal = current + points;
  final tier = tierForPoints(newTotal);       // recalculated every time
  tx.update(userRef, {'points': newTotal, 'tier': tier});
  tx.set(historyRef, { event, points, descriptionAr, descriptionEn, total: newTotal, createdAt });
});
```

### Point Deduction (Reward Redemption)

```dart
await _fs.runTransaction((tx) async {
  final current = snap.data()?['points'] ?? 0;
  if (current < pointsRequired) { success = false; return; }
  tx.update(userRef, {'points': current - pointsRequired, 'tier': ...});
  tx.set(redemptionRef, { donorId, sponsorId, rewardId, rewardTitle, pointsDeducted, redeemedAt });
});
```
If the donor's balance is insufficient, the transaction aborts without writing anything.

---

## 17. Notification System

### Architecture

`NotificationService` is a **singleton** (`factory` constructor returns `_instance`). It combines:
1. **Firebase Cloud Messaging (FCM)** — push to device even when app is closed
2. **Firestore inbox** — persistent in-app notification store in `users/{uid}/notifications`

### FCM v1 HTTP API

The app does NOT use the legacy FCM API or Firebase Admin SDK (incompatible with Flutter web). Instead:

1. A Google Service Account JSON is stored in `.env`
2. At runtime, `_getAccessToken()` exchanges the service account for an OAuth2 bearer token via `googleapis_auth`
3. The bearer token is used as `Authorization: Bearer <token>` header in HTTP POST to `https://fcm.googleapis.com/v1/projects/{projectId}/messages:send`

### Notification Types

```dart
enum NotificationType {
  emergency,        // Urgent blood request broadcast
  verification,     // Request or blood group verified
  gratitude,        // Thank-you from requester
  newRequest,       // New request arrived at hospital
  requestClosed,    // Donor notified that requester confirmed closure
  general           // Broadcast from SuperAdmin
}
```

### Notification Methods

| Method | Trigger | Recipients |
|---|---|---|
| `sendEmergencyNotification()` | Hospital admin verifies a request | All compatible donors in same city |
| `sendToHospitalAdmins()` | Recipient creates a request | All admins of that hospital |
| `sendDirectNotification()` | Any 1-to-1 notification | Single user by UID |
| `sendRequestClosedNotification()` | Recipient marks their request closed | The matched donor |

### Emergency Broadcast Logic

```dart
final compatibleTypes = BloodLogic.getCompatibleDonors(bloodGroup);
final donorsSnap = await _fs.collection('users')
    .where('role', isEqualTo: 'donor')
    .where('city', isEqualTo: city)
    .where('bloodGroup', whereIn: compatibleTypes)
    .get();

// Parallel: Firestore batch write (inbox) + FCM pushes
await Future.wait([
  firestoreBatch.commit(),
  ...fcmFutures,
]);
```

### Notifications Screen (Inbox)

5 tab filters: All · Emergency · Verification · Donation · System

Each notification card:
- Icon (colour-coded by type)
- Title (shown in app language: AR or EN)
- Body text
- Timestamp (formatted with `intl`)
- Unread dot (fades on tap via `markAsRead()`)
- "Mark all read" button in AppBar

Unread badge on bell icon uses a live stream:
```dart
NotificationService().getUnreadCountStream(userId)
// → _fs.collection('users').doc(uid).collection('notifications')
//       .where('isRead', isEqualTo: false).snapshots()
```

---

## 18. Offline Support

### Layer 1 — Firestore Built-in Cache

Firestore with `persistenceEnabled: true` automatically:
- Serves all reads from cache when offline
- Queues all writes and applies them when connection is restored
- Streams continue emitting cached data without any code changes

### Layer 2 — Blood Request Queue (`PendingActionsService`)

Handles the case where the device is offline **at the moment** the user submits a blood request:

```dart
// On submit — check connectivity first
final connectivityResult = await Connectivity().checkConnectivity();
final isOnline = connectivityResult.any((r) => r != ConnectivityResult.none);

if (!isOnline) {
  await PendingActionsService().saveRequest(requestData);  // → SharedPreferences
  // Shows orange snackbar: "Saved, will sync when online"
  return;
}
```

On reconnection (detected by `connectivityProvider`):
```dart
// HomeScreen._listenForReconnect()
ref.listenManual(connectivityProvider, (prev, next) {
  if (prev == false && next == true) {
    _syncPendingRequests();
  }
});
```

`syncPendingRequests()` loops through all queued items, writes each to Firestore (with `_syncedFromOffline: true` flag), notifies hospital admins, and removes successfully synced items from the queue.

### Layer 3 — UI Indicator

`OfflineBanner` widget (embedded in the scaffold body for hospitalAdmin and other roles):
- Watches `connectivityProvider`
- Shows a red/amber banner: "You are offline" when `state == false`
- Disappears automatically when connection is restored

---

## 19. State Management (Riverpod)

All providers live in `lib/providers/`. The app uses `ProviderScope` at the root.

### Provider Map

| Provider | Type | Location | Purpose |
|---|---|---|---|
| `authStateProvider` | `StreamProvider<User?>` | auth_provider.dart | Firebase Auth state stream |
| `userProfileProvider` | `StreamProvider<Map?>` | auth_provider.dart | Live Firestore user document |
| `roleProvider` | `StateNotifierProvider<RoleNotifier, UserRole?>` | auth_provider.dart | Selected/current role |
| `authServiceProvider` | `Provider<AuthService>` | auth_provider.dart | AuthService singleton |
| `localeProvider` | `StateNotifierProvider<LocaleNotifier, Locale?>` | locale_provider.dart | AR/EN, persisted |
| `themeModeProvider` | `StateNotifierProvider<ThemeModeNotifier, ThemeMode>` | theme_provider.dart | Light/Dark, persisted |
| `connectivityProvider` | `NotifierProvider<ConnectivityNotifier, bool>` | connectivity_provider.dart | Online/offline status |
| `pointsProvider` | `StreamProvider` | points_provider.dart | Live donor points + tier |
| `sponsorRewardsProvider` | `StreamProvider` | points_provider.dart | Rewards by sponsor UID |
| `sponsorRedemptionsCountProvider` | `StreamProvider<int>` | points_provider.dart | Total redemptions count |

### Key Patterns

**Single source of truth for auth:**
```dart
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users').doc(user.uid).snapshots()
      .map((snap) => snap.data());
});
```
`userProfileProvider` is derived from `authStateProvider`, so it automatically resets when the user logs out.

**Role derivation in HomeScreen** — always from Firestore, never from `roleProvider` directly for routing. `roleProvider` is only kept in sync for child widgets that still reference it.

**Persistence** — both `localeProvider` and `themeModeProvider` use `SharedPreferences` to persist state across app restarts. Both load saved values in their constructor via an async init method.

---

## 20. Localisation (l10n)

### Setup

- `flutter: generate: true` in pubspec.yaml
- ARB files: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Generated output: `lib/l10n/app_localizations.dart` + `_en.dart` + `_ar.dart`
- Default language: **Arabic** (`LocaleNotifier` initialises to `Locale('ar')`)
- Supported: `['ar', 'en']`

### Scale

~580+ string keys covering every visible string in the app, including:
- All UI labels, buttons, placeholders
- Error messages and validation feedback
- Notification titles and bodies
- WhatsApp message templates (with ICU placeholders)
- Motivational quotes (7 quotes × 2 languages)
- Points event descriptions

### ICU Message Format

Parameterised strings use ICU placeholders:
```json
"donorDetected": "Donor Detected: {name}",
"@donorDetected": {
  "placeholders": {
    "name": { "type": "String" }
  }
}
```

### Language Switching

```dart
// Bottom sheet in HomeScreen
await ref.read(localeProvider.notifier).setLocale(const Locale('ar'));
// → saves to SharedPreferences → MaterialApp rebuilds with new locale
```

The entire widget tree rebuilds with the new locale instantly — no navigation required.

---

## 21. Theming System

### Definition

Two complete `ThemeData` objects defined in `app_theme.dart`:
- `AppTheme.lightTheme` — white/slate backgrounds, teal-blue primary
- `AppTheme.darkTheme` — dark navy backgrounds (`#0F172A`), bright teal primary

### Color Palette

| Category | Light | Dark |
|---|---|---|
| Scaffold background | `#FFFFFF` | `#0F172A` |
| Surface | `#F8FAFC` | `#1E293B` |
| Primary | `#0891B2` (teal) | `#38BDF8` (bright teal) |
| Blood Red | `#DC2626` | `#F87171` |
| Success | `#16A34A` | `#16A34A` |
| Error | `#DC2626` | `#DC2626` |

Blood red (`AppColors.primaryRed` / `AppColors.bloodRed`) is **only used for blood-specific actions** — blood group badges, request buttons, donation icons. All other UI elements use the medical teal primary.

### Persistence

```dart
// ThemeModeNotifier
Future<void> toggle() async {
  state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('sheryan_theme_mode', state == ThemeMode.dark ? 'dark' : 'light');
}
```

Toggle button appears in the AppBar on every screen.

---

## 22. Blood Compatibility Logic

`BloodLogic` in `lib/core/utils/blood_logic.dart` provides two static methods:

### `getCompatibleDonors(recipientType)`

Returns which blood types can **donate** to the given recipient:

| Recipient | Compatible Donors |
|---|---|
| AB+ | All 8 types (universal recipient) |
| AB- | AB-, A-, B-, O- |
| A+ | A+, A-, O+, O- |
| A- | A-, O- |
| B+ | B+, B-, O+, O- |
| B- | B-, O- |
| O+ | O+, O- |
| O- | O- (universal donor) |

Used by `sendEmergencyNotification()` to target only donors whose blood can help the specific recipient.

### `getCompatibleRecipients(donorType)`

Returns which blood types the donor **can donate to** — used when a donor browses requests compatible with their blood type.

---

## 23. Profile Completion System

`ProfileCompletion` class (`lib/core/utils/profile_completion.dart`) computes a 0–100% score from 5 weighted sections:

| Section | Weight | Completion Condition |
|---|---|---|
| Basic Info | 20% | name, phone, city, bloodGroup all non-empty |
| Health Profile | 20% | height, weight, gender, smokingStatus all set |
| Medical History | 15% | lastDonated non-empty |
| Emergency Contact | 10% | emergencyContactName + emergencyContactPhone |
| Blood Group Verified | 35% | bloodGroupVerified == true |

The highest single contributor is **Blood Group Verification (35%)** — requiring a physical visit to a hospital. This is intentional design: it ensures only real, verified donors reach high profile completion scores.

`PointsService.checkAndAwardProfileMilestones()` is called:
- After any profile section save
- After blood group verification
- Each milestone is **idempotent** — `hasEarnedEvent()` checks `pointsHistory` before awarding, so it cannot be earned twice.

---

## 24. Services Layer

### `AuthService`

Stateless class (instantiated fresh where needed, also available via `authServiceProvider`).

| Method | Action |
|---|---|
| `registerUser()` | Firebase Auth create + Firestore profile write + FCM token capture |
| `loginUser()` | Firebase Auth sign-in + FCM token refresh + lastLogin update |
| `logoutUser()` | Firebase Auth sign-out |

### `NotificationService`

Singleton — `factory NotificationService() => _instance`.

| Method | Action |
|---|---|
| `init(context)` | Setup local notifications, save FCM token, request permissions |
| `sendEmergencyNotification()` | Batch push to all compatible donors in a city |
| `sendToHospitalAdmins()` | Direct push to all admins of a specific hospital |
| `sendDirectNotification()` | Push + Firestore inbox write for one user |
| `sendRequestClosedNotification()` | Notify the matched donor when request is closed |
| `getUnreadCountStream()` | Live count of unread notifications |
| `markAsRead()` | Set single notification `isRead: true` |
| `markAllAsRead()` | Batch update all unread to `isRead: true` |

### `PointsService`

Stateless class, instantiated where needed.

| Method | Action |
|---|---|
| `awardPoints()` | Firestore transaction: add points + update tier + write history |
| `hasEarnedEvent()` | Idempotency check: query pointsHistory |
| `awardDonationPoints()` | Donation award with emergency×2 + rare blood +100 + streak +50 |
| `checkAndAwardProfileMilestones()` | Checks and awards all 5 section milestones (idempotent) |
| `deductPoints()` | Firestore transaction: subtract points for reward redemption |
| `tierForPoints()` | Pure function: int → "bronze"|"silver"|"gold"|"platinum" |
| `getPoints()` | One-shot fetch of current points balance |

### `PendingActionsService`

Singleton — stores offline blood requests as JSON in `SharedPreferences` under key `sheryan_pending_blood_requests`.

| Method | Action |
|---|---|
| `saveRequest()` | Append JSON to SharedPreferences list |
| `getPendingCount()` | Count queued items |
| `syncPendingRequests()` | Replay all items to Firestore, return synced count |
| `clearAll()` | Remove all pending items |

---

## 25. Core Utilities & Models

### `AppNotification` Model

```dart
class AppNotification {
  final String id;
  final String titleAr, titleEn;
  final String bodyAr, bodyEn;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final String? requestId;
}
```

Has `.toMap()` and `.fromMap()` for Firestore serialisation. The `type` field is serialised as the enum name string.

### `BloodLogic`

Pure static methods. No state. Compatible donor/recipient lookup using `switch` on blood type strings.

### `ProfileCompletion`

Pure static class. `calculate()` returns 0–100 int. `getSections()` returns a list of `ProfileSection` objects with completion status and weight for UI rendering.

### `AppDesignConstants`

Centralised spacing and radius values. All padding, margin, border radius, and icon sizes in the app reference these constants — no magic numbers in widget code.

### `AppColors`

All colour constants. The key design rule: `AppColors.primaryRed` (`#DC2626`) is reserved for blood-specific UI elements. All other interactive elements use `AppColors.medicalBlue` / `Theme.of(context).colorScheme.primary`.

---

## 26. Dependencies & Package Map

| Package | Version | Purpose |
|---|---|---|
| `firebase_core` | ^4.7.0 | Firebase initialisation |
| `firebase_auth` | ^6.4.0 | Email/password authentication |
| `cloud_firestore` | ^6.3.0 | Realtime database + offline cache |
| `firebase_messaging` | ^16.2.0 | FCM token management + background message handler |
| `firebase_storage` | ^13.3.0 | (Present, not yet actively used) |
| `flutter_riverpod` | ^3.0.3 | State management (StreamProvider, StateNotifier, Notifier) |
| `flutter_localizations` | sdk | ARB-based i18n support |
| `intl` | ^0.20.2 | Date/number formatting + ICU message parser |
| `mobile_scanner` | ^5.2.3 | QR code scanning via camera |
| `qr_flutter` | ^4.1.0 | QR code rendering (donor card, reward QR) |
| `geolocator` | ^14.0.2 | GPS coordinates for nearby donors |
| `permission_handler` | ^11.3.1 | Runtime camera + location permissions |
| `connectivity_plus` | ^6.1.1 | Online/offline detection |
| `shared_preferences` | ^2.3.0 | Persisting locale, theme, offline queue, notification prefs |
| `url_launcher` | ^6.3.2 | WhatsApp deep links |
| `http` | ^1.6.0 | FCM v1 HTTP API calls |
| `googleapis_auth` | ^1.6.0 | OAuth2 service account → bearer token exchange |
| `flutter_dotenv` | ^5.2.1 | Load `.env` at runtime |
| `flutter_local_notifications` | ^20.1.0 | Show push notifications while app is in foreground |

---

## 27. Environment Variables & Secrets

All secrets are stored in `.env` (not committed to version control). The `run.sh` build script generates the `.env` from the Replit environment secrets before every build.

Required variables:

| Variable | Used By |
|---|---|
| `FCM_PROJECT_ID` | FCM HTTP v1 endpoint URL + service account |
| `FCM_PRIVATE_KEY_ID` | Service account JSON |
| `FCM_PRIVATE_KEY` | RSA private key (newlines encoded as `\n`) |
| `FCM_CLIENT_EMAIL` | Service account email for OAuth2 |
| `FCM_CLIENT_ID` | Service account client ID |

The `run.sh` patches `package_config.json` to point Flutter's internal flutter package to a local writable copy (`flutter_local_lib/`) where the `@protected` annotation has been removed from `ImplicitlyAnimatedWidget` — this prevents a `dart2js` crash specific to this build environment.

---

## 28. Build & Run

### Development (Replit)

```bash
bash run.sh
```

`run.sh` performs:
1. Generates `.env` from environment secrets
2. Patches `package_config.json` → `flutter` → `flutter_local` (local copy)
3. Runs `flutter build web --release --no-pub`
4. Serves `build/web/` behind a reverse proxy on port 5000

### Build Time

~45–55 seconds (dart2js release compilation).

### Serving

A Node.js proxy server on port 5000 serves the static `build/web/` directory and forwards API-style paths as needed. The build output is a standard Flutter web SPA (`index.html` + generated JS).

### Local Development (outside Replit)

```bash
flutter pub get
flutter run -d chrome --web-port 5000
```

---

## 29. Known Limitations & Future Roadmap

### Current Limitations

| Area | Limitation |
|---|---|
| FCM permissions | Web browsers require explicit user permission; some browsers block notifications entirely |
| QR scanning | `mobile_scanner` uses the camera API — works on mobile browsers, limited on desktop |
| GPS | `geolocator` requires HTTPS; city distances are approximated by geocoding city names, not actual GPS of donors |
| Blood requests | No duplicate detection — a recipient can submit the same request multiple times |
| Hospital admin | No hospital profile editing (Phase 2) |
| SuperAdmin | No audit log for admin actions |
| Security rules | Firestore rules are not documented here — full enforcement of role isolation is critical before production |

### Phase 2 — Hospital Admin (Planned)

- Donor search by name or phone number
- In-app notification panel with history
- Hospital profile editing (name/city) with SuperAdmin approval workflow

### Phase 3 — Hospital Admin (Planned)

- Analytics charts using `fl_chart` (donation trends, blood group distribution)
- Blood inventory tracking per hospital
- Web-compatible manual ID fallback when camera is unavailable

### Platform Expansion

- Native iOS/Android builds (code is Flutter-native, only build target changes)
- FCM background message handler (`firebase_messaging` background isolate)
- Firebase App Check for production security

---

*Documentation generated from codebase analysis — commit `47a63818` (2026-05-02)*  
*Sheryan — Because every second counts. كل ثانية مهمة.*
