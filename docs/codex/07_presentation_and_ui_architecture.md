# Presentation Layer and UI Architecture

Phase 7 technical analysis of Sheryan's presentation layer, design system, reusable UI components, and internationalization architecture.

Target areas:

- `lib/core/theme/app_theme.dart`
- related theme files:
  - `lib/core/theme/app_colors.dart`
  - `lib/core/theme/app_design_constants.dart`
  - `lib/core/theme/app_typography.dart`
- `lib/l10n/`
- `lib/screens/home/widgets/action_card.dart`
- `lib/screens/hospital/requests/request_card.dart`

Note: the requested paths `lib/widgets/action_card.dart` and `lib/screens/hospital/widgets/request_card.dart` do not exist in the current repository. The actual implementations are `lib/screens/home/widgets/action_card.dart` and `lib/screens/hospital/requests/request_card.dart`.

## 1. Presentation Layer Overview

Sheryan's presentation layer is organized around three architectural ideas:

1. **Centralized design system**
   - Colors, typography, spacing, radius, component themes, and light/dark variants are centralized under `lib/core/theme/`.

2. **Component-driven UI**
   - Reusable widgets such as `ActionCard` and `RequestCard` encapsulate visual structure and interaction contracts.

3. **Generated localization**
   - ARB files define user-facing text in English and Arabic.
   - Flutter's localization generator produces strongly typed accessors in `AppLocalizations`.

Together, these mechanisms improve consistency, scalability, and maintainability across a large Flutter codebase.

## 2. Design System and Material 3

### 2.1 Central Theme Entry Point

`AppTheme` is the theme factory for the application:

```text
lib/core/theme/app_theme.dart
```

It exposes:

- `AppTheme.lightTheme`
- `AppTheme.darkTheme`
- `AppTheme.getTheme(dynamic role)` as a legacy compatibility API

The application consumes these themes in `main.dart`:

```text
theme: AppTheme.lightTheme
darkTheme: AppTheme.darkTheme
themeMode: themeMode
```

This centralizes visual language at the application boundary. Individual screens do not need to define their own global color system, button shapes, or input borders.

### 2.2 Material 3 Foundation

`app_theme.dart` enables Material 3:

```dart
useMaterial3: true
```

It builds a `ColorScheme` manually inside `_build(...)`, mapping Sheryan's medical visual identity into Material 3 semantic slots:

- `primary`
- `onPrimary`
- `primaryContainer`
- `secondary`
- `secondaryContainer`
- `error`
- `surface`
- `onSurface`
- `onSurfaceVariant`
- `outline`
- `surfaceContainer*`

This is important because Material 3 components derive visual behavior from semantic color slots rather than scattered hardcoded colors.

### 2.3 Light and Dark Mode

The light theme uses a pure medical light palette:

```text
primary             -> AppColors.medicalBlue
primaryContainer    -> AppColors.medicalBlueLight
scaffold            -> AppColors.scaffoldLight
surface             -> AppColors.surfaceLight
surfaceContainer    -> AppColors.surfaceContainerLight
onSurface           -> AppColors.textOnLight
onSurfaceVariant    -> AppColors.textOnLightSecondary
outline             -> AppColors.borderLight
```

The dark theme uses a dark medical palette:

```text
primary             -> AppColors.medicalBlueDark
scaffold            -> AppColors.scaffoldDarkNew
surface             -> AppColors.surfaceDarkNew
surfaceContainer    -> AppColors.surfaceContainerDarkNew
onSurface           -> AppColors.textOnDark
onSurfaceVariant    -> AppColors.textOnDarkSecondary
outline             -> AppColors.borderDark
```

The important software engineering property is symmetry: both theme modes are produced through the same `_build(...)` function. This reduces theme drift.

### 2.4 Color Tokens

`app_colors.dart` defines semantic tokens:

- medical primary colors,
- blood-specific red colors,
- light and dark backgrounds,
- text colors,
- status colors,
- legacy aliases,
- role color aliases.

The design distinction is clear:

```text
medicalBlue -> system-level primary brand color
bloodRed    -> blood-specific semantic/action color
success     -> positive state
error       -> destructive/failure state
warning     -> caution state
info        -> informational state
```

This improves consistency because status colors are named semantically rather than selected ad hoc per widget.

### 2.5 Typography Tokens

`app_typography.dart` defines `AppTypography.textTheme` using a compact set of text styles:

- `displayMedium`
- `titleLarge`
- `titleMedium`
- `bodyLarge`
- `bodyMedium`
- `labelSmall`
- `labelLarge`

The theme applies this typography through:

```dart
AppTypography.textTheme.apply(
  bodyColor: onSurface,
  displayColor: onSurface,
)
```

This separates font scale and weight from theme color. The same typography system works in both light and dark mode because colors are injected by the active theme.

### 2.6 Layout Tokens

`app_design_constants.dart` defines reusable layout constants:

- border radii: small, medium, large, extra-large, circular,
- padding values,
- elevation values,
- icon sizes.

This reduces "magic numbers" in the UI and gives the codebase a shared spacing/radius vocabulary.

### 2.7 Component Theme Centralization

`AppTheme._build()` configures Material components globally:

- `AppBarTheme`
- `CardThemeData`
- `ElevatedButtonThemeData`
- `TextButtonThemeData`
- `OutlinedButtonThemeData`
- `InputDecorationTheme`
- `ProgressIndicatorThemeData`
- `DividerThemeData`
- `BottomNavigationBarThemeData`
- `BottomAppBarThemeData`
- `ListTileThemeData`
- `SwitchThemeData`
- `DialogThemeData`
- `SnackBarThemeData`
- `TabBarThemeData`
- `ChipThemeData`
- `PopupMenuThemeData`
- `BottomSheetThemeData`

This is enterprise-oriented because it moves styling policy from individual screens into one design-system layer. The expected result is consistency across admin, hospital, donor, recipient, and sponsor interfaces.

## 3. Component-Driven Architecture

### 3.1 ActionCard

`ActionCard` is implemented in:

```text
lib/screens/home/widgets/action_card.dart
```

It is a `StatelessWidget` with a clean input contract:

```text
title
subtitle
icon
color
onTap
```

The widget is independent of business logic. It does not know what screen it opens, what role the user has, or what service operation will happen after tapping. It only receives a callback.

This produces a strong separation:

```text
Parent screen decides behavior
ActionCard renders reusable interaction tile
```

### 3.2 ActionCard Design Properties

The component uses:

- `Theme.of(context).colorScheme.surface`
- `Theme.of(context).colorScheme.outline`
- `Theme.of(context).colorScheme.onSurface`
- `AppDesignConstants.borderRadiusMedium`
- bounded text with `maxLines` and `TextOverflow.ellipsis`
- an icon container colored by the injected semantic color

This makes it portable across light/dark modes and role contexts. It can be reused for home actions, navigation shortcuts, dashboard actions, or feature launchers.

Architectural benefits:

- no duplicated card layout across screens,
- consistent tap behavior and shape,
- theming through `Theme.of(context)`,
- behavior injected via callback,
- text injected by parent, allowing localization outside the component.

### 3.3 RequestCard

`RequestCard` is implemented in:

```text
lib/screens/hospital/requests/request_card.dart
```

Its input contract is:

```text
doc
isDone
isVerified
isUrgent
hospitalName
adminUid
hospitalId
```

It represents a hospital-facing blood request summary card. It extracts display properties from `doc`, computes status icon/color, displays blood group, patient name, unit count, date, urgency state, and opens `RequestDetailSheet` on tap.

### 3.4 RequestCard Design Properties

`RequestCard` encapsulates request summary rendering:

- status mapping:
  - done -> success/check icon,
  - verified -> blue/verified icon,
  - pending -> orange/pending icon,
- urgency border and urgent badge,
- blood group visual badge,
- date formatting from Firestore `Timestamp`,
- modal bottom sheet interaction.

The parent screen does not need to repeatedly encode how a request card looks or how status maps to icons.

### 3.5 Decoupling Benefits

Reusable widgets reduce monolithic screen complexity. Instead of a screen containing all layout, status mapping, tap handling, and modal creation inline, responsibilities are split:

```text
Requests screen
    -> owns list/query/tab context

RequestCard
    -> owns summary visual representation

RequestDetailSheet
    -> owns detail interaction and verification workflow
```

This improves:

- readability,
- testability,
- layout consistency,
- future refactoring,
- feature isolation.

### 3.6 Current Coupling Notes

The component model is strong but not perfectly decoupled:

- `RequestCard` accepts a raw `Map<String, dynamic>` rather than a typed request model.
- `RequestCard` directly opens `RequestDetailSheet`, so it owns part of navigation behavior.
- Some fallback symbols and display strings are hardcoded, such as placeholder dash/question mark values and date formatting.
- `RequestCard` mixes theme tokens with direct `Colors.red`, `Colors.orange`, and `Colors.grey`.

For thesis accuracy, this should be described as a component-driven presentation layer with some pragmatic coupling still present in feature-specific widgets.

## 4. Internationalization (i18n)

### 4.1 ARB Structure

The localization folder contains:

```text
lib/l10n/
|-- app_en.arb
|-- app_ar.arb
|-- app_localizations.dart
|-- app_localizations_en.dart
`-- app_localizations_ar.dart
```

`app_en.arb` is the template file. `app_ar.arb` provides Arabic translations. Generated Dart files expose typed getters and methods.

The `l10n.yaml` configuration declares:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

This means localization strings are generated from ARB files into non-null accessors.

### 4.2 Application Integration

`main.dart` integrates localization through:

```text
onGenerateTitle: AppLocalizations.of(context)!.appTitle
locale: locale
supportedLocales: AppLocalizations.supportedLocales
localizationsDelegates:
  AppLocalizations.delegate
  GlobalMaterialLocalizations.delegate
  GlobalCupertinoLocalizations.delegate
  GlobalWidgetsLocalizations.delegate
```

This wires application strings and Flutter framework widgets into the selected locale.

### 4.3 Strongly Typed Localization Access

Generated `AppLocalizations` exposes getters and methods such as:

```text
appTitle
changeLanguage
roleDonor
requestSubmittedSuccessfully
requestSubmittingError(error)
neededAtValue(date)
urgentLabel
units
```

Parameterized messages in ARB, such as `{error}` or `{date}`, become typed methods in Dart. This avoids manual string interpolation scattered across UI code.

Example:

```dart
AppLocalizations.of(context)!.requestSubmittingError(e.toString())
```

This gives the project compile-time discoverability for localization keys.

### 4.4 Scale Benefits

ARB-based localization prepares the app for scale because:

- translations live in data files, not widget code,
- each key has a stable identifier,
- generated code gives typed access,
- English and Arabic can evolve in parallel,
- pluralization/placeholders can be represented in ARB metadata,
- supported locales are centralized,
- Flutter framework widgets receive Arabic/English localization delegates.

This is especially important for a health application because the same workflow must be understandable in multiple languages and across different user roles.

### 4.5 Zero-Hardcoded Strings Policy

The architecture is aligned with a zero-hardcoded-strings policy:

```text
UI text should come from AppLocalizations instead of inline string literals.
```

The existing implementation already uses this in many presentation files. For example, `RequestCard` calls:

```dart
final l10n = AppLocalizations.of(context)!;
```

and uses localized labels such as:

```text
l10n.urgentLabel
l10n.units
```

However, the codebase is not yet a perfect zero-hardcoded-string implementation. Some widgets still contain fallback display values and direct formatting literals. These are minor but should be documented as improvement targets.

Recommended policy statement for the thesis:

```text
The project uses ARB-backed generated localization as the architectural standard for user-facing strings, with remaining hardcoded fallback strings treated as technical debt.
```

## 5. UI Scalability Evaluation

### Strengths

- Material 3 is enabled globally.
- Light and dark themes share one internal builder.
- Color, typography, spacing, radius, and component themes are centralized.
- Reusable widgets reduce repeated layout code.
- ARB files provide scalable English/Arabic localization.
- Generated `AppLocalizations` gives typed accessors and parameterized messages.
- `Theme.of(context)` usage allows components to adapt to active theme.

### Improvement Opportunities

- Replace raw maps in widgets like `RequestCard` with typed view models.
- Move hardcoded fallback display values into localization keys where user-visible.
- Standardize direct color usage into semantic design tokens.
- Keep navigation decisions outside low-level reusable cards when deeper decoupling is needed.
- Add more shared components for badges, status chips, request metadata rows, and blood group labels.
- Consider a stricter lint/review policy against user-facing hardcoded strings.

## 6. Academic Framing

Sheryan's presentation architecture can be described as a **component-driven Flutter UI backed by a centralized Material 3 design system and ARB-based internationalization**.

The design system provides visual consistency through centralized color schemes, typography, spacing constants, and global component themes. This reduces visual drift across a multi-role application where donors, recipients, hospital admins, sponsors, and super admins each interact with different screens.

The component-driven approach improves scalability by decomposing complex screens into reusable widgets with explicit input contracts. `ActionCard` represents a generic dashboard action component, while `RequestCard` represents a domain-specific hospital request summary component. This pattern supports maintainability because visual and interaction patterns can be evolved at the component level rather than rewritten across screens.

The localization architecture uses ARB files as the translation source of truth and generated Dart accessors as the application API. This prepares the app for multilingual expansion and supports a zero-hardcoded-strings standard, with the current codebase already using localization broadly while retaining a few fallback literals as technical debt.

For the thesis, the presentation layer can be summarized as:

```text
Design System          -> AppTheme + AppColors + AppTypography + AppDesignConstants
Component Architecture -> ActionCard + RequestCard + feature widgets
Localization           -> ARB files + generated AppLocalizations
Scalability Goal       -> reusable UI, theme consistency, multilingual growth
```
