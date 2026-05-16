# 🕵️ Notification Routing Audit & Donor UX Refactor Blueprint

## 1. Push Notification Routing: Phase A Implementation

### 1.1 Pure Data Payloads (Emergency Alerts)
To prevent "OS Hijack" where the System UI intercepts notification clicks and fails to pass data to Dart, we have transitioned emergency alerts to **Data-only payloads**.
*   **Backend Change:** The `"notification"` block is now omitted for emergency types.
*   **Payload Specification:**
    ```json
    "data": {
      "type": "emergency",
      "requestId": "...",
      "titleEn": "...",
      "titleAr": "...",
      "bodyEn": "...",
      "bodyAr": "...",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    }
    ```
*   **Client Handling:** The app now manually triggers a Local Notification via `flutter_local_notifications` upon receiving these background messages, ensuring full control over the tap event.

### 1.2 Early Initialization & Lifecycle Hooks
*   **Race Condition Fix:** Notification handlers are now initialized in `main.dart` before the Splash timer begins.
*   **Global Navigator:** Added `navigatorKey` to `MaterialApp` to allow context-less routing from the `NotificationService`.
*   **Background Handling:** Registered a top-level `@pragma('vm:entry-point')` handler for background messages to ensure local notifications are shown even when the app is terminated.

## 2. Donor Navigation Refactoring: The "Emergency Hub" (Phase B Implementation)

### 2.1 Tab Swap & UX Optimization
*   **Action:** Removed the "All Donors" directory for ordinary donors.
*   **Replacement:** Introduced the **"Emergency Alerts" (نداءات الاستغاثة)** tab at index 1 of the Bottom Navigation Bar.
*   **Icon:** `Icons.campaign_rounded` for high visibility.

### 2.2 The State Shield (`lastEmergencyRequestIdProvider`)
*   **Mechanism:** Created a global Riverpod `StateProvider` to store the ID of the most recent incoming emergency alert.
*   **Integration:** The `NotificationService` now updates this state immediately upon receiving a data-only payload (Foreground/Background/Terminated).
*   **Fallback Logic:** If push-routing fails at the OS level, the donor can manually tap the tab to see the active request details immediately.
*   **Empty State:** When no ID is present, the system displays a localized "System All Clear" screen.

## 3. In-App Notification Enhancement: The "Action Bridge" (Phase C Implementation)
*   **Feature:** Introduced a context-aware action bridge for emergency notifications.
*   **UI Injection:** Inside `notifications_screen.dart`, any card with `NotificationType.emergency` now features a prominent **"View Details" (عرض التفاصيل)** button.
*   **Safe Navigation:** Tapping the button triggers a context-based `Navigator.push` to the `RequestResponseScreen`.
*   **Null-Safety:** Added a guard to prevent navigation if `requestId` is null or malformed, displaying a localized error snackbar instead.

---
*Status: All Phases (A, B, C) Complete. Notification Routing Architecture is LOCKED and production-ready.*
