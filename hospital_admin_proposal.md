# Hospital Admin Role — Development Proposal
**Project:** Sheryan (شريان) — Blood Donation Platform  
**Date:** May 2026  
**Scope:** Written plan only — no code changes in this document

---

## 1. Current State

The Hospital Admin dashboard (`lib/screens/hospital/hospital_dashboard.dart`) currently offers three actions:

| Action | Description |
|---|---|
| **Verify Request** | Scan a blood request QR code to mark it as `isVerified: true` and broadcast to compatible donors |
| **Register Donation** | Two-step QR scan (donor → request) to complete a donation, update request status to `done`, create a `donations` record, and award points |
| **Verify Donor Blood Group** | Scan a donor QR to stamp `bloodGroupVerified: true` on their profile and award milestone points |

Below the action buttons, the admin sees a **live list of incoming blood requests** for their hospital, filtered by `hospitalId`, sorted newest first, with status icons (pending / verified / done).

### Gaps in the Current Role

1. **No statistics or summary** — the admin has no at-a-glance numbers (total requests, pending count, donations this month).
2. **No donation history** — there is no way to review past donations processed at this hospital.
3. **No request detail view** — tapping a request card does nothing; the admin cannot see patient details, requester contact, or urgency level.
4. **No manual status management** — if a QR scan fails (damaged QR, offline device, etc.), there is no fallback to update a request status manually.
5. **No donor search / lookup** — the admin cannot search for a donor by name or blood group without scanning a QR code.
6. **No blood inventory tracking** — there is no way to record available blood units at the hospital.
7. **No in-app notifications panel** — incoming urgent requests are pushed via FCM, but the admin has no in-app notification history.
8. **Profile incomplete** — the admin's own profile (hospital name, contact) is not editable from within the dashboard.
9. **No analytics / reporting** — no charts for donation trends, busiest request periods, or blood group distribution.
10. **Scanner is mobile-only** — `MobileScanner` relies on a physical camera; it does not degrade gracefully on the web build, leaving hospital staff who use a desktop browser without a fallback.

---

## 2. Proposed Improvements

### Phase 1 — Core Usability (High Priority)

#### 2.1 Statistics Bar
Add a horizontal row of stat cards at the top of the dashboard, similar to the SuperAdmin overview:
- **Total Requests** — all `blood_requests` where `hospitalId == myHospitalId`
- **Pending** — status is `pending`
- **Verified** — status is `verified`
- **Fulfilled** — status is `done` or `completed`

All counts should be live (`StreamBuilder` / Firestore count aggregation).

#### 2.2 Request Detail Sheet
Make each request card tappable. Tapping opens a bottom sheet (or dialog) showing:
- Patient name, blood group, units required, urgency flag
- Requester contact information (phone number if provided)
- Request date and city
- Current status with a timeline (Pending → Verified → Done)
- Quick-action buttons: **Verify** (if still pending), **Mark Done** (if verified), **Delete** (superAdmin only — out of scope here)

This eliminates the need to scan a QR just to see details.

#### 2.3 Manual Status Override (Fallback for Failed Scans)
Add a confirmation-guarded button inside the request detail sheet:
- **"Mark as Verified"** — updates `isVerified: true` and broadcasts to donors, same as the QR scan flow.
- **"Mark as Fulfilled"** — updates `status: done`, prompts for donor ID (text field), creates a `donations` record, and triggers point awards.

This covers cases where the QR code is damaged, the donor forgot their QR, or the device camera is unavailable.

#### 2.4 Donation History Tab
Add a second tab or a scrollable section titled "Donation History" that lists all `donations` documents where `hospitalId == myHospitalId`, ordered newest first. Each row shows:
- Donor name (fetched by `donorId`)
- Linked request (blood group, patient name)
- Date and time
- Points awarded

---

### Phase 2 — Discovery & Management (Medium Priority)

#### 2.5 Donor Search / Lookup
Add a search screen (accessible from a floating action button or top-bar icon) that lets the admin:
- Search donors by name or blood group
- Filter by city (defaulting to the hospital's city)
- Tap a result to view the donor's profile card (name, blood group, verification status, last donation date)

This is useful when the admin needs to contact a compatible donor directly without waiting for a QR scan.

#### 2.6 Notifications Panel
Show a badge on the dashboard app bar for unread announcements. A bell icon opens a panel listing the 20 most recent `announcements` documents along with any system notifications (request verified, donation success) addressed to this admin's `uid`. Mark items as read in Firestore (`readBy` array or a separate `adminNotifications` sub-collection).

#### 2.7 Hospital Profile Editing
Allow the admin to view and edit their hospital's own Firestore document fields:
- Hospital name (read-only suggestion, edit requires SuperAdmin approval workflow)
- Contact phone number
- Address / landmark

Changes to name should create a `pendingEdits` document for SuperAdmin review rather than writing directly, to prevent accidental or unauthorised renames.

---

### Phase 3 — Analytics & Advanced Features (Lower Priority)

#### 2.8 Analytics Dashboard
A dedicated analytics tab showing:
- **Monthly donation trend** — bar chart (last 6 months)
- **Blood group distribution** of fulfilled requests — pie / donut chart
- **Average time to fulfillment** — from request creation to `status: done`
- **Peak request hours** — useful for staffing

Recommended library: `fl_chart` (already a common Flutter charting package).

#### 2.9 Blood Inventory Tracking
A simple in-app inventory screen where the admin can log available units per blood group. Each entry records:
- Blood group (`A+`, `B−`, etc.)
- Units available (integer)
- Last updated timestamp

Stored in a `bloodInventory` sub-collection under the hospital's Firestore document. Donors searching for nearby donation opportunities can optionally surface hospitals with matching blood group needs.

#### 2.10 Web-Compatible QR Fallback
Since `MobileScanner` requires a physical camera and may not work reliably in the Flutter web build:
- Detect the platform at runtime (`kIsWeb`).
- On web, replace the scanner UI with a **manual ID entry** text field — the admin types or pastes the donor / request ID.
- This ensures full functionality on desktop browsers used by hospital staff.

---

## 3. Firestore Schema Changes Required

| Collection / Document | Change |
|---|---|
| `donations` | No change — already contains `hospitalId`, `donorId`, `requestId`, `timestamp` |
| `hospitals/{id}` | Add optional fields: `phone`, `address`, `city` (city already stored) |
| `hospitals/{id}/bloodInventory/{bloodGroup}` | New sub-collection: `{ units: int, updatedAt: Timestamp }` |
| `adminNotifications/{uid}/items/{id}` | New sub-collection for per-admin notification inbox |
| `blood_requests` | Add `pendingManualOverride: bool` flag for audit trail when manual override is used |

---

## 4. Security Rules Considerations

- Hospital admins must only read/write `blood_requests` and `donations` where `hospitalId == resource.data.hospitalId` (already enforced in the current QR flow; manual override must apply the same check).
- `bloodInventory` writes must be restricted to the admin whose `hospitalId` matches the hospital document.
- `hospitals/{id}` name edits must be blocked for `hospitalAdmin` role at the rules level; only `superAdmin` may write to `name`.

---

## 5. Suggested Implementation Order

```
Phase 1.1  Statistics bar            ~1 day
Phase 1.2  Request detail sheet      ~1 day
Phase 1.3  Manual status override    ~1 day   (depends on 1.2)
Phase 1.4  Donation history tab      ~1 day
Phase 2.5  Donor search              ~1 day
Phase 2.6  Notifications panel       ~2 days
Phase 2.7  Hospital profile editing  ~1 day
Phase 3.8  Analytics dashboard       ~2 days
Phase 3.9  Blood inventory           ~2 days
Phase 3.10 Web QR fallback           ~0.5 day
```

Total estimated effort: **~13.5 development days** across three phases.

---

## 6. Summary

The Hospital Admin role is currently functional but minimal — it covers the essential scan-to-verify and scan-to-donate flows. The most impactful short-term improvements are a **statistics bar**, **tappable request detail sheet**, and a **manual status override fallback**, which together make the role fully operable without a working camera. Medium-term, a **donation history view** and **donor search** significantly improve the admin's operational efficiency. Long-term, analytics and blood inventory tracking position Sheryan as a complete hospital-facing platform rather than a simple scan tool.
