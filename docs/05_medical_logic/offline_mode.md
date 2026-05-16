# Offline Mode — Sheryan App

## Overview
Sheryan supports a full offline experience. Users can browse previously loaded data, and critical actions like blood requests are queued for automatic sync when connectivity is restored.

---

## Architecture

### 1. Firestore Offline Persistence (`main.dart`)
Firebase Firestore is configured with `persistenceEnabled: true` and unlimited cache size. This automatically caches all Firestore queries and streams locally, providing:
- `StreamBuilder` screens (requests list, notifications) work offline with zero extra code.
- Firestore re-syncs automatically when back online.

### 2. Connectivity Provider (`lib/providers/connectivity/connectivity_provider.dart`)
- Uses `connectivity_plus` package.
- Exposes a Riverpod `StateNotifierProvider<ConnectivityNotifier, bool>` (`connectivityProvider`).
- Listens to real-time network changes via `Connectivity().onConnectivityChanged`.
- Returns `true` when any network interface (WiFi, mobile, ethernet) is active.

### 3. Offline Banner Widget (`lib/widgets/offline_banner.dart`)
- `ConsumerStatefulWidget` that watches `connectivityProvider`.
- Shows an **orange** strip when offline: "أنت غير متصل بالإنترنت / You're offline".
- Shows a **green** strip for 3 seconds when connectivity is restored: "تم استعادة الاتصال ✓ / Back online ✓".
- Placed as the first element in the body `Column` of `HomeScreen`, visible across all tabs and roles.

### 4. Pending Actions Service (`lib/services/pending_actions_service.dart`)
Handles blood requests created while offline.
- **Storage**: `SharedPreferences` key `sheryan_pending_blood_requests` — stores a JSON list of pending request payloads.
- `saveRequest(data)` — queues a request offline.
- `syncPendingRequests()` — submits all queued requests to Firestore and returns the count of successfully synced items.
- `getPendingCount()` — returns number of pending items.
- Auto-sync is triggered from `HomeScreen` when connectivity is restored (via `ref.listenManual`).

---

## Screen-by-Screen Offline Behavior

| Screen | Behavior |
|--------|----------|
| **Home Screen** | Loads user profile from Firestore (online) or SharedPreferences cache (offline). Auto-syncs pending requests when back online. |
| **Donors List** | Fetches from Firestore (online) and caches to SharedPreferences. Loads from cache when offline. Shows "Showing N cached donors" indicator. |
| **Donor Profile** | Fetches from Firestore (online) and caches to SharedPreferences. Loads from cache offline. |
| **My Blood Requests** | Uses `StreamBuilder` — works offline via Firestore persistence cache automatically. |
| **Notifications** | Uses `StreamBuilder` — works offline via Firestore persistence cache automatically. |
| **Create Blood Request** | Checks connectivity on submit. If offline: saves to `PendingActionsService` queue and shows orange snackbar. If online: sends to Firestore normally. |
| **Hospital Dashboard** | Uses Firestore streams — cached automatically by Firestore persistence. |

---

## New Strings Added (Localization)

| Key | Arabic | English |
|-----|--------|---------|
| `offlineBannerTitle` | أنت غير متصل بالإنترنت | You're offline |
| `offlineBannerSubtitle` | البيانات المعروضة محفوظة مسبقاً | Showing cached data |
| `backOnlineMessage` | تم استعادة الاتصال ✓ | Back online ✓ |
| `offlineCachedAt` | آخر تحديث: {time} | Last updated: {time} |
| `requestSavedOffline` | لا يوجد اتصال — سيُرسل طلبك تلقائياً... | No internet — your request will be sent... |
| `pendingRequestsSynced` | تم إرسال جميع الطلبات المعلقة بنجاح | All pending requests have been sent |
| `hasPendingRequests` | لديك {count} طلب معلق بانتظار الإرسال | You have {count} pending request(s) waiting to sync |
| `offlineActionDisabled` | هذا الإجراء يتطلب اتصالاً بالإنترنت | This action requires an internet connection |
| `cachedDonorsLabel` | عرض {count} متبرع محفوظ | Showing {count} cached donors |

---

## New Files

| File | Purpose |
|------|---------|
| `lib/providers/connectivity/connectivity_provider.dart` | Riverpod connectivity state |
| `lib/widgets/offline_banner.dart` | Offline/online status banner widget |
| `lib/services/pending_actions_service.dart` | Queue and sync pending blood requests |

## Modified Files

| File | Change |
|------|--------|
| `pubspec.yaml` | Added `connectivity_plus: ^6.1.1` |
| `lib/main.dart` | Enabled Firestore offline persistence |
| `lib/l10n/app_en.arb` | Added 9 new offline strings |
| `lib/l10n/app_ar.arb` | Added 9 new offline strings (Arabic) |
| `lib/l10n/app_localizations.dart` | Added abstract declarations |
| `lib/l10n/app_localizations_en.dart` | Added English implementations |
| `lib/l10n/app_localizations_ar.dart` | Added Arabic implementations |
| `lib/screens/home/home_screen.dart` | Added offline banner, profile cache, pending sync |
| `lib/screens/donor_dashboard/donors_list.dart` | Added donors list cache |
| `lib/screens/donor_dashboard/donors_profile.dart` | Added profile cache |
| `lib/screens/requests/create_request_screen.dart` | Added offline queue on submit |
