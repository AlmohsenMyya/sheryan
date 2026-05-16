# Recipient Flow Implementation: Cooldown UI & Manual Dispatch (Phase 4 & 5)

## 1. Overview
This final phase completed the ecosystem by providing the recipient with a real-time control interface for managing blood request notifications. We implemented a reactive cooldown banner that prevents spam while allowing for the targeted expansion of the donor pool.

## 2. UI Component: `StagedCooldownBanner`

### 2.1 Reactive State Management
The banner utilizes a `StreamProvider.family` (`requestStreamProvider`) to monitor the specific blood request in Firestore. This ensures that as soon as a batch is dispatched (either automatically by the hospital or manually by the recipient), the UI reflects the new state (incremented count and reset timer) across all devices.

### 2.2 Precise Countdown Logic
To ensure accuracy and resist local time manipulation, the countdown logic:
1. Fetches the `lastNotificationSentAt` server timestamp.
2. Calculates the `targetTime` (Timestamp + 30 minutes).
3. Uses a local `Timer.periodic` (1s) to compute the difference between `DateTime.now()` and `targetTime`.
4. Formatting: Displays remaining time in `MM:SS` format.

### 2.3 The Four Button States
- **State A (Cooldown Active):** The button is `FilledButton.tonal` and disabled. It displays "Next batch available in MM:SS".
- **State B (Ready):** The button is enabled. It displays "Notify 10 More Donors".
- **State C (Loading):** While the Firestore transaction is processing, a `CircularProgressIndicator` is shown inside the button.
- **State D (Exhausted):** If the service returns a "Pool exhausted" flag, the button becomes permanently disabled with the text "All compatible donors notified".

## 3. Integration & Safety Guards

### 3.1 Visibility Logic
The banner is injected into `lib/screens/requests/requests_list_screen.dart` with strict visibility rules:
```dart
if (status == 'done' || status == 'completed' || !isVerified) {
  return SizedBox.shrink();
}
```
This ensures that fulfilled requests or requests awaiting hospital verification do not show notification controls.

### 3.2 Null Safety (Legacy Support)
The widget handles `null` values for `lastNotificationSentAt` and `notifiedDonorIds` gracefully, treating legacy requests as "Ready" for their first staged batch if they are verified.

## 4. Localization
Strict adherence to `AppLocalizations` was maintained for both English and Arabic. 
New keys integrated:
- `stagedNotifiedCount(count)`
- `nextBatchAvailable(time)`
- `notifyMoreDonors`
- `allDonorsNotified`

## 5. Memory Management
The `Timer.periodic` is instantiated in `initState` and strictly cancelled in `dispose` to prevent memory leaks as the user scrolls through or leaves the request list.

---
*Date: May 2026*
*Phase Completion: Phase 4 & 5 Successful*
*Status: Ecosystem Fully Deployed*
