# Firebase Console Checklist (Based on Current Code Usage)

This checklist is derived from actual Firebase usage in the app code.

## 1) Firebase services that are **required** now

### A. Authentication (Email/Password)
Enable in **Firebase Console → Authentication → Sign-in method**:
- Email/Password provider.

Why required:
- User sign-up with email/password.
- User login with email/password.
- Password reset email.
- Re-authentication before sensitive actions.
- Account deletion/sign-out.

---

### B. Cloud Firestore
Enable in **Firebase Console → Firestore Database** (production mode recommended + proper rules).

Collections used by the app:
- `users`
- `blood_requests`

Main operations used:
- `users/{uid}`: create profile at signup, read/update self profile, update FCM token at login, delete on account deletion.
- `blood_requests`: create, query by owner, query all, query pending, update request status, delete owner requests.

---

### C. Cloud Messaging (FCM)
Enable in **Firebase Console → Cloud Messaging**.

Why required:
- App reads FCM device token (`getToken`) on signup/login and stores it in `users.fcmToken`.

Notes:
- Receiving foreground/background push handling is not implemented yet in code.
- Android manifest already contains notification permission and a default notification channel metadata.

---

## 2) Firebase services currently **configured in dependencies but not used functionally**

### A. Cloud Storage
- Package is included and bucket exists in Firebase options, but no runtime upload/download calls are present.
- You can keep it disabled for now unless you plan profile images/files.

### B. Firebase Hosting / Cloud Functions
- `firebase.json` includes hosting/functions config, but mobile app code does not call Functions or hosting endpoints directly.

## 3) Firestore indexes to create

Create these **composite indexes** in Firestore Indexes:

1. Collection: `blood_requests`
   - Fields: `userId` (Ascending), `createdAt` (Descending)
   - Needed for: owner requests screen query (`where userId` + `orderBy createdAt desc`).

2. Collection: `blood_requests`
   - Fields: `status` (Ascending), `createdAt` (Descending)
   - Needed for: nearby/pending requests query (`where status` + `orderBy createdAt desc`).

(If missing, Firestore will throw an index error with a direct creation link.)

## 4) Suggested minimal Firestore security model

Because the app reads donor/request data across users, a practical first model is:

- `users/{uid}`
  - read: authenticated users (or stricter donor/public-field model later)
  - create/update/delete: only owner (`request.auth.uid == uid`)

- `blood_requests/{requestId}`
  - read: authenticated users
  - create: authenticated users with `request.resource.data.userId == request.auth.uid`
  - update/delete: only owner (`resource.data.userId == request.auth.uid`)

This matches current app flows and prevents one user from editing/deleting another user’s data.

## 5) Authentication console settings recommended

- Authorized domains: include your web domain(s) and localhost for development if testing web.
- Email templates: customize password reset template and sender details.
- (Optional) Enable email verification flow later if you want stronger account quality.

## 6) Platform/app registration checks after moving to a new Firebase project

Since the project was moved to a new Firebase backend, verify:

- Android app registered with package: `com.sheryan.app`.
- Correct `google-services.json` file is inside `android/app/`.
- iOS app registered with bundle ID: `com.example.bloodDonationAppFull` (or your final bundle id).
- Correct iOS `GoogleService-Info.plist` is added if building iOS.
- `lib/firebase_options.dart` and `firebase.json` point to the new project IDs/app IDs (not old project values).

## 7) Current schema fields used by code (for validation/rules)

### `users` document fields
- `uid`, `name`, `email`, `bloodGroup`, `city`, `role`, `phone`, `lastDonated`, `fcmToken`, `createdAt`, `lastLogin`.

### `blood_requests` document fields
- `userId`, `patientName`, `hospital`, `city`, `bloodGroup`, `units`, `phone`, `neededAt`, `createdAt`, `status`.

---

If you want, the next step can be: I generate ready-to-paste Firestore Security Rules + exact index JSON for `firebase deploy`.
