# Donor Flow Implementation: Notification Routing & Landing Screen (Phase 3)

## 1. Overview
This phase focused on closing the loop for the donor experience. We implemented deep-linking routing for FCM notifications and a dedicated landing screen for donors to respond to emergency requests.

## 2. Notification Routing (Deep-Linking)

### 2.1 Global Navigator Key
To allow navigation from the `NotificationService` (which operates outside the widget tree), we added a `GlobalKey<NavigatorState>` to `main.dart` and registered it with the `MaterialApp`.

### 2.2 FCM Data Payload Handling
We updated `NotificationService` to listen for:
- `FirebaseMessaging.onMessageOpenedApp`: Triggers when the app is in background.
- `FirebaseMessaging.instance.getInitialMessage()`: Triggers when the app is opened from a terminated state.

**Routing Logic:**
If the notification `data` contains:
- `type == 'emergency'`
- `requestId != null`

The system automatically pushes the `RequestResponseScreen` onto the navigation stack.

## 3. Request Response Screen (`lib/screens/donors/request_response_screen.dart`)

### 3.1 Data Fetching
The screen fetches real-time metadata from Firestore using `RequestService().getById(requestId)` to ensure the donor sees the latest information (e.g., if the request was already fulfilled).

### 3.2 Actions
- **Accept (قبول):** Opens a persistent bottom sheet with options to **Call** the recipient or message via **WhatsApp** (utilizing `WhatsAppHelper`).
- **Decline (اعتذار):** 
    1. Prompts for confirmation.
    2. Invokes `StagedNotificationService().declineRequestSlot()`.
    3. Triggers the **Replenishment Loop** on the backend (Phase 2 logic).
    4. Shows a success snackbar and pops the screen.

## 4. Technical Details

### 4.1 Navigation
```dart
navigatorKey.currentState?.push(
  MaterialPageRoute(
    builder: (_) => RequestResponseScreen(requestId: requestId),
  ),
);
```

### 4.2 State Management
The screen uses a simple `StatefulWidget` for local loading and error states. Business logic for declining is handled by the `StagedNotificationService` singleton.

### 4.3 Localization
Strict compliance with `AppLocalizations` was maintained. New keys:
- `emergencyRequest`
- `declineButton` / `acceptButton`
- `confirmDeclineTitle` / `confirmDeclineBody`
- `declineSuccessMessage`

---
*Date: May 2026*
*Phase Completion: Phase 3 Successful*
