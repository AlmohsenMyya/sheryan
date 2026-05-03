# Sheryan (شريان) - Technical Project Documentation (V2)

## 1. Overview
**Sheryan** is a comprehensive blood donation ecosystem designed to bridge the gap between donors, recipients, and hospitals. It leverages modern mobile technologies and cloud infrastructure to ensure fast, reliable, and secure blood request fulfillment.

---

## 2. Architecture & Design Patterns
The project follows a **Layered Architecture** with a strong focus on **Decoupling** and **Scalability**.

### 2.1. Layers
*   **Presentation Layer (Screens & UI):** Built with Flutter, utilizing Material 3 design principles.
*   **State Management (Providers):** Powered by `Riverpod` for high-performance, reactive state handling (Auth, Locale, Theme).
*   **Service Layer:** Mediates business logic. Services (e.g., `RequestService`, `DonationService`) act as a bridge between the UI and the data layer.
*   **Repository Pattern:** Data operations are abstracted into Interfaces (in `lib/repositories/interfaces`). This allows for switching backends (e.g., from Firebase to SQL) with zero changes to the service layer.

---

## 3. Core Modules & Logic

### 3.1. Advanced Notification System (Hybrid)
Following recent upgrades, Sheryan uses a robust hybrid notification model:
*   **Push Engine:** Firebase Cloud Messaging (FCM) V1 API using OAuth2 authentication.
*   **Security:** Sensitive credentials (Private Keys) are managed via a `.env` system, protected by `flutter_dotenv` and excluded from version control.
*   **Persistence (In-app Inbox):** Every notification is mirrored in Firestore (`users/{uid}/notifications`) to ensure users can view alerts even if they were offline during the push.
*   **Smart Targeting:** Uses FCM Topics (`city_...`, `blood_...`) for scalable broadcasting to compatible donors.
*   **Foreground Handling:** Integrated with `flutter_local_notifications` to ensure sound, vibration, and pop-up banners while the app is active.

### 3.2. Gamification & Points System
Designed to encourage frequent and urgent donations:
*   **Point Values:** Basic donation (200 pts), Emergency bonus (2x multiplier), Rarity bonus (+100 pts), and Streak bonus (+50 pts).
*   **User Tiers:** Bronze, Silver, Gold, Platinum based on cumulative points.
*   **Milestones:** Points are awarded for profile completion (Basic, Health, Medical, Emergency, and Hospital Verification).

### 3.3. Profile Completion Logic
Calculates user "trustworthiness" and data completeness:
*   **Basic Info:** 20%
*   **Health Profile:** 20%
*   **Medical History:** 15%
*   **Emergency Contact:** 10%
*   **Hospital Verification:** 35% (The most critical factor).

---

## 4. Workflows

### 4.1. Hospital Admin Workflow
1.  **Request Verification:** Admin scans a request QR code. The system marks it as `isVerified` and triggers the multi-cast notification.
2.  **Donation Registration:** Admin scans Donor QR then Request QR.
3.  **Atomic Updates:** Uses Firestore `WriteBatch` to update the request status, donor's last donation date, and create a donation record in a single transaction.

### 4.2. Donor & Recipient Interactions
*   **Smart Matching:** `BloodLogic` utility calculates compatible blood groups for both sending and receiving.
*   **Communication:** Integrated `WhatsAppHelper` for one-click structured messaging between parties.

---

## 5. Security & Configuration
*   **Environment Variables:** Managed in `.env` file (FCM_PROJECT_ID, FCM_PRIVATE_KEY, etc.).
*   **Git Integrity:** `.gitignore` configured to prevent leakage of secrets.
*   **API Standards:** Migrated to Google Projects V1 API for future-proof communication.

---

## 6. Technical Stack
*   **Framework:** Flutter (Latest Stable)
*   **Backend:** Firebase (Auth, Firestore, Messaging, Storage)
*   **Local Storage:** `shared_preferences`
*   **Utilities:** `geolocator`, `googleapis_auth`, `intl`, `mobile_scanner`.

---
*Documentation generated after full code audit on: May 2024*
