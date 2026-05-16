# Implementation History Log — Version 2.0 (May 2026)

> **Context:** This document captures the intensive refactoring and feature implementation phase. It bridges the gap between the original legacy code and the current clean, production-ready architecture.

---

## 1. Branding & Visual Identity Overhaul
We transitioned the app from generic icons to a consistent, professional brand identity.
- **Assets:** Integrated `assets/logo.png` (transparent) and `assets/logo-splash.jpg`.
- **Splash Screen:** Configured `flutter_native_splash` for a native-feel boot and updated the in-app `SplashScreen` to use the branded splash image and a cleaner loader.
- **App Icons:** Configured `flutter_launcher_icons` to generate consistent icons across Android and iOS using the primary logo.
- **Global Integration:** The logo was strategically placed in all major screens (Auth, Dashboards, Profile Headers).

---

## 2. Advanced Architectural Refactoring (HomeScreen)
The `HomeScreen` was refactored from a "God Object" into a clean, decoupled module.
- **Controller Pattern:** Introduced `HomeController` to manage side effects (notifications, auth, sync).
- **State Management:** 
    - Created `currentUserRoleProvider` for safe, single-point-of-truth role resolution.
    - Eliminated manual null-checks in favor of Riverpod's `AsyncValue.when`.
- **Componentization:** Extracted UI into reusable widgets in `lib/screens/home/widgets/` (`HomeAppBar`, `UserWelcomeHeader`, `ActionCard`, etc.).
- **Routing:** Replaced complex conditional blocks with a strategy-based `_buildRoleDashboard` delegator.

---

## 3. Recipient Profile & Statistics Revamp
The `ProfileScreen` for recipients was completely redesigned to match the high standards of the Donor dashboard.
- **Architecture:** Created `ProfileController` and extended `RequestRepository`/`RequestService` to include user-specific statistics (Total vs. Fulfilled requests).
- **UI Design:** 
    - **Dashboard Style:** Replaced a static form with an interactive dashboard.
    - **Stats Cards:** Added real-time tracking of personal blood request history.
    - **Sheet-based Editing:** Separated "View" and "Edit" modes. Editing now happens in a modern `ModalBottomSheet` (`EditProfileSheet`).
    - **Branded Header:** High-contrast blue gradient header with profile status and info tiles.

---

## 4. Feature: Nearby Blood Banks (Replacing Nearby Donors)
We deprecated the "Nearby Donors" search for regular users (due to null bloodGroup issues) and replaced it with a more practical "Nearby Hospitals/Blood Banks" feature.
- **Data Layer:** Enhanced `UserRepository` and `HospitalRepository` to support city-based filtering.
- **Providers:** Created `NearbyHospitalsProvider` using a reactive `selectedCityProvider` (defaults to user's home city).
- **UI:** 
    - Interactive screen with a city dropdown to browse hospitals in any area.
    - **HospitalCard:** Displays name, detailed address, and a direct "Call" button powered by `url_launcher`.
- **Integration:** Updated the Recipient Home Dashboard with the new "Nearby Blood Banks" entry point.

---

## 5. Hospital Admin: Profile & Information Management
Empowered hospital admins to manage their facility's public-facing information.
- **Hospital Profile Tab:** Added a dedicated settings tab in the `HospitalDashboard`.
- **Data Expansion:** Added support for `phone` (inquiry number) and `address` (full location details) in the `hospitals` collection.
- **Real-time Updates:** Admins can now update their hospital's contact details, which immediately reflects on the `NearbyHospitalsScreen` for all users.

---

## 6. UI/UX Modernization & Centralized Settings
Conducted a major cleanup to meet modern UX standards and reduce cognitive load.
- **AppBar Cleanup:** Removed Theme toggles, Language icons, and generic menus from all AppBars (Home, Profile, etc.).
- **Settings Hub:** Centralized all app logic into `userside_settings_screen.dart` organized by cards/sections:
    - **Account:** Password changes, account deletion, request reset.
    - **Preferences:** **Theme** toggle (Dark/Light) and **Language** selection moved here.
    - **Support & Danger Zone:** Grouped contact info and a prominent red **Logout** button at the bottom.
- **Dynamic UX:** The QR Button label in the Profile screen now dynamically switches between "Donor Card" and "My Card" based on the user's role.

---

## 7. Technical Improvements & Rules
- **Points Security:** Implemented "No point redemption before first donation" logic in services and UI.
- **Localization:** Added several keys to `app_ar.arb` and `app_en.arb` for the new UI, settings, and hospital profiles.
- **Architecture Integrity:** Strictly maintained the **Repository/Service/Controller/UI** pattern across all new features.

---

## 8. Summary for Future Agents
The project is highly modular. When adding features:
1.  **UI:** Use the `widgets/` folder relative to the screen for sub-components.
2.  **Logic:** Create a `controllers/` folder for UI logic; use Riverpod providers.
3.  **Data:** Always route via `Service` → `Repository`. Avoid direct Firestore calls in UI.
4.  **Branding:** Follow the blue gradient for recipients and red gradient for donors.

---

## 9. UX: Collapsible Profile Completion (Donor Dashboard)
Refactored the donor's profile completion tasks to reduce vertical clutter and improve navigation focus.
- **UI Refactoring:** Replaced the static list of 5 completion cards (Basic Info, Health, Medical History, etc.) with a borderless `ExpansionTile`.
- **UX Benefits:** 
    - The section is now collapsed by default, allowing donors to quickly access their points history, rewards, and donation history without excessive scrolling.
    - Maintains a cleaner interface while keeping high-priority tasks easily accessible upon expansion.
- **Modified Files:** `lib/screens/donor_dashboard/donors_profile.dart`.

---

## 10. Data Integrity: Profile Verification Guard & Point Rarity
Implemented a security layer to prevent "verification spoofing" and ensure fair point distribution during profile updates.
- **Verification Integrity:** 
    - Updated `BasicInfoScreen` to monitor blood group changes.
    - If a user attempts to change their blood group after it has been verified by a hospital, a **Warning Dialog** appears.
    - Confirming the change automatically resets the `bloodGroupVerified` flag to `false`, requiring a new hospital scan.
- **Point Economy:** 
    - Verified that `PointsService` prevents duplicate milestone rewards. Points for completing profile sections are awarded only once per account lifetime by tracking permanent event logs in `pointsHistory`.
- **UI Enhancements:** Added a "Verified" badge next to the blood group label in the edit screen to highlight its sensitive status.
- **Modified Files:** `lib/screens/donor_dashboard/profile_sections/basic_info_screen.dart`.

---

## 11. Feature: General & Periodic Donation Registration
Extended the hospital dashboard to support non-request-based donations, facilitating blood bank inventory growth.
- **Data Layer:** 
    - Added `registerGeneralDonationBatch` to `DonationRepository` to atomically update donor's `lastDonated` and create a `general` type donation record.
    - Updated `DonationService` to manage general donation flows.
- **Point System:** Introduced `general_donation` event awarding **150 points** to encourage voluntary periodic donations.
- **UI/UX Refactoring:** 
    - Reorganized `HospitalDashboard` actions into a **2x2 Grid** for better accessibility.
    - Added "General/Periodic Donation" action button.
    - Enhanced `ScannerScreen` to be context-aware, supporting single-scan flows for general donations with a confirmation dialog.
    - Improved `DonationHistoryTab` to distinguish between request-based and general blood bank donations.
- **Bug Fix:** Fixed an issue where the `ScannerScreen` title and logic incorrectly expected a second scan (Request QR) during general donation registrations.
- **Modified Files:** `donation_service.dart`, `donation_repository.dart`, `hospital_dashboard.dart`, `points_service.dart`, and localization files.

---

## 12. Major Architectural Refactoring & UX Standardization
Conducted a full-scale refactor of the `HospitalDashboard` and standardized the global settings/navigation flow across all roles.
- **Architectural Decoupling (SRP):**
    - Broken the 850+ line `hospital_dashboard.dart` God Object into a modular folder structure (`/controllers`, `/requests`, `/history`, `/profile`, `/scanner`, `/widgets`).
    - Extracted business logic and async state management into dedicated Riverpod Notifiers (e.g., `ScannerController`, `HospitalRequestsController`).
    - Unified scanner logic to handle multiple scan contexts (Request, General Donation, Blood Group Verification) using a centralized state machine.
- **UX Consistency & Centralized Settings:**
    - Integrated the centralized `SettingsScreen` for the **Hospital Admin** role by adding a gear icon to their main AppBar.
    - Updated `SettingsScreen` to be **role-aware**, dynamically hiding recipient-only actions (like "Reset Requests") when accessed by admins or donors.
    - Standardized AppBars across all roles (Home, Donor, Recipient, Hospital Admin) to only show relevant action points (Notifications & Settings).
- **Componentization:**
    - Extracted `NotificationBadge` into a shared widget for consistent unread-count tracking.
    - Modularized hospital statistics, request cards, and detail sheets for better maintainability.
- **Technical Improvements:**
    - Eliminated "Double AppBar" issues for Admin roles by allowing their dashboards to manage their own root Scaffolds.
    - Maintained full offline resilience by integrating the `OfflineBanner` into the new modular dashboards.

---

## 13. UX Standardization: Sponsor Dashboard & Centralized Settings
Completed the global UX standardization by integrating the centralized settings flow for the **Sponsor Organization** role.
- **Settings Integration:** Added the gear icon (`Icons.settings_outlined`) and `NotificationBadge` to the `SponsorDashboard` AppBar.
- **Consistent Flow:** Sponsors can now access Theme toggles, Language selection, and Logout actions through the same centralized hub as other users.
- **Clean UI:** Removed redundant "Add Reward" buttons from the AppBar to reduce clutter, relying on the existing prominent buttons within the dashboard body.
- **Refined Permissions:** Ensured the `SettingsScreen` remains role-aware, hiding recipient-specific debug tools from Sponsor accounts.
- **Modified Files:** `lib/screens/sponsor/sponsor_dashboard.dart`.

---

## 14. Architecture: Modularization of Super Admin Dashboard
Transformed the monolithic `AdminDashboard` into a decoupled, feature-first structure to improve maintainability and strictly follow SRP.
- **Directory Restructuring:** Organized the dashboard into sub-features: `/overview`, `/hospital_admins`, `/hospitals`, `/cities`, `/sponsors`, `/donors`, `/requests`, and `/broadcast`.
- **State Management (Riverpod):** 
    - Extracted all asynchronous business logic into dedicated controllers (Notifiers).
    - Eliminated `setState` for loading indicators in favor of reactive state observers.
    - Features like `Broadcast`, `HospitalAdmin`, `Sponsor`, and `General Admin` (Cities/Hospitals) now have centralized logic.
- **Massive Dialog Componentization:** Refactored complex forms (e.g., creating hospital admins or sponsors) into standalone dialog widgets.
- **Unified Widgets:** Extracted shared admin UI elements (Sidebar, SectionHeader, StatusBadge, etc.) for project-wide consistency.
- **Technical Benefits:** Dramatically reduced the file size of the main `admin_dashboard.dart` shell and improved code readability and testability.

---

## 15. Feature: Staged Notification Ecosystem & Donor UX Optimization
Implemented a highly reliable, multi-batch emergency notification engine and optimized the donor navigation experience.
- **Smart Staged Dispatch:** Replaced global broadcasts with a server-side validated cooldown loop (30 min) targeting 10 compatible donors at a time.
- **Data-Only Routing (Phase A):** Eliminated "OS Hijack" by switching to pure FCM Data payloads, ensuring 100% routing accuracy via a custom `navigatorKey` handler.
- **Emergency State Shield (Phase B):** Refactored the Donor's Bottom Navigation Bar to replace "All Donors" with a reactive "Emergency Alerts" tab driven by a `lastEmergencyRequestIdProvider`.
- **In-App Action Bridge (Phase C):** Injected contextual "View Details" buttons inside emergency notification cards.
- **UI Safety & Locking:** Implemented server-side state-aware locking in `RequestResponseScreen` for fulfilled or already declined requests.
- **UX Refinement:** Removed the redundant "All Donors" dashboard card and replaced it with a prominent "Available Rewards" entry point to enhance gamification engagement.

---
*Log updated: May 2026*
