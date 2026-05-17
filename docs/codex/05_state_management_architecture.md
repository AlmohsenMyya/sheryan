# State Management Architecture and Reactive Data Flow

Phase 5 technical analysis of Sheryan's Riverpod-based state architecture, global providers, feature-scoped controllers, and reactive data propagation.

Target files:

- `lib/providers/auth/auth_provider.dart`
- `lib/providers/points/points_provider.dart`
- `lib/screens/home/controllers/home_controller.dart`
- `lib/screens/hospital/controllers/hospital_requests_controller.dart`

This document focuses on Separation of Concerns, Reactive Programming, Dependency Injection, and State Encapsulation.

## 1. Architectural Overview

Sheryan uses Riverpod as the primary state management and dependency access layer. The application combines two complementary patterns:

1. **Global state providers**
   - Cross-cutting state such as authentication, user profile, role, points, points history, rewards, and redemptions.
   - Mostly implemented with `StreamProvider`, `Provider`, and `StateNotifierProvider`.

2. **Feature-scoped controllers**
   - Screen/domain-specific command handlers such as `HomeController` and `HospitalRequestsController`.
   - Exposed through `Provider`.
   - Usually invoked through `ref.read(...)` for imperative actions.

This creates a hybrid state architecture:

```text
Firebase / Services / Repositories
        |
        v
Riverpod Global Providers
        |
        +--> Reactive UI via ref.watch(...)
        |
        `--> Feature Controllers via Ref
                  |
                  +--> service calls
                  +--> notification events
                  +--> navigation/snackbars
                  `--> provider invalidation or notifier mutation
```

The system therefore separates continuously changing data streams from user-triggered commands.

## 2. Global State Providers

### 2.1 Auth Provider

`auth_provider.dart` defines the authentication state backbone.

#### AuthService Dependency

```text
lib/providers/auth/auth_provider.dart:8-9
```

```dart
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
```

This provider exposes `AuthService` through Riverpod. It allows controllers and screens to retrieve the service without constructing it directly.

Example usage:

```text
HomeController.signOut()
    -> _ref.read(authServiceProvider).logoutUser()
```

This is Riverpod acting as a lightweight dependency injection container.

#### Authentication Stream

```text
lib/providers/auth/auth_provider.dart:11-14
```

```dart
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

This wraps Firebase Authentication's stream into Riverpod. Any widget or provider that watches `authStateProvider` reacts automatically when:

- user signs in,
- user signs out,
- token/session state changes.

The UI does not poll Firebase. It subscribes declaratively through Riverpod.

#### User Profile Stream

```text
lib/providers/auth/auth_provider.dart:16-21
```

```dart
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return UserService().watchProfile(user.uid);
});
```

This provider composes state:

```text
authStateProvider
        |
        v
userProfileProvider
        |
        v
UserService.watchProfile(uid)
```

If there is no authenticated user, the provider emits `null`. If a user exists, it subscribes to the user's Firestore profile stream.

This is a key reactive programming pattern: one provider depends on another provider, and Riverpod recalculates the dependent stream when the upstream authentication state changes.

#### Role State

```text
lib/providers/auth/auth_provider.dart:23-57
```

`roleProvider` is a `StateNotifierProvider<RoleNotifier, UserRole?>`. It stores a normalized local enum representation of the user's role.

`RoleNotifier` exposes:

- `setRole(UserRole role)`
- `setRoleFromString(String? roleStr)`
- `clearRole()`

This encapsulates role parsing and mutation logic away from UI widgets. Screens do not need to duplicate string-to-enum conversion logic.

## 3. Points and Rewards Providers

`points_provider.dart` defines reward-related reactive streams.

### 3.1 Points Stream

```text
lib/providers/points/points_provider.dart:6-10
```

```dart
final pointsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({'points': 0, 'tier': 'bronze'});
  return UserService().watchPoints(user.uid);
});
```

This provider depends on `authStateProvider`. When the current user changes, the points stream is rebuilt for the new user.

The fallback value:

```text
{'points': 0, 'tier': 'bronze'}
```

prevents null-heavy UI logic for unauthenticated or loading states.

### 3.2 Points History Stream

```text
lib/providers/points/points_provider.dart:12-17
```

`pointsHistoryProvider` uses the same auth-dependent structure:

```text
auth user -> UserService.watchPointsHistory(uid)
```

This provides a real-time stream of point ledger entries.

### 3.3 Reward Repository Streams

`points_provider.dart` also defines:

- `sponsorRewardsProvider`
- `cityRewardsProvider`
- `sponsorRedemptionsCountProvider`

These are `StreamProvider.family` declarations. The `.family` modifier parameterizes the provider by a runtime key such as `sponsorId` or `city`.

Example:

```dart
ref.watch(cityRewardsProvider(_selectedCity))
```

This turns reward queries into reactive, cacheable provider instances keyed by business identifiers.

The file constructs:

```dart
final _rewardRepo = FirebaseRewardRepository();
```

and then uses repository stream methods:

- `watchBySponsor(sponsorId)`
- `watchByCity(city)`
- `watchRedemptionsCount(sponsorId)`

Architecturally, this is repository-backed reactive state. The UI observes provider output, while the repository owns Firestore query details.

## 4. Feature-Scoped Controllers

### 4.1 HomeController

`home_controller.dart` exposes:

```text
lib/screens/home/controllers/home_controller.dart:11
```

```dart
final homeControllerProvider = Provider((ref) => HomeController(ref));
```

This provider injects Riverpod's `Ref` into `HomeController`, allowing the controller to read other providers while remaining outside the widget tree.

`HomeController` handles three command-style responsibilities:

1. Initialize notification services.
2. Synchronize pending offline requests.
3. Sign out and reset role state.

#### Notification Initialization

```text
lib/screens/home/controllers/home_controller.dart:17-26
```

`initNotifications()` calls:

- `NotificationService().init(context)`
- `NotificationService().sendUserTags(...)`

It receives the current profile from the UI and extracts city, blood group, and role. This keeps notification setup out of the visual widget code.

#### Offline Sync

```text
lib/screens/home/controllers/home_controller.dart:28-42
```

`syncPendingRequests()`:

1. Reads pending queue count.
2. Replays queued requests if present.
3. Shows a snackbar when replay succeeds.

This method coordinates UI feedback with service-layer synchronization while keeping the actual queue logic inside `PendingActionsService`.

#### Sign Out

```text
lib/screens/home/controllers/home_controller.dart:44-60
```

`signOut()`:

1. Attempts notification logout.
2. Logs out through `authServiceProvider`.
3. Falls back to direct `AuthService()` if provider path fails.
4. Clears `roleProvider`.
5. Navigates to `LoginScreen`.

This demonstrates controller-level orchestration: service call, provider mutation, and navigation are grouped into a feature-level command.

### 4.2 HospitalRequestsController

`hospital_requests_controller.dart` exposes:

```text
lib/screens/hospital/controllers/hospital_requests_controller.dart:11
```

```dart
final hospitalRequestsProvider = Provider((ref) => HospitalRequestsController(ref));
```

The controller owns hospital request commands:

- verify request,
- look up donor,
- complete manual donation.

It holds service dependencies:

```text
RequestService
UserService
DonationService
```

#### Request Verification

```text
lib/screens/hospital/controllers/hospital_requests_controller.dart:21-47
```

`markVerified()`:

1. Extracts `requestId`.
2. Calls `_requestService.markVerified(requestId)`.
3. Dispatches `BloodRequestVerifiedEvent`.
4. Performs UI feedback through navigation and snackbar.

This is a feature-level command that bridges:

```text
Hospital UI action
    -> RequestService mutation
    -> NotificationEngine event
    -> UI acknowledgement
```

#### Donor Lookup

```text
lib/screens/hospital/controllers/hospital_requests_controller.dart:49-63
```

`lookupDonor()` reads donor data through `UserService.getById(uid)` and returns a map to the caller. Errors are translated into UI snackbars.

#### Manual Donation Completion

```text
lib/screens/hospital/controllers/hospital_requests_controller.dart:65-102
```

`completeManualDonation()`:

1. Calls `_donationService.registerDonation(...)`.
2. Dispatches `DonationRegisteredEvent`.
3. Shows success or error feedback.

This separates donation business mutation from the dialog widget that invokes it.

## 5. Global vs. Feature-Scoped State

The system uses a practical split:

| Category | Examples | Purpose |
|---|---|---|
| Global reactive state | `authStateProvider`, `userProfileProvider`, `pointsProvider`, `pointsHistoryProvider` | Data that many screens need and that changes over time |
| Global mutable state | `roleProvider` | Local application role selection and clearing |
| Parameterized global streams | `cityRewardsProvider(city)`, `sponsorRewardsProvider(sponsorId)` | Data streams keyed by domain identifiers |
| Feature-scoped controllers | `homeControllerProvider`, `hospitalRequestsProvider` | Imperative commands for a screen or feature area |

The boundary can be summarized as:

```text
ref.watch(...) -> subscribe to data
ref.read(...)  -> execute a command
```

Global providers answer "what is the current state?" Controllers answer "what should happen after this user action?"

## 6. Reactive UI Updates

### 6.1 StreamProvider as Real-Time Data Binding

`StreamProvider` is used to bind Firebase streams to the widget tree:

- auth state from Firebase Auth,
- user profile from Firestore,
- points data from Firestore,
- rewards and redemption counts from repository streams.

When Firestore emits a new snapshot, Riverpod updates the provider state. Widgets using `ref.watch(...)` rebuild automatically with the new `AsyncValue`.

This prevents manual subscription management inside widgets. The screen does not need to call `listen()`, store a `StreamSubscription`, or cancel it manually in `dispose()`.

### 6.2 Memory Leak Prevention

Riverpod manages provider lifecycles and stream subscriptions. This reduces memory leak risk compared with manual stream handling because:

- subscriptions are owned by providers,
- widgets declaratively watch provider state,
- providers are disposed when no longer needed under Riverpod lifecycle rules,
- controllers are retrieved from providers rather than permanently stored in widget state.

In this architecture, UI classes generally consume state rather than owning long-running listeners directly.

### 6.3 AsyncValue Boundary

Providers such as `userProfileProvider` and reward providers expose asynchronous state. Screens can handle:

- loading,
- error,
- data.

This establishes a formal boundary between data availability and presentation. For example, `HomeScreen` watches `userProfileProvider`, then builds loading, error, or role-specific dashboard states.

### 6.4 Reactive Composition

`userProfileProvider` and `pointsProvider` both watch `authStateProvider`. This creates reactive composition:

```text
FirebaseAuth authStateChanges()
        |
        +--> userProfileProvider
        |
        `--> pointsProvider / pointsHistoryProvider
```

When the authenticated user changes, dependent streams automatically switch to the new user or emit fallback values.

## 7. Dependency Injection

Riverpod acts as a dependency injection container in three ways.

### 7.1 Service Injection

`authServiceProvider` exposes `AuthService`. `HomeController` reads it through:

```dart
_ref.read(authServiceProvider).logoutUser()
```

This means code using `HomeController` does not need to construct `AuthService` directly.

### 7.2 Controller Injection

Controllers are themselves injected through providers:

```text
homeControllerProvider
hospitalRequestsProvider
```

Widgets call:

```dart
ref.read(homeControllerProvider)
ref.read(hospitalRequestsProvider)
```

This keeps controller construction centralized and gives controllers access to `Ref`.

### 7.3 Parameterized Repository Access

`StreamProvider.family` acts as dependency injection plus query parameterization:

```text
cityRewardsProvider(city)
sponsorRewardsProvider(sponsorId)
sponsorRedemptionsCountProvider(sponsorId)
```

The UI supplies a domain key, and Riverpod resolves the appropriate repository-backed stream.

## 8. Separation of Concerns

The architecture partially enforces Separation of Concerns:

- Providers expose state.
- Services and repositories perform external data operations.
- Controllers orchestrate feature commands.
- Widgets render data and invoke commands.
- Notification events are dispatched after domain mutations.

Example:

```text
ManualFulfillDialog
    -> ref.read(hospitalRequestsProvider).completeManualDonation(...)
        -> DonationService.registerDonation(...)
        -> NotificationEngine.dispatch(DonationRegisteredEvent)
        -> Snackbar feedback
```

This avoids placing all donation logic directly inside the dialog.

## 9. Architectural Limitations

The implementation is pragmatic rather than perfectly pure:

- Some providers instantiate services directly, such as `UserService()` inside `userProfileProvider` and `pointsProvider`.
- `points_provider.dart` creates a module-level `_rewardRepo` rather than exposing it through a repository provider.
- Controllers mix domain orchestration with UI concerns such as `BuildContext`, `Navigator`, and `ScaffoldMessenger`.
- Some controller dependencies are manually constructed inside the controller instead of injected as provider dependencies.
- The `_ref` field in `HospitalRequestsController` is currently available but not meaningfully used in the target file.

These are acceptable for a graduation project and useful to document honestly. The observed pattern is a hybrid:

```text
Riverpod-managed global state
+ Provider-exposed feature controllers
+ direct service construction in some areas
```

## 10. Academic Framing

Sheryan's state architecture can be described as a **Riverpod-centered reactive state model**. Global application state is modeled as streams and notifiers, while feature-specific commands are encapsulated in provider-exposed controllers.

The key software engineering value is separation between:

- continuously changing data,
- user-triggered commands,
- external services,
- UI presentation.

Riverpod enables reactive programming by allowing widgets to watch provider state declaratively. It also acts as a dependency injection container by exposing services and controllers through providers. This reduces manual object wiring and gives the application a consistent access pattern for authentication, profile state, points state, offline synchronization commands, hospital request commands, and notification initialization.

For the thesis, this layer should be presented as a pragmatic state-management architecture that balances real-time Firebase streams with feature-scoped command controllers. Its strongest design property is reactive data flow; its main improvement opportunity is deeper dependency injection for services and repositories to reduce direct construction and increase testability.
