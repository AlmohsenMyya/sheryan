# Edge Resilience and Offline State Synchronization

Phase 4 technical analysis of Sheryan's network fault tolerance, offline action queue, connectivity detection, and emergency edge-state cache.

Target files:

- `lib/services/pending_actions_service.dart`
- `lib/providers/connectivity/connectivity_provider.dart`
- `lib/providers/emergency/emergency_provider.dart`

Supporting flow references:

- `lib/screens/requests/create_request_screen.dart`
- `lib/screens/home/controllers/home_controller.dart`
- `lib/screens/home/home_screen.dart`
- `lib/services/notification_service.dart`
- `lib/screens/donor_dashboard/emergency_alerts_tab.dart`

## 1. Resilience Model Overview

Sheryan implements edge resilience through two complementary mechanisms:

1. **Offline-first synchronization for outbound request creation**
   - Blood requests can be serialized locally when the device is offline.
   - Stored requests are replayed after connectivity returns.
   - Replay triggers the same domain notification event as an online request.

2. **Emergency state shielding for inbound FCM packets**
   - The most recent emergency request ID is cached in Riverpod state.
   - Foreground FCM payloads update this state immediately.
   - The donor emergency tab reacts to this local state even if direct OS notification routing does not carry the user to the correct screen.

In network engineering terms, this is an **edge survivability pattern**. The device temporarily preserves intent and state at the edge when the network or operating-system routing path is unreliable.

## 2. Connectivity Provider: Link-State Signal

`connectivity_provider.dart` exposes a global Riverpod provider:

```text
lib/providers/connectivity/connectivity_provider.dart:5-6
```

```dart
final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);
```

The provider returns a boolean:

- `true` if at least one connectivity result is not `ConnectivityResult.none`.
- `false` if all connectivity results indicate no connection.

The notifier initializes in three steps:

1. `build()` registers disposal cleanup and calls `_init()`.
2. `_init()` performs an initial `Connectivity().checkConnectivity()`.
3. `_init()` subscribes to `Connectivity().onConnectivityChanged`.

The conversion function is:

```text
results.any((r) => r != ConnectivityResult.none)
```

This means the provider is a **link-state indicator**, not a full Internet reachability proof. It can detect Wi-Fi or mobile link availability, but it does not guarantee that Firebase, FCM, DNS, or the public Internet are reachable.

## 3. Offline-First Synchronization

### 3.1 Local Queue Store

`pending_actions_service.dart` defines a SharedPreferences key:

```text
sheryan_pending_blood_requests
```

This key stores a `StringList`, where each item is a JSON-encoded pending request.

The service is a singleton:

```text
PendingActionsService()
```

This gives the app one shared abstraction for offline request persistence and replay.

### 3.2 Queueing a Request During an Outage

`saveRequest()` is implemented in:

```text
lib/services/pending_actions_service.dart:16-25
```

Algorithm:

```text
Input: requestData

1. Load SharedPreferences.
2. Read current string list from sheryan_pending_blood_requests.
3. Create JSON entry from requestData.
4. Add _savedAt timestamp using DateTime.now().toIso8601String().
5. Append JSON entry to the local list.
6. Persist updated list back to SharedPreferences.
```

The `_savedAt` field is metadata for local queue provenance. It records when the edge device accepted the request into its offline buffer.

The queue producer is visible in `create_request_screen.dart`. During submission:

```text
lib/screens/requests/create_request_screen.dart:108-118
```

The screen checks connectivity. If offline, it calls:

```text
PendingActionsService().saveRequest({...})
```

with fields such as:

- `patientName`
- `hospitalId`
- `hospital`
- `city`
- `bloodGroup`
- `requiredUnits`
- `phone`
- `neededAt`

After saving, the app notifies the user that the request was saved offline and returns from the screen.

### 3.3 Queue Inspection

The service provides two read operations:

```text
getPendingCount()
getPendingRequests()
```

`getPendingCount()` returns the number of queued JSON entries.

`getPendingRequests()` decodes each JSON item and removes `_savedAt` before returning the request map. This separates internal queue metadata from the request payload that will later be sent to the backend.

### 3.4 Replay Algorithm

`syncPendingRequests()` is the replay engine:

```text
lib/services/pending_actions_service.dart:43-84
```

Algorithm:

```text
Input: local SharedPreferences queue

1. Load queue list.
2. If empty, return 0.
3. Initialize synced counter.
4. Initialize remaining list.
5. For each queued JSON item:
   a. Decode JSON into map.
   b. Remove _savedAt.
   c. Read current authenticated user ID.
   d. If no user exists, keep the item in remaining.
   e. If user exists, call RequestService().create().
   f. Add userId and _syncedFromOffline to the request payload.
   g. Dispatch BloodRequestCreatedEvent through NotificationEngine.
   h. Increment synced counter.
   i. If any exception occurs, keep the item in remaining.
6. Persist only remaining items back to SharedPreferences.
7. Return synced count.
```

This is a classic **at-least-attempted replay queue**. Successful items are removed. Failed items stay in the local queue for future retries.

### 3.5 Replay Trigger Points

The replay is initiated from `HomeController`:

```text
lib/screens/home/controllers/home_controller.dart:28-42
```

The controller:

1. Checks pending count.
2. Calls `PendingActionsService().syncPendingRequests()`.
3. Shows a success snackbar if one or more items synced.

`HomeScreen` invokes the replay in two places:

1. On reconnect:

```text
lib/screens/home/home_screen.dart:56-61
```

It listens to `connectivityProvider` and when state changes from `false` to `true`, it calls `syncPendingRequests()`.

2. On post-frame initialization:

```text
lib/screens/home/home_screen.dart:136-142
```

After the profile loads and home initialization completes, the app calls `syncPendingRequests()` once. This covers cases where the app starts online with pending requests already stored locally.

### 3.6 Notification Continuity After Replay

A replayed request does not only create a Firestore request. After `RequestService().create()`, the service dispatches:

```text
BloodRequestCreatedEvent
```

through:

```text
NotificationEngine().dispatch(...)
```

This is important because the offline path rejoins the same event-driven messaging architecture as the online path.

The online path in `create_request_screen.dart` also creates a request and dispatches `BloodRequestCreatedEvent`. The offline replay path mirrors this behavior after network recovery.

The resilience goal is:

```text
offline user intent
    -> local queue
    -> network recovery
    -> backend request creation
    -> normal notification routing
```

## 4. Offline Queue Semantics

### 4.1 Fault Tolerance Properties

The queue provides:

- **Temporary local persistence:** queued items survive app screen changes and ordinary app restarts because they are stored in SharedPreferences.
- **Retry preservation:** failed sync attempts remain in the queue.
- **Authentication guard:** if no authenticated user exists during replay, the item remains queued.
- **Event restoration:** replayed requests trigger notification events after successful creation.

### 4.2 Limitations

The queue is lightweight and practical, but it is not a fully durable local database:

- SharedPreferences is appropriate for small payloads, not high-volume transactional queues.
- There is no explicit idempotency key in the payload, so repeated sync after uncertain failures could theoretically duplicate a request if the backend create succeeds but the client throws before removing the queue item.
- Replay is sequential and simple; there is no exponential backoff, retry budget, or conflict resolution protocol.
- `_savedAt` is removed before sync and not sent to the backend, so the server does not retain the original offline creation timestamp.
- Connectivity detection is based on link state, not verified Firebase reachability.

For thesis accuracy, the implementation should be described as a **lightweight offline queue**, not as a complete distributed job scheduler.

## 5. State Shielding: Emergency Provider

### 5.1 Provider Definition

`emergency_provider.dart` contains:

```text
lib/providers/emergency/emergency_provider.dart:3-5
```

```dart
final lastEmergencyRequestIdProvider = StateProvider<String?>((ref) => null);
```

This provider stores the latest emergency blood request ID received through the notification pipeline.

It is intentionally minimal:

- State type: `String?`
- Initial value: `null`
- Meaning: no active emergency request cached locally.

### 5.2 FCM Payload Capture

The emergency provider is updated in `notification_service.dart`, specifically inside `_updateEmergencyState()`:

```text
requestId = data['requestId']
type      = data['type']

if requestId != null && type == 'emergency':
    lastEmergencyRequestIdProvider = requestId
```

This function is called in two important receive paths:

1. Foreground message path:

```text
FirebaseMessaging.onMessage.listen(...)
```

When the app is open and an FCM packet arrives, the provider is updated immediately.

2. Routing path:

```text
_handleRouting(data)
```

When a notification is opened from background or terminated state, routing first updates the provider, then navigates.

The emergency provider therefore acts as a local edge cache for the packet's routing identifier.

### 5.3 Heads-Up Display Behavior

`EmergencyAlertsTab` watches the provider:

```text
lib/screens/donor_dashboard/emergency_alerts_tab.dart:13
```

If the provider is `null`, it displays an empty state. If the provider contains a request ID, it renders:

```text
RequestResponseScreen(requestId: requestId)
```

This creates a reactive "Heads-up Display" state inside the donor dashboard:

```text
FCM emergency packet received
        |
        v
lastEmergencyRequestIdProvider updated
        |
        v
EmergencyAlertsTab rebuilds
        |
        v
RequestResponseScreen appears for that request
```

### 5.4 Why This Is a Shield

Mobile notification routing can fail or behave inconsistently due to:

- app foreground/background/terminated differences,
- OS-level notification interception,
- data-only payload behavior,
- user tapping behavior,
- local notification plugin callback timing,
- platform-specific restrictions.

The emergency provider reduces dependence on direct OS navigation. Even if the operating system does not route the user immediately, the app still captures the emergency `requestId` while foregrounded and exposes it inside the donor dashboard.

This is why it can be documented as **State Shielding**:

```text
network packet data
    -> local reactive cache
    -> UI can recover emergency context
```

The provider shields the user experience from routing failure by preserving the essential routing key at the application edge.

## 6. Edge Caching Interpretation

The emergency provider is an in-memory edge cache:

- It stores the latest emergency request ID.
- It is fast and reactive.
- It is local to the running app process.
- It is not persisted across app restarts.

This makes it suitable for foreground FCM continuity, not long-term emergency history. Durable notification history is handled elsewhere through Firestore notification documents.

The cache has one primary job:

```text
preserve the most recent emergency routing key while the app is active
```

## 7. End-to-End Fault Tolerance Flows

### 7.1 Outbound Offline Request Flow

```text
Recipient creates blood request
        |
        v
Connectivity check
        |
        +-- online --> RequestService.create()
        |              |
        |              `--> NotificationEngine.dispatch(BloodRequestCreatedEvent)
        |
        `-- offline --> PendingActionsService.saveRequest()
                       |
                       `--> SharedPreferences queue
```

### 7.2 Reconnect Replay Flow

```text
ConnectivityProvider detects false -> true
        |
        v
HomeScreen listener fires
        |
        v
HomeController.syncPendingRequests()
        |
        v
PendingActionsService.syncPendingRequests()
        |
        +--> RequestService.create()
        +--> NotificationEngine.dispatch(BloodRequestCreatedEvent)
        +--> remove successful item from queue
        `--> keep failed item in queue
```

### 7.3 Inbound Emergency Shield Flow

```text
FCM emergency data packet
        |
        v
NotificationService._updateEmergencyState()
        |
        v
lastEmergencyRequestIdProvider = requestId
        |
        v
EmergencyAlertsTab reacts
        |
        v
RequestResponseScreen(requestId)
```

## 8. Academic Framing

Sheryan's edge resilience layer can be described as a **client-side fault tolerance mechanism** for both outbound and inbound network uncertainty.

For outbound workflows, the app uses a SharedPreferences-backed offline queue to preserve user intent during network outages. When connectivity returns, the queued request payloads are replayed into the normal backend creation and notification pipeline. This provides eventual synchronization for emergency blood request creation.

For inbound workflows, the emergency provider acts as a lightweight edge cache. It captures the routing identifier from FCM data packets and exposes it to the UI through Riverpod. This creates a local heads-up state that can survive notification routing inconsistencies while the app is active.

Together, these mechanisms form a pragmatic mobile resilience model:

```text
Outbound resilience  -> Offline Queue + Replay
Inbound resilience   -> Emergency Edge Cache + Reactive UI
Network awareness    -> Connectivity Provider
User feedback        -> Offline/Back-online banner
```

The design is academically relevant because it demonstrates how mobile applications can implement network fault tolerance at the edge without a full local database or backend job scheduler. The implementation is lightweight, but it clearly separates intent preservation, link-state monitoring, replay, and emergency-state shielding.

## 9. Thesis Notes

Useful phrasing for the thesis:

- "The application implements a lightweight offline queue to preserve blood request creation intent during temporary network partitions."
- "Connectivity state is modeled as a reactive Riverpod provider, allowing the UI and synchronization controller to respond to link-state changes."
- "Emergency FCM payloads are cached locally in a StateProvider, creating a heads-up display state that reduces dependence on OS notification routing."
- "The offline queue provides eventual synchronization, while the emergency provider provides ephemeral edge caching."
- "The implementation prioritizes pragmatic mobile resilience over full distributed job durability."
