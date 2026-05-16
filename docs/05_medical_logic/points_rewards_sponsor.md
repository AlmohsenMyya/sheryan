# Points, Rewards & Sponsor Organization System

## Overview
A complete gamification layer added to Sheryan that rewards donors for completing their profile and donating blood. Sponsors create redeemable rewards that donors can browse and claim via QR scanning.

---

## Points System

### Earning Events
| Event | Points |
|---|---|
| Account created | +20 |
| Basic info complete | +30 |
| Health info complete | +30 |
| Medical history complete | +20 |
| Emergency contact complete | +20 |
| Blood group verified | +100 |
| Profile 100% bonus | +50 |
| Donation registered | +200 |
| Consecutive donation bonus | +50 |

### Tier Levels
| Tier | Points Range |
|---|---|
| Bronze 🥉 | 0 – 499 |
| Silver 🥈 | 500 – 999 |
| Gold 🥇 | 1000 – 1999 |
| Platinum 💎 | 2000+ |

---

## Firestore Collections

### `rewards/{id}`
```
sponsorId, sponsorName, city, title, description,
sponsorPhone, sponsorAddress, pointsRequired,
isActive, createdAt, updatedAt
```

### `redemptions/{id}`
```
donorId, sponsorId, rewardId, rewardTitle,
pointsDeducted, redeemedAt
```

### `users/{uid}/pointsHistory/{id}`
```
event, points, descriptionAr, descriptionEn, total, createdAt
```

---

## Roles

### `sponsorOrg`
- Created **only** by superAdmin via Admin Dashboard → Sponsors tab
- Has access to `SponsorDashboard` screen
- Can add/edit/delete rewards
- Can scan donor QR codes to redeem rewards (deducts points from donor)

---

## Key Files

| File | Purpose |
|---|---|
| `lib/services/points_service.dart` | Core logic: award, deduct, tier, milestone checks |
| `lib/providers/points/points_provider.dart` | Riverpod streams: points, history, rewards |
| `lib/screens/donor_dashboard/rewards_screen.dart` | Donor views rewards + points history |
| `lib/screens/sponsor/sponsor_dashboard.dart` | Sponsor manages rewards, views stats |
| `lib/screens/sponsor/manage_reward_screen.dart` | Add/edit a reward |
| `lib/screens/sponsor/scan_redeem_screen.dart` | Scan donor QR and deduct points |
| `lib/screens/donor_dashboard/profile_sections/basic_info_screen.dart` | Edit name/phone/city/DOB/blood group |

---

## UX Flow

### Donor
1. Opens profile → sees points card with tier badge
2. Taps points card → `RewardsScreen` with 2 tabs
3. **Tab 1 — Available Rewards**: filter by city, see reward cards, tap "Show QR" to present QR to sponsor
4. **Tab 2 — Points History**: list of all earned events

### Sponsor
1. Logs in → automatically routed to `SponsorDashboard`
2. Adds rewards with title, description, points required, city, phone, address
3. Opens a reward → taps "Scan QR" → camera scans donor's QR
4. System checks points, deducts if sufficient, records redemption

### SuperAdmin
1. Admin Dashboard → 4th tab "Sponsor Organizations"
2. Creates sponsor accounts (name, email, password, phone, city)
3. Can delete sponsor accounts
