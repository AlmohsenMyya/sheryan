# Auth Flow Bug Fixes

## Problems Found & Fixed

### Bug 1 — Cache key not UID-specific (CRITICAL)
**File:** `lib/screens/home/home_screen.dart`, `lib/screens/donor_dashboard/donors_profile.dart`

**Problem:** SharedPreferences used a single global key `sheryan_user_cache` for all users.
If User A (donor) logged in, then logged out, then User B (hospitalAdmin) logged in and
Firestore failed for any reason, User B would see User A's data — including the wrong role.

**Fix:** Cache keys now include the UID:
- `sheryan_user_cache_{uid}` in `home_screen.dart`
- `sheryan_donor_profile_cache_{uid}` in `donors_profile.dart`

---

### Bug 2 — `build()` showed wrong dashboard before data loaded (CRITICAL)
**File:** `lib/screens/home/home_screen.dart`

**Problem:** The `build()` method derived the role from `roleProvider` (starts as `null`)
and `userData` (starts as `null`). When both were null, it defaulted to `UserRole.recipient`.
A hospitalAdmin or superAdmin would see the recipient dashboard momentarily — or permanently
if `_loadUser()` failed — before the correct role was resolved.

**Fix:** `build()` now returns a full-screen `CircularProgressIndicator` Scaffold while
`loading == true`. Role is only read from `roleProvider` AFTER `_loadUser()` completes,
which guarantees it's always correctly set.

---

### Bug 3 — Two HomeScreen instances during sign-up (CRITICAL)
**File:** `lib/screens/auth/sign_up_screen.dart`

**Problem:** `createUserWithEmailAndPassword` triggers `authStateChanges`, which caused
`StartupRouter` (still in the nav stack) to mount a HomeScreen (H1) before `registerUser()`
had finished writing the Firestore document. H1's `_loadUser()` raced with the Firestore
write and could read a non-existent document. Using `Navigator.pushReplacement` left
StartupRouter and H1 alive in the background.

**Fix:** Changed to `Navigator.pushAndRemoveUntil(..., (route) => false)` to clear the
entire navigation stack. Only one HomeScreen (H2) exists after sign-up, and it only
starts after `registerUser()` has fully completed (document written).

---

### Bug 4 — Connectivity check gated Firestore unnecessarily (IMPORTANT)
**Files:** `home_screen.dart`, `donors_profile.dart`, `donors_list.dart`

**Problem:** `_loadUser()`, `_loadProfile()`, and `_loadDonors()` all read
`connectivityProvider` to decide whether to fetch from Firestore or use cache.
If the connectivity provider reported the wrong state (e.g., briefly `false` due to
the async init race), Firestore was skipped even when online, showing stale/empty data.

**Fix:** Removed the connectivity check entirely. Firestore with `persistenceEnabled: true`
handles online/offline automatically — it returns cached data when offline and fetches
from the server when online. Errors are caught and SharedPreferences cache is used
as the final fallback.

---

### Bug 5 — Missing `mounted` checks after async gaps (IMPORTANT)
**Files:** `home_screen.dart`, `donors_profile.dart`, `donors_list.dart`

**Problem:** Async functions called `setState` and `ref.read(roleProvider.notifier)`
without checking `if (!mounted)` after every `await`. This caused:
- setState on disposed widgets (Flutter warning / potential crash)
- roleProvider being set by a widget that's already been removed from the tree

**Fix:** Added `if (!mounted) return;` after every `await` in all data-loading functions.

---

### Bug 6 — Role set AFTER `loading = false` (IMPORTANT)
**File:** `lib/screens/home/home_screen.dart`

**Problem:** In the original code, `setState(() => loading = false)` could be called
before `setRoleFromString()` in some code paths, causing a build cycle where loading=false
but role still wasn't set.

**Fix:** `setRoleFromString()` is now always called BEFORE `setState(() => loading = false)`.
The `build()` method only reads `roleProvider` after `loading = false`, so role is
guaranteed to be correct on first render.

---

## Files Modified
- `lib/screens/home/home_screen.dart`
- `lib/screens/auth/sign_up_screen.dart`
- `lib/screens/donor_dashboard/donors_profile.dart`
- `lib/screens/donor_dashboard/donors_list.dart`
