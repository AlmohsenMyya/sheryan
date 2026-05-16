# Comprehensive Project Summary — Sheryan (شريان)

> **Goal:** This document serves as the primary source of truth for the AI assistant and developers, preserving context regarding the project architecture, features, and implementation history.

---

## 1. Project Identity
**Sheryan (شريان — "Artery")** is a community-driven blood donation platform connecting donors, recipients, and hospitals. It aims to reduce the time to find compatible donors through real-time notifications and incentivizes donation through a gamified points system.

---

## 2. Technical Stack
- **Frontend:** Flutter 3.x (Web & Mobile ready).
- **State Management:** Riverpod 3 (StreamProviders, StateNotifiers).
- **Backend:** Firebase (Authentication, Firestore, Cloud Messaging v1).
- **Localization:** Official Flutter `gen-l10n` (ARB files), defaulting to **Arabic**.
- **Theming:** Dual-theme system (Light/Dark) with persisted state via `SharedPreferences`.
- **Branding:** 
  - `assets/logo.png`: Main app logo (transparent).
  - `assets/logo-splash.jpg`: High-quality splash image (white background).

---

## 3. Architecture & Patterns
The project follows a **Decoupled Layered Architecture**:

1.  **Presentation Layer (`lib/screens/`, `lib/widgets/`):** Material 3 UI components.
2.  **Provider Layer (`lib/providers/`):** Reactively bridges data to UI.
3.  **Service Layer (`lib/services/`):** Contains business logic (e.g., `PointsService`, `NotificationService`).
4.  **Repository Layer (`lib/repositories/`):** Abstract interfaces (`interfaces/`) and concrete implementations (`firebase/`). This allows for easy backend swaps (e.g., migrating from Firebase to a REST API).
5.  **Event-Driven Notifications:** Uses an `AppEvent` sealed hierarchy and a `NotificationEngine` to centralize notification logic.

---

## 4. Key Systems

### 4.1 Advanced Notification System
- **Engine:** `NotificationService` handles direct FCM v1 HTTP API calls using OAuth2.
- **Inbox:** Every notification is persisted in `users/{uid}/notifications` for offline access.
- **Event Flow:** Screens dispatch `AppEvent` -> `NotificationEngine` translates to UI strings -> `NotificationService` executes Push + Inbox write.
- **Targeting:** Direct per-user targeting (not topic-based) for high reliability and blood-group compatibility filtering.

### 4.2 Gamification & Tiers
- **Points Logic:** Awarded for profile milestones (signup, health data, verification) and successful donations.
- **Tiers:** Bronze, Silver, Gold, Platinum based on cumulative points.
- **Redemption:** Sponsor organizations can scan donor QR codes to deduct points and grant real-world rewards.

### 4.3 Offline Support & Resilience
- **Firestore Cache:** Enabled via `persistenceEnabled: true` for seamless reading while offline.
- **Pending Actions:** `PendingActionsService` queues blood requests created while offline in `SharedPreferences` and auto-syncs them on reconnect.
- **Connectivity:** `connectivityProvider` tracks real-time network status and triggers sync/UI banners.

### 4.4 Profile Completion
- **Logic:** Weighted percentage (Basic: 20%, Health: 20%, Medical: 15%, Emergency: 10%, Hospital Verification: 35%).
- **Verification:** Requires a physical hospital visit where an admin scans the donor's QR code.

---

## 5. Workflows & Roles
- **Donor:** Browses requests, tracks history, earns points, manages health profile.
- **Recipient:** Creates/tracks blood requests, contacts donors via WhatsApp.
- **Hospital Admin:** Verifies requests, registers donations (QR or Manual), verifies donor blood groups.
- **Super Admin:** Global CRUD on hospitals, cities, admins, and sends broadcast announcements.
- **Sponsor Org:** Manages rewards and handles point redemptions via scanning.

---

## 6. Implementation History (Recent Tasks)

### A. Auth Flow & Stability Fixes
- **UID-Specific Caching:** Fixed a critical bug where `SharedPreferences` cache wasn't user-specific, leading to role-leaks between logouts.
- **Race Condition Handling:** Fixed a bug where `HomeScreen` would mount before Firestore profile creation during signup.
- **Connectivity Gating:** Removed redundant connectivity checks that were blocking Firestore's built-in offline persistence.

### B. Hospital Admin Phase 1
- **Dashboard Upgrade:** Added a Stats Bar with real-time counters.
- **Request Management:** Implemented a Draggable Detail Sheet for requests.
- **Manual Override:** Enabled admins to verify/fulfill requests manually when QR codes are unavailable.
- **Donation History:** Added a dedicated tab for hospital-specific donation logs.

### C. Branding & UI Refresh
- **Branding Assets:** Integrated `logo.png` and `logo-splash.jpg`.
- **Splash Screen:** Configured `flutter_native_splash` for a seamless boot and updated the in-app `SplashScreen` flow.
- **App Icons:** Configured `flutter_launcher_icons` using the new logo.
- **HomeScreen Redesign:** Completely overhauled the `HomeScreen` UI with a Hero gradient header, action grids, and a modern card-based layout.
- **Global Logo Usage:** Added the logo to the AppBar, Profile header, and Auth screens.

### D. Multi-Filter Broadcast Notifications
- **Issue:** SuperAdmin could only filter by *either* City or Blood Group, not both.
- **Fix:** Updated `NotificationService.sendEmergencyNotification` to support cumulative filters (Role + City + BloodGroup).
- **Bilingual Support:** Updated `AnnouncementService` and `AdminBroadcastEvent` to support separate Arabic and English title/body fields.
- **UI Upgrade:** Updated the SuperAdmin broadcast form to allow multi-filter selection and provide bilingual input fields.

---

## 7. Current Project State
- **Stability:** High. Critical auth and data race conditions are resolved.
- **Visuals:** Modern and branded.
- **Logic:** Fully event-driven and repository-pattern compliant.
- **Next Steps (Roadmap):**
  - Donor search by name/phone in Hospital Dashboard.
  - Analytics and charts for Super Admin.
  - Blood inventory tracking per hospital.
  - Native iOS/Android build optimization.

---
*Documentation updated: May 2024*
