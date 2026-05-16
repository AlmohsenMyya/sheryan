# Arabic + English Localization Plan (Professional Structure)

## Current state (quick audit)
- The app currently has **hard-coded English UI strings** across screens.
- `MaterialApp` in `lib/main.dart` does not define `locale`, `supportedLocales`, or localization delegates.
- Riverpod is already used, so locale state can be integrated cleanly with a dedicated provider.
- The project already depends on `intl`, but Flutter localization tooling/delegates are not configured yet.

## Recommended architecture

### 1) Use Flutter gen-l10n (official)
Adopt Flutter's built-in localization generation (`flutter gen-l10n`) using ARB files:
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ar.arb`

This gives type-safe translation keys (`AppLocalizations.of(context)!.loginTitle`) and avoids string duplication.

### 2) Add a dedicated locale state provider (Riverpod)
Create `lib/providers/locale/locale_provider.dart`:
- Holds selected locale (`Locale('en')` / `Locale('ar')`).
- Exposes `setLocale(Locale)`, `toggleLocale()`, and optional persistence hooks.

This keeps language switching globally managed, not screen-local.

### 3) Persist language in SharedPreferences
On app startup:
- read language code from `SharedPreferences`
- initialize locale provider from saved value

When user changes language:
- update provider state
- save choice immediately

### 4) Wire localization in `MaterialApp`
In `lib/main.dart`:
- `locale: ref.watch(localeProvider)`
- `supportedLocales: AppLocalizations.supportedLocales`
- `localizationsDelegates: AppLocalizations.localizationsDelegates`

### 5) Replace hardcoded strings gradually
Start from shared/high-traffic screens:
1. `auth/*`
2. `home/*`
3. `requests/*`
4. `settings/*`

Use key naming convention:
- `auth.loginTitle`
- `auth.loginSubtitle`
- `home.settings`
- `request.submitSuccess`

### 6) Add a simple professional language switch button
Best UX options:
- Settings item: "Language / اللغة" with bottom sheet selector.
- Quick app-bar icon (`Icons.language`) on major screens.

For a simple start: add app-bar language icon that opens a sheet with:
- English
- العربية

### 7) RTL support for Arabic
Flutter handles many RTL behaviors automatically when locale is `ar`, but verify:
- paddings/margins in custom cards
- icon direction for navigation arrows
- text alignments in critical forms

### 8) Date/time/message formatting
Use `intl` and locale-aware formatting for:
- request dates
- confirmation messages

## Implementation options (choose one)

### Option A — Quick + clean (recommended now)
- Add localization infra + locale provider + persisted switch.
- Translate only core screens first (Auth + Home + Settings).
- Keep fallback English for untranslated screens.

Pros: fast rollout, low risk.
Cons: mixed language until full migration.

### Option B — Full migration before release
- Translate all screens and snackbars in one pass.
- Add key coverage checklist and review.

Pros: consistent UX.
Cons: larger change set, longer QA.

### Option C — Domain-first migration
- Translate by feature module (auth, donor flow, recipient flow).
- Release per module.

Pros: structured and measurable.
Cons: requires release coordination.

## Suggested minimum task breakdown
1. Enable gen-l10n and delegates.
2. Add `localeProvider` + persistence service.
3. Add language picker UI (single reusable widget).
4. Migrate 30-40 high-impact strings.
5. QA for AR/EN + RTL on Android/iOS.

## QA checklist
- Language persists after app restart.
- Arabic layout is RTL in app bars/forms/lists.
- No untranslated key names appear in UI.
- SnackBars/dialogs switch language correctly.
- Date format respects locale.

## Notes for this repository
Given the current codebase structure, localization should be introduced as **cross-cutting infrastructure** (provider + l10n files + MaterialApp wiring), then applied screen-by-screen.
This aligns well with your existing Riverpod usage and avoids large risky refactors.
