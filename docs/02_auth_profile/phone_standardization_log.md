# Standardization of Syrian Phone Numbers (+963)

## 1. Overview
To ensure data integrity and a seamless user experience for calling and WhatsApp integration, we have standardized all phone number inputs across the "Sheryan" ecosystem to follow the Syrian international format.

## 2. Technical Specifications
- **Prefix:** Fixed `+963` (displayed as non-editable prefix text).
- **Format:** Exactly 9 digits following the prefix (e.g., `933123456`).
- **Validation:** Strict 9-digit length requirement.
- **Input Control:** 
    - `TextInputType.phone` enabled.
    - `FilteringTextInputFormatter.digitsOnly` applied to prevent illegal characters.
    - `maxLength: 9` set to prevent overflows.
- **Storage:** Saved in full E.164 format (`+9639xxxxxxxx`).

## 3. Implementation Details

### 3.1 Affected Modules
1.  **Auth (Sign Up):** Standardized donor/recipient registration.
2.  **Blood Requests:** Standardized contact number for emergency requests.
3.  **Donor Profile (Basic Info):** Standardized phone updates; includes logic to strip prefix when loading existing data for editing.
4.  **Recipient Profile (Edit Sheet):** Standardized phone updates; includes prefix stripping logic.
5.  **Hospital Admin (Profile):** Standardized hospital inquiry number.
6.  **Super Admin (Sponsor Creation):** Standardized organization contact number.

### 3.2 Key Code Patterns
- **Parsing existing data:**
  ```dart
  if (phone.startsWith('+963')) {
    phone = phone.substring(4);
  }
  ```
- **Saving data:**
  ```dart
  final fullPhone = '+963${_phoneController.text.trim()}';
  ```

## 4. UI/UX Benefits
- Users no longer need to worry about leading zeros or country codes.
- Immediate feedback via localized error messages if the number is incomplete.
- Guaranteed compatibility with `url_launcher` for one-tap calls and WhatsApp messages.

---
*Log updated: May 2026*
