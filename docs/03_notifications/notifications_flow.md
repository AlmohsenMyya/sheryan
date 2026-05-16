# Sheryan — Notification System: Technical Documentation

## Overview

This document describes the complete notification architecture implemented in the Sheryan blood donation application. The system was redesigned from a basic topic-based approach to a precise, targeted, real-time notification pipeline using Firebase Cloud Messaging (FCM) v1 API with service account authentication.

---

## Architecture

### Components

| Component | Role |
|-----------|------|
| `NotificationService` | Singleton service handling all FCM and Firestore notification operations |
| `AppNotification` model | Typed in-app notification data model |
| `NotificationType` enum | Classification of notification categories |
| `NotificationsScreen` | Tabbed UI for displaying the notification inbox |
| Firebase Firestore | Persistent in-app notification inbox per user |
| FCM v1 API | Real-time push delivery to devices |

---

## Notification Types

Defined in `lib/core/models/app_notification.dart`:

```dart
enum NotificationType {
  emergency,      // Emergency blood request broadcast to compatible donors
  verification,   // Request or blood group verified by hospital
  gratitude,      // Donor acknowledged after successful donation
  newRequest,     // Hospital admin notified when new request is created
  requestClosed,  // Matched donor notified when requester marks request as done
  general,        // System-level or informational messages
}
```

---

## Notification Flows

### Flow 1 — Emergency Broadcast (Verified Request)

**Trigger:** Hospital admin scans a blood request QR and presses "Verify Request"

**Process:**
1. Admin scans request QR → `_handleVerifyRequest(requestId)` is called
2. Firestore `blood_requests/{id}` → `isVerified: true`
3. Requester receives a direct notification: "Your request has been verified"
4. `sendEmergencyNotification()` is called with `city` and `bloodGroup`
5. Firestore query: all `users` where `role == 'donor'`, `city == city`, `bloodGroup` in compatible types (via `BloodLogic.getCompatibleDonors`)
6. For each compatible donor:
   - A Firestore in-app notification is written to `users/{donorId}/notifications`
   - A direct FCM v1 push is sent to the donor's `fcmToken`
7. All Firestore writes are batched; FCM pushes run concurrently via `Future.wait`

**Relevant method:** `sendEmergencyNotification(city, bloodGroup, requestId)`

---

### Flow 2 — Hospital Admin Notified on New Request

**Trigger:** A user (recipient) creates a new blood request

**Process:**
1. `CreateRequestScreen._submit()` creates the request in Firestore
2. Immediately after: `sendToHospitalAdmins(hospitalId, ...)` is called
3. Firestore query: all `users` where `role == 'hospitalAdmin'`, `hospitalId == hospitalId`
4. For each admin, `sendDirectNotification()` is called, which:
   - Sends a FCM v1 push to the admin's device
   - Writes an in-app notification to `users/{adminId}/notifications`

**Relevant method:** `sendToHospitalAdmins(hospitalId, titleEn, titleAr, bodyEn, bodyAr, requestId)`

---

### Flow 3 — Donor Notified When Request is Manually Closed

**Trigger:** The requester presses "Mark as Done" on their own request in `RequestsListScreen`

**Process:**
1. `_markAsDone(requestId)` updates `blood_requests/{id}` → `status: 'done'`
2. `sendRequestClosedNotification(requestId)` is called
3. Firestore query: `donations` collection where `requestId == requestId` (limit 1)
4. If a matched donor exists, `sendDirectNotification()` sends them a gratitude push

**Relevant method:** `sendRequestClosedNotification(requestId)`

---

### Flow 4 — Donation Completion (Hospital registers donation)

**Trigger:** Hospital admin scans both donor QR and request QR, confirms donation

**Process:**
1. `_completeDonation()` in `HospitalDashboard`:
   - Updates `blood_requests/{id}` → `status: 'done'`
   - Updates `users/{donorId}` → `lastDonated: now`
   - Creates a `donations/{id}` document
2. Donor receives gratitude push: "Thank you for saving a life!"
3. Recipient receives fulfillment push: "Good news! Your request was fulfilled"

---

### Flow 5 — Blood Group Verification (NEW)

**Trigger:** Hospital admin scans donor QR in "Verify Donor Blood Group" screen

**Process:**
1. Admin opens `BloodGroupVerificationScreen`
2. Scans donor QR → fetches `users/{donorId}` from Firestore
3. Confirmation dialog shows: donor name, blood group, city
4. Admin presses "Confirm" → `users/{donorId}` → `bloodGroupVerified: true`
5. Donor receives a verification push:
   - Title: "Blood Group Verified ✅"
   - Body: "Your blood group has been medically verified. Profile completion increased!"

---

## FCM v1 API Implementation

### Authentication

The service uses `googleapis_auth` with a service account to obtain short-lived OAuth2 tokens:

```dart
Future<String?> _getAccessToken() async {
  final client = await auth.clientViaServiceAccount(
    auth.ServiceAccountCredentials.fromJson(_serviceAccount),
    ['https://www.googleapis.com/auth/firebase.messaging'],
  );
  return client.credentials.accessToken.data;
}
```

Service account credentials are loaded from environment variables (`.env` file generated by `run.sh`) to avoid hardcoding secrets.

### Why v1 API (not Legacy FCM)

| Feature | Legacy API | v1 API (current) |
|---------|-----------|-----------------|
| Auth | Server key (static) | OAuth2 token (short-lived, secure) |
| Per-device targeting | ✅ | ✅ |
| Topics | ✅ | ✅ |
| Deprecation | **Deprecated June 2024** | ✅ Active |

### Why Direct Targeting (not Topics)

The original implementation used FCM Topics (`/topics/bloodGroup_city`). This was replaced with direct per-donor targeting because:

1. **No unsubscribe risk** — topics require active subscription management
2. **More reliable** — topics can have propagation delays
3. **Security** — tokens are only in Firestore, not exposed via topic names
4. **Precision** — we can apply `BloodLogic.getCompatibleDonors()` to send only to biologically compatible donors (e.g., O- can donate to all types)

---

## In-App Notification Inbox

### Firestore Structure

```
users/
  {userId}/
    notifications/
      {notificationId}/
        id: String
        titleEn: String
        titleAr: String
        bodyEn: String
        bodyAr: String
        timestamp: Timestamp
        type: String       // NotificationType.name
        isRead: Boolean    // default false
        requestId: String? // optional reference
```

### NotificationsScreen UI

Located at: `lib/screens/misc/notifications_screen.dart`

**Features:**
- **5 tabs:** All / Emergency / Verification / Donation / System
- **Date separators:** Today / Yesterday / Earlier
- **Colored left-border cards:** each type has a distinct color
- **Unread dot indicators** on unread notifications
- **Mark all as read** button in AppBar
- Real-time stream via `StreamBuilder<QuerySnapshot>`

### Read/Unread Management

```dart
// Mark single notification as read on tap
NotificationService().markAsRead(userId, notificationId);

// Mark all as read (Firestore batch write)
NotificationService().markAllAsRead(userId);

// Real-time unread count stream
NotificationService().getUnreadCountStream(userId);
```

---

## FCM Token Management

On each app launch and login, the user's FCM token is saved to Firestore:

```
users/{uid}/fcmToken: "device-token-string"
```

Token refresh is handled automatically via `_fcm.onTokenRefresh` listener. If a user has no token (web/emulator), the notification is still saved to their Firestore inbox.

---

## File Reference

| File | Purpose |
|------|---------|
| `lib/services/notification_service.dart` | Core service — FCM + Firestore |
| `lib/core/models/app_notification.dart` | Data model + NotificationType enum |
| `lib/screens/misc/notifications_screen.dart` | Tabbed notification inbox UI |
| `lib/screens/requests/create_request_screen.dart` | Triggers Flow 2 (admin notif) |
| `lib/screens/requests/requests_list_screen.dart` | Triggers Flow 3 (close notif) |
| `lib/screens/hospital/hospital_dashboard.dart` | Triggers Flows 1, 4, 5 |
| `lib/l10n/app_en.arb` | English localization strings |
| `lib/l10n/app_ar.arb` | Arabic localization strings |
