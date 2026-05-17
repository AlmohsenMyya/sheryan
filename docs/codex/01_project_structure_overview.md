# Sheryan Project Structure Overview

Phase 1 structural X-ray of the Flutter `lib/` directory. This document is intentionally macro-level: it maps where code currently lives and identifies architectural boundaries without line-by-line analysis.

## 1. Directory Tree

```text
lib/
|-- main.dart
|-- firebase_options.dart
|-- core/
|   |-- enums/
|   |   `-- user_role.dart
|   |-- models/
|   |   `-- app_notification.dart
|   |-- theme/
|   |   |-- app_colors.dart
|   |   |-- app_design_constants.dart
|   |   |-- app_theme.dart
|   |   `-- app_typography.dart
|   `-- utils/
|       |-- blood_logic.dart
|       |-- points_ui_utils.dart
|       |-- profile_completion.dart
|       |-- qr_dialog.dart
|       `-- whatsapp_helper.dart
|-- events/
|   |-- app_event.dart
|   `-- notification_engine.dart
|-- l10n/
|   |-- app_ar.arb
|   |-- app_en.arb
|   |-- app_localizations.dart
|   |-- app_localizations_ar.dart
|   `-- app_localizations_en.dart
|-- providers/
|   |-- auth/
|   |   `-- auth_provider.dart
|   |-- connectivity/
|   |   `-- connectivity_provider.dart
|   |-- emergency/
|   |   `-- emergency_provider.dart
|   |-- locale/
|   |   `-- locale_provider.dart
|   |-- points/
|   |   `-- points_provider.dart
|   `-- theme/
|       `-- theme_provider.dart
|-- repositories/
|   |-- firebase/
|   |   |-- firebase_announcement_repository.dart
|   |   |-- firebase_city_repository.dart
|   |   |-- firebase_donation_repository.dart
|   |   |-- firebase_hospital_repository.dart
|   |   |-- firebase_request_repository.dart
|   |   |-- firebase_reward_repository.dart
|   |   `-- firebase_user_repository.dart
|   `-- interfaces/
|       |-- announcement_repository.dart
|       |-- city_repository.dart
|       |-- donation_repository.dart
|       |-- hospital_repository.dart
|       |-- request_repository.dart
|       |-- reward_repository.dart
|       `-- user_repository.dart
|-- services/
|   |-- announcement_service.dart
|   |-- auth_service.dart
|   |-- donation_service.dart
|   |-- hospital_service.dart
|   |-- notification_service.dart
|   |-- pending_actions_service.dart
|   |-- points_service.dart
|   |-- request_service.dart
|   |-- staged_notification_service.dart
|   `-- user_service.dart
|-- screens/
|   |-- admin/
|   |   |-- admin_dashboard.dart
|   |   |-- broadcast/
|   |   |   |-- broadcast_controller.dart
|   |   |   `-- broadcast_view.dart
|   |   |-- cities/
|   |   |   `-- city_manager_view.dart
|   |   |-- controllers/
|   |   |   `-- admin_general_controller.dart
|   |   |-- donors/
|   |   |   `-- donor_manager_view.dart
|   |   |-- hospital_admins/
|   |   |   |-- create_hospital_admin_dialog.dart
|   |   |   |-- edit_hospital_admin_dialog.dart
|   |   |   |-- hospital_admin_controller.dart
|   |   |   `-- hospital_admin_view.dart
|   |   |-- hospitals/
|   |   |   `-- hospital_manager_view.dart
|   |   |-- overview/
|   |   |   `-- admin_overview_view.dart
|   |   |-- requests/
|   |   |   `-- blood_requests_admin_view.dart
|   |   |-- sponsors/
|   |   |   |-- create_sponsor_dialog.dart
|   |   |   |-- edit_sponsor_dialog.dart
|   |   |   |-- sponsor_controller.dart
|   |   |   `-- sponsor_manager_view.dart
|   |   `-- widgets/
|   |       |-- admin_dialogs.dart
|   |       |-- admin_sidebar.dart
|   |       |-- blood_group_badge.dart
|   |       |-- empty_state.dart
|   |       |-- section_header.dart
|   |       `-- status_badge.dart
|   |-- auth/
|   |   |-- role_selection_screen.dart
|   |   |-- sign_in_screen.dart
|   |   `-- sign_up_screen.dart
|   |-- donor_dashboard/
|   |   |-- blood_compatibility_screen.dart
|   |   |-- donation_history_screen.dart
|   |   |-- donor_settings.dart
|   |   |-- donors_details.dart
|   |   |-- donors_list.dart
|   |   |-- donors_profile.dart
|   |   |-- emergency_alerts_tab.dart
|   |   |-- nearby_users_req.dart
|   |   |-- profile_sections/
|   |   |   |-- basic_info_screen.dart
|   |   |   |-- emergency_contact_screen.dart
|   |   |   |-- health_info_screen.dart
|   |   |   `-- medical_history_screen.dart
|   |   |-- rewards_screen.dart
|   |   `-- see_users_request.dart
|   |-- donors/
|   |   |-- donor_detail_screen.dart
|   |   |-- donors_list_screen.dart
|   |   |-- nearby_donors_screen.dart
|   |   `-- request_response_screen.dart
|   |-- home/
|   |   |-- controllers/
|   |   |   `-- home_controller.dart
|   |   |-- home_screen.dart
|   |   |-- providers/
|   |   |   `-- home_providers.dart
|   |   `-- widgets/
|   |       |-- action_card.dart
|   |       |-- home_app_bar.dart
|   |       |-- long_action_card.dart
|   |       |-- motivational_banner.dart
|   |       `-- user_welcome_header.dart
|   |-- hospital/
|   |   |-- controllers/
|   |   |   |-- hospital_profile_controller.dart
|   |   |   |-- hospital_requests_controller.dart
|   |   |   `-- scanner_controller.dart
|   |   |-- dashboard/
|   |   |   `-- hospital_stats_bar.dart
|   |   |-- history/
|   |   |   `-- donation_history_tab.dart
|   |   |-- hospital_dashboard.dart
|   |   |-- profile/
|   |   |   `-- hospital_profile_tab.dart
|   |   |-- requests/
|   |   |   |-- manual_fulfill_dialog.dart
|   |   |   |-- request_card.dart
|   |   |   |-- request_detail_sheet.dart
|   |   |   `-- requests_tab.dart
|   |   |-- scanner/
|   |   |   |-- blood_group_verification_screen.dart
|   |   |   `-- scanner_screen.dart
|   |   `-- widgets/
|   |       |-- action_btn.dart
|   |       |-- detail_row.dart
|   |       `-- status_chip.dart
|   |-- hospitals/
|   |   |-- nearby_hospitals_screen.dart
|   |   |-- providers/
|   |   |   `-- nearby_hospitals_provider.dart
|   |   `-- widgets/
|   |       `-- hospital_card.dart
|   |-- misc/
|   |   |-- awareness_screen.dart
|   |   |-- notifications_screen.dart
|   |   `-- splash_screen.dart
|   |-- profile/
|   |   |-- controllers/
|   |   |   `-- profile_controller.dart
|   |   |-- user_profile_screen.dart
|   |   `-- widgets/
|   |       |-- edit_profile_sheet.dart
|   |       |-- profile_header.dart
|   |       |-- profile_info_section.dart
|   |       `-- profile_stats.dart
|   |-- requests/
|   |   |-- create_request_screen.dart
|   |   |-- providers/
|   |   |   `-- staged_notification_provider.dart
|   |   |-- requests_list_screen.dart
|   |   `-- widgets/
|   |       `-- staged_cooldown_banner.dart
|   |-- settings/
|   |   |-- developer_profile_screen.dart
|   |   `-- userside_settings_screen.dart
|   `-- sponsor/
|       |-- manage_reward_screen.dart
|       |-- scan_redeem_screen.dart
|       `-- sponsor_dashboard.dart
`-- widgets/
    |-- notification_badge.dart
    `-- offline_banner.dart
```

## 2. Architectural Reality Check

The observed architecture is **hybrid**:

- **Layer-first foundations exist** in `core/`, `providers/`, `repositories/`, and `services/`.
- **Feature-first UI organization dominates** under `screens/`, where app areas such as `admin`, `hospital`, `donor_dashboard`, `requests`, `settings`, and `sponsor` own their views, local controllers, widgets, and some providers.
- **Repository abstraction is present but not universal.** The `repositories/interfaces/` and `repositories/firebase/` folders define a clean database access direction for users, requests, hospitals, donations, cities, announcements, and rewards. However, many screens and some providers still call `FirebaseFirestore.instance` directly.
- **Services contain major business workflows.** `services/notification_service.dart`, `services/staged_notification_service.dart`, `services/points_service.dart`, and `services/pending_actions_service.dart` are central behavior files, not just thin API wrappers.
- **Controllers are partially feature-scoped.** Admin, hospital, home, profile, and scanner logic lives inside `screens/.../controllers/` or adjacent controller files. This is pragmatic, but it means state/business behavior is split between global providers, services, repositories, and screen-owned controllers.

Areas where UI and heavier logic appear tightly coupled:

- `lib/screens/donor_dashboard/` contains large UI screens with direct Firestore access in files such as `donors_list.dart`, `nearby_users_req.dart`, `see_users_request.dart`, `rewards_screen.dart`, and profile section screens.
- `lib/screens/settings/userside_settings_screen.dart` and `lib/screens/donor_dashboard/donor_settings.dart` combine account UI, authentication re-check flows, and Firestore deletion/update calls.
- `lib/screens/requests/create_request_screen.dart`, `lib/screens/requests/requests_list_screen.dart`, and `lib/screens/requests/widgets/staged_cooldown_banner.dart` are UI-facing request flow files that also trigger notification/event behavior.
- `lib/screens/sponsor/manage_reward_screen.dart`, `lib/screens/sponsor/scan_redeem_screen.dart`, and parts of `sponsor_dashboard.dart` directly interact with Firestore despite the existence of reward and points providers/services.
- `lib/screens/misc/notifications_screen.dart` owns a large amount of notification inbox UI and directly reads/writes notification state through Firestore and `NotificationService`.

High-level conclusion: Sheryan is not a strict clean/layered architecture. It is best documented as a **hybrid Flutter/Riverpod/Firebase architecture** with a layered core, feature-first screens, and several transitional areas where data access and business workflows still live near UI.

## 3. Core Systems Mapping

### Firestore Transactions and Database Operations

Primary repository-backed database layer:

- `lib/repositories/interfaces/user_repository.dart`
- `lib/repositories/interfaces/request_repository.dart`
- `lib/repositories/interfaces/donation_repository.dart`
- `lib/repositories/interfaces/hospital_repository.dart`
- `lib/repositories/interfaces/city_repository.dart`
- `lib/repositories/interfaces/announcement_repository.dart`
- `lib/repositories/interfaces/reward_repository.dart`
- `lib/repositories/firebase/firebase_user_repository.dart`
- `lib/repositories/firebase/firebase_request_repository.dart`
- `lib/repositories/firebase/firebase_donation_repository.dart`
- `lib/repositories/firebase/firebase_hospital_repository.dart`
- `lib/repositories/firebase/firebase_city_repository.dart`
- `lib/repositories/firebase/firebase_announcement_repository.dart`
- `lib/repositories/firebase/firebase_reward_repository.dart`

Service-level database/business operations:

- `lib/services/auth_service.dart` - Firebase Auth, user document creation/update, FCM token association.
- `lib/services/request_service.dart` - request-domain service wrapper.
- `lib/services/donation_service.dart` - donation-domain workflow support.
- `lib/services/hospital_service.dart` - hospital-domain workflow support.
- `lib/services/announcement_service.dart` - announcement-domain workflow support.
- `lib/services/user_service.dart` - user-domain workflow support.
- `lib/services/points_service.dart` - points ledger and reward redemption logic.
- `lib/services/staged_notification_service.dart` - staged emergency notification batch/cooldown writes.
- `lib/services/notification_service.dart` - notification inbox writes, FCM token lookups, donor targeting, read state.
- `lib/services/pending_actions_service.dart` - offline/pending action replay that can dispatch notification events.

Observed Firestore transaction hotspots:

- `lib/repositories/firebase/firebase_donation_repository.dart` - donation registration / request update transaction path.
- `lib/services/points_service.dart` - points award and reward redemption transactions.
- `lib/services/staged_notification_service.dart` - staged notification cooldown/batch transaction paths.

Known direct Firestore access outside repositories/services:

- `lib/main.dart` - global Firestore cache/persistence settings.
- `lib/providers/auth/auth_provider.dart` - auth/user profile streams.
- `lib/providers/points/points_provider.dart` - points, reward, and redemption streams.
- `lib/screens/requests/providers/staged_notification_provider.dart` - blood request stream for staged notification UI.
- `lib/screens/hospitals/providers/nearby_hospitals_provider.dart` - city and hospital streams.
- `lib/screens/auth/sign_in_screen.dart`
- `lib/screens/auth/sign_up_screen.dart`
- `lib/screens/settings/userside_settings_screen.dart`
- `lib/screens/donor_dashboard/donor_settings.dart`
- `lib/screens/donor_dashboard/donation_history_screen.dart`
- `lib/screens/donor_dashboard/donors_list.dart`
- `lib/screens/donor_dashboard/donors_details.dart`
- `lib/screens/donor_dashboard/nearby_users_req.dart`
- `lib/screens/donor_dashboard/see_users_request.dart`
- `lib/screens/donor_dashboard/rewards_screen.dart`
- `lib/screens/donor_dashboard/profile_sections/basic_info_screen.dart`
- `lib/screens/donor_dashboard/profile_sections/emergency_contact_screen.dart`
- `lib/screens/donor_dashboard/profile_sections/health_info_screen.dart`
- `lib/screens/donor_dashboard/profile_sections/medical_history_screen.dart`
- `lib/screens/donors/donors_list_screen.dart`
- `lib/screens/donors/donor_detail_screen.dart`
- `lib/screens/donors/nearby_donors_screen.dart`
- `lib/screens/misc/notifications_screen.dart`
- `lib/screens/profile/widgets/edit_profile_sheet.dart`
- `lib/screens/sponsor/manage_reward_screen.dart`
- `lib/screens/sponsor/scan_redeem_screen.dart`
- `lib/screens/sponsor/sponsor_dashboard.dart`

### FCM and Staged Notification Routing Logic

FCM initialization and message handling:

- `lib/main.dart` - creates `NotificationService` during app startup and calls `initializeNotificationHandlers()`.
- `lib/services/notification_service.dart` - central FCM and local notification service. Handles Firebase Messaging listeners, background handler setup, foreground messages, opened-app messages, initial messages, FCM token writes, local notification display, notification inbox writes, and read state updates.
- `lib/services/auth_service.dart` - obtains or stores FCM token as part of auth/user setup.

Event-based notification routing:

- `lib/events/app_event.dart` - sealed event hierarchy for domain events that can trigger notifications.
- `lib/events/notification_engine.dart` - central dispatcher translating domain events into notification service calls.

Staged notification flow:

- `lib/services/staged_notification_service.dart` - batch dispatch, cooldown enforcement, request metadata updates, and staged donor notification orchestration.
- `lib/screens/requests/providers/staged_notification_provider.dart` - provider exposing request state to staged notification UI.
- `lib/screens/requests/widgets/staged_cooldown_banner.dart` - UI for staged cooldown state and manual next-batch triggering.
- `lib/screens/requests/create_request_screen.dart` - dispatches request-created notification event.
- `lib/screens/requests/requests_list_screen.dart` - dispatches request-closed event and includes staged notification UI.
- `lib/services/pending_actions_service.dart` - can replay pending request actions and dispatch notification events.
- `lib/screens/misc/notifications_screen.dart` - user-facing notification inbox and notification action handling.

### Global State Management (Riverpod)

Riverpod bootstrap:

- `lib/main.dart` - creates global `ProviderContainer` and wraps the app with `UncontrolledProviderScope`.

Global provider folders:

- `lib/providers/auth/auth_provider.dart` - auth service provider, auth state stream, user profile stream, current role state.
- `lib/providers/theme/theme_provider.dart` - theme mode state and derived theme.
- `lib/providers/locale/locale_provider.dart` - locale state.
- `lib/providers/connectivity/connectivity_provider.dart` - connectivity state.
- `lib/providers/emergency/emergency_provider.dart` - last emergency request state.
- `lib/providers/points/points_provider.dart` - points, points history, sponsor rewards, city rewards, redemption count streams.

Feature-scoped providers/controllers:

- `lib/screens/home/providers/home_providers.dart` - current user role derived provider.
- `lib/screens/home/controllers/home_controller.dart`
- `lib/screens/requests/providers/staged_notification_provider.dart`
- `lib/screens/hospitals/providers/nearby_hospitals_provider.dart`
- `lib/screens/admin/controllers/admin_general_controller.dart`
- `lib/screens/admin/broadcast/broadcast_controller.dart`
- `lib/screens/admin/hospital_admins/hospital_admin_controller.dart`
- `lib/screens/admin/sponsors/sponsor_controller.dart`
- `lib/screens/hospital/controllers/hospital_requests_controller.dart`
- `lib/screens/hospital/controllers/hospital_profile_controller.dart`
- `lib/screens/hospital/controllers/scanner_controller.dart`
- `lib/screens/profile/controllers/profile_controller.dart`

### Main Epic Screens

App entry and routing:

- `lib/main.dart`
- `lib/screens/misc/splash_screen.dart`
- `lib/screens/auth/role_selection_screen.dart`
- `lib/screens/auth/sign_in_screen.dart`
- `lib/screens/auth/sign_up_screen.dart`
- `lib/screens/home/home_screen.dart`

Donor dashboard and donor-facing epic:

- `lib/screens/donor_dashboard/donors_profile.dart`
- `lib/screens/donor_dashboard/donor_settings.dart`
- `lib/screens/donor_dashboard/donation_history_screen.dart`
- `lib/screens/donor_dashboard/blood_compatibility_screen.dart`
- `lib/screens/donor_dashboard/rewards_screen.dart`
- `lib/screens/donor_dashboard/emergency_alerts_tab.dart`
- `lib/screens/donor_dashboard/nearby_users_req.dart`
- `lib/screens/donor_dashboard/see_users_request.dart`
- `lib/screens/donor_dashboard/donors_list.dart`
- `lib/screens/donor_dashboard/donors_details.dart`
- `lib/screens/donor_dashboard/profile_sections/basic_info_screen.dart`
- `lib/screens/donor_dashboard/profile_sections/medical_history_screen.dart`
- `lib/screens/donor_dashboard/profile_sections/health_info_screen.dart`
- `lib/screens/donor_dashboard/profile_sections/emergency_contact_screen.dart`

Recipient / request flow:

- `lib/screens/requests/create_request_screen.dart`
- `lib/screens/requests/requests_list_screen.dart`
- `lib/screens/requests/providers/staged_notification_provider.dart`
- `lib/screens/requests/widgets/staged_cooldown_banner.dart`
- `lib/screens/donors/request_response_screen.dart`
- `lib/screens/donors/nearby_donors_screen.dart`
- `lib/screens/donors/donor_detail_screen.dart`
- `lib/screens/donors/donors_list_screen.dart`

Settings and profile:

- `lib/screens/settings/userside_settings_screen.dart`
- `lib/screens/settings/developer_profile_screen.dart`
- `lib/screens/profile/user_profile_screen.dart`
- `lib/screens/profile/controllers/profile_controller.dart`
- `lib/screens/profile/widgets/edit_profile_sheet.dart`
- `lib/screens/profile/widgets/profile_header.dart`
- `lib/screens/profile/widgets/profile_info_section.dart`
- `lib/screens/profile/widgets/profile_stats.dart`

Hospital dashboard epic:

- `lib/screens/hospital/hospital_dashboard.dart`
- `lib/screens/hospital/controllers/hospital_requests_controller.dart`
- `lib/screens/hospital/controllers/hospital_profile_controller.dart`
- `lib/screens/hospital/controllers/scanner_controller.dart`
- `lib/screens/hospital/dashboard/hospital_stats_bar.dart`
- `lib/screens/hospital/history/donation_history_tab.dart`
- `lib/screens/hospital/profile/hospital_profile_tab.dart`
- `lib/screens/hospital/requests/requests_tab.dart`
- `lib/screens/hospital/requests/request_card.dart`
- `lib/screens/hospital/requests/request_detail_sheet.dart`
- `lib/screens/hospital/requests/manual_fulfill_dialog.dart`
- `lib/screens/hospital/scanner/scanner_screen.dart`
- `lib/screens/hospital/scanner/blood_group_verification_screen.dart`

Admin / SuperAdmin epic:

- `lib/screens/admin/admin_dashboard.dart`
- `lib/screens/admin/controllers/admin_general_controller.dart`
- `lib/screens/admin/overview/admin_overview_view.dart`
- `lib/screens/admin/requests/blood_requests_admin_view.dart`
- `lib/screens/admin/donors/donor_manager_view.dart`
- `lib/screens/admin/hospitals/hospital_manager_view.dart`
- `lib/screens/admin/hospital_admins/hospital_admin_view.dart`
- `lib/screens/admin/hospital_admins/hospital_admin_controller.dart`
- `lib/screens/admin/cities/city_manager_view.dart`
- `lib/screens/admin/sponsors/sponsor_manager_view.dart`
- `lib/screens/admin/sponsors/sponsor_controller.dart`
- `lib/screens/admin/broadcast/broadcast_view.dart`
- `lib/screens/admin/broadcast/broadcast_controller.dart`

Sponsor / rewards epic:

- `lib/screens/sponsor/sponsor_dashboard.dart`
- `lib/screens/sponsor/manage_reward_screen.dart`
- `lib/screens/sponsor/scan_redeem_screen.dart`
- `lib/providers/points/points_provider.dart`
- `lib/services/points_service.dart`
- `lib/repositories/firebase/firebase_reward_repository.dart`

Notifications inbox:

- `lib/screens/misc/notifications_screen.dart`
- `lib/widgets/notification_badge.dart`
- `lib/core/models/app_notification.dart`
- `lib/services/notification_service.dart`
- `lib/events/notification_engine.dart`

Offline / connectivity support:

- `lib/providers/connectivity/connectivity_provider.dart`
- `lib/widgets/offline_banner.dart`
- `lib/services/pending_actions_service.dart`

## 4. Notes for Later Deep Dives

Recommended next documentation passes:

1. Firestore data model and collection map.
2. Request lifecycle: create, verify, notify, respond, fulfill, close.
3. Notification architecture: `AppEvent` -> `NotificationEngine` -> `NotificationService` / `StagedNotificationService`.
4. State management map: global providers vs feature-scoped providers/controllers.
5. UI/business coupling audit for donor dashboard, settings, requests, sponsor, and notification inbox screens.
6. Graduation-thesis architecture narrative: describe the current hybrid reality honestly, then explain which layers are intentional and which are legacy/transitional.
