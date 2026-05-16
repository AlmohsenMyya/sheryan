# Production Settings Refactor & Developer Profile

## 1. Overview
This update transforms the settings layer into an enterprise-grade interactive interface, integrating deep-linking, dynamic package scanning, and a dedicated professional developer profile.

## 2. Key Enhancements

### 2.1 Enterprise Support Integration
- **Direct WhatsApp Bridge:** The "Contact Support" tile now acts as a deep link to WhatsApp (`+963996367749`).
- **Contextual Messaging:** Pre-filled localized support greetings are injected into the URL to streamline user inquiries.

### 2.2 Dynamic System Metadata
- **Integration of `package_info_plus`:** The "About App" section now dynamically retrieves the application version and build number from the environment, replacing static hardcoded strings.
- **System Dialog:** Integrated `showAboutDialog` for a native Material 3 experience.

### 2.3 Legal & External Links
- **Web-view Transition:** Privacy Policy and Terms of Service tiles now launch external secure web URLs using `url_launcher`.
- **Fault Tolerance:** Implemented `canLaunchUrl` guards and error handling to ensure application stability during scheme failures.

### 2.4 Developer Profile Screen
- **New Feature:** Added a "Developer Profile" entry point in settings.
- **Architectural Credit:** Dedicated screen for **Eng. Almohsen Myya** (Senior Flutter Developer & Core Architect).
- **Interactive Social Layer:**
    - GitHub & LinkedIn deep-linking.
    - Direct contact bridge.
    - Material 3 responsive layout with full Dark/Light mode support.

## 3. Localization Hygiene
- Strictly adhered to the zero-hardcoded-strings policy.
- All new strings extracted to `app_en.arb` and `app_ar.arb`.
- Integrated `developerProfileTitle`, `developerName`, `developerBio`, `whatsappSupportMessage`, and `appVersion`.

---
*Log updated: May 2026*
