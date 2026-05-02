// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Blood Donation App';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get donorDashboard => 'Donor Dashboard';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get friend => 'Friend';

  @override
  String get motivationTitle => 'Motivational Quote';

  @override
  String get bloodGroup => 'Blood Group';

  @override
  String get city => 'City';

  @override
  String get usersBloodRequests => 'Users Blood Requests';

  @override
  String get viewAllRequestsFromUsersAcross =>
      'View all requests from users across';

  @override
  String get nearbyRequests => 'Nearby Requests';

  @override
  String get checkNearbyBloodRequests => 'Check nearby blood requests';

  @override
  String get awareness => 'Awareness';

  @override
  String get awarenessDonorSubtitle =>
      'Donate with confidence: Essential tips and guidelines';

  @override
  String get requestBlood => 'Request Blood';

  @override
  String get createNewBloodRequest => 'Create a new blood request';

  @override
  String get myRequests => 'My Requests';

  @override
  String get trackPreviousRequests => 'Track your previous requests';

  @override
  String get nearbyDonors => 'Nearby Donors';

  @override
  String get trackNearbyDonors => 'Track all your nearby donors';

  @override
  String get awarenessUserSubtitle =>
      'Stay Safe, Donate Safe: Essential Tips for Blood Donors';

  @override
  String get homeTab => 'Home';

  @override
  String get donorsTab => 'Donors';

  @override
  String get profileTab => 'Profile';

  @override
  String get allDonorsTab => 'All donors';

  @override
  String get roleWhoAreYou => 'Who are you?';

  @override
  String get roleSelectContinue => 'Select your role to continue';

  @override
  String get roleDonor => 'Donor';

  @override
  String get roleDonorSubtitle => 'I want to donate blood';

  @override
  String get roleUser => 'User';

  @override
  String get roleUserSubtitle => 'I need blood or browse donors';

  @override
  String get alreadyHaveAccountLogin => 'Already have an account? Login';

  @override
  String get loginEnterEmailPassword => 'Enter email & password';

  @override
  String loginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get welcomeBack => 'Welcome Back 👋';

  @override
  String get loginToAccount => 'Login to your account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Login';

  @override
  String get dontHaveAccountSignUp => 'Don\'t have an account? Sign Up';

  @override
  String get signupFillAllFields => 'Please fill all fields';

  @override
  String get signupValidEmail => 'Please enter a valid email';

  @override
  String get signupPasswordStrong =>
      'Password must be at least 6 characters and include letters & numbers';

  @override
  String get accountCreated => 'Account created';

  @override
  String get signupFailed => 'Signup failed';

  @override
  String get emailAlreadyInUse => 'Email already in use';

  @override
  String get createAccountTitle => 'Create Account 🩸';

  @override
  String get fillDetailsCreateAccount => 'Fill details to create an account';

  @override
  String get fullName => 'Full name';

  @override
  String get phoneWithCountryCode => 'Phone (with country code)';

  @override
  String get enterCityOrVillage => 'Enter city or village';

  @override
  String get selectLastDonationDate => 'Select last donation date';

  @override
  String lastDonatedOn(String date) {
    return 'Last donated: $date';
  }

  @override
  String get signUp => 'Sign Up';

  @override
  String get requestFillRequiredFields => 'Please fill all required fields';

  @override
  String get requestSubmittedSuccessfully => 'Request submitted successfully';

  @override
  String requestSubmittingError(String error) {
    return 'Error submitting: $error';
  }

  @override
  String get createBloodRequest => 'Create Blood Request';

  @override
  String get patientName => 'Patient Name';

  @override
  String get hospitalName => 'Hospital Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get units => 'Units';

  @override
  String get whenBloodNeededTap => 'When is blood needed? (tap to select)';

  @override
  String neededAtValue(String date) {
    return 'Needed: $date';
  }

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get markAsDone => 'Mark as Done';

  @override
  String get confirmRequestFulfilled =>
      'Are you sure this blood request is fulfilled?';

  @override
  String get cancel => 'Cancel';

  @override
  String get yesDone => 'Yes, Done';

  @override
  String get myBloodRequests => 'My Blood Requests';

  @override
  String get noBloodRequestsFound => 'No blood requests found';

  @override
  String hospitalLabel(String value) {
    return '🏥 Hospital: $value';
  }

  @override
  String cityLabel(String value) {
    return '📍 City: $value';
  }

  @override
  String phoneLabel(String value) {
    return '📞 Phone: $value';
  }

  @override
  String unitsLabel(String value) {
    return '💉 Units: $value';
  }

  @override
  String neededAtLabel(String value) {
    return '🕒 Needed At: $value';
  }

  @override
  String requestedOnLabel(String value) {
    return '📅 Requested On: $value';
  }

  @override
  String get unknownPatient => 'Unknown Patient';

  @override
  String get notAvailable => 'N/A';

  @override
  String genericError(String error) {
    return 'Error: $error';
  }

  @override
  String get statusDone => 'Done';

  @override
  String get statusPending => 'Pending';

  @override
  String get account => 'Account';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get privacyLegal => 'Privacy & Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get about => 'About';

  @override
  String get aboutApp => 'About App';

  @override
  String get changePassword => 'Change Password';

  @override
  String get enterCurrentPassword => 'Enter current password';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get passwordUpdated => 'Password updated successfully';

  @override
  String get currentPasswordIncorrect => 'Current password is incorrect';

  @override
  String get forgotPassword => 'Forgot Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordResetSent => 'Password reset email sent';

  @override
  String sendResetLinkTo(String email) {
    return 'Send reset link to $email';
  }

  @override
  String get signOut => 'Sign Out';

  @override
  String get confirmSignOut => 'Are you sure you want to sign out?';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get confirmDeleteAccount =>
      'This will permanently delete your account and data. This action cannot be undone. Are you sure?';

  @override
  String get permanentlyDeleteData =>
      'Permanently delete your account and data';

  @override
  String get confirmPasswordToDelete =>
      'Enter your current password to delete your account.';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get allRequestsDeleted => 'All requests deleted successfully';

  @override
  String get resetAllRequests => 'Reset All Requests';

  @override
  String get confirmResetRequests =>
      'Are you sure you want to delete all your requests?';

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get resetRequests => 'Reset Requests';

  @override
  String get all => 'All';

  @override
  String get noPhoneNumber => 'No phone number';

  @override
  String get cannotMakeCall => 'Cannot make call';

  @override
  String get availableDonors => 'Available Donors';

  @override
  String get noDonorsFound => 'No donors found';

  @override
  String get unknown => 'Unknown';

  @override
  String get quote1 => 'Your single act can save lives.';

  @override
  String get quote2 => 'Be the reason someone survives today.';

  @override
  String get quote3 => 'Every drop counts — donate blood.';

  @override
  String get quote4 => 'Giving blood is giving hope.';

  @override
  String get quote5 => 'Heroes don\'t wear capes, they donate blood.';

  @override
  String get quote6 => 'You can make a difference today.';

  @override
  String get quote7 => 'One call, one donation, one life saved.';

  @override
  String get donorDetails => 'Donor Details';

  @override
  String get donorNotFound => 'Donor not found';

  @override
  String get unknownDonor => 'Unknown Donor';

  @override
  String bloodGroupLabel(String value) {
    return 'Blood Group: $value';
  }

  @override
  String get phone => 'Phone';

  @override
  String get lastDonated => 'Last Donated';

  @override
  String get availableToDonate => 'Available to Donate';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get callDonor => 'Call Donor';

  @override
  String get myProfile => 'My Profile';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String get bloodDonor => 'Blood Donor';

  @override
  String get unknownCity => 'Unknown City';

  @override
  String get name => 'Name';

  @override
  String get accountType => 'Account Type';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get requiredField => 'Required field';

  @override
  String get noNearbyRequests => 'No nearby requests';

  @override
  String get call => 'Call';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String whatsappDonorMessage(String patient, String bloodGroup) {
    return 'Hello, I am contacting you via Sheryan app regarding the patient $patient. My blood group is $bloodGroup and I\'m ready to help. Please provide the hospital location.';
  }

  @override
  String whatsappRecipientMessage(
    String donor,
    String bloodGroup,
    String city,
  ) {
    return 'Hello $donor, I saw your profile on Sheryan app. We are in urgent need of $bloodGroup donor in $city. Can you help us?';
  }

  @override
  String get cannotOpenWhatsapp =>
      'Could not open WhatsApp. Please check if it\'s installed.';

  @override
  String get unableToDetectCity => 'Unable to detect your city.';

  @override
  String noDonorsFoundInCity(String city) {
    return 'No donors found in $city';
  }

  @override
  String get awarenessTitle => 'Blood Donation Tips';

  @override
  String get tipBeforeTitle => 'Before Donation';

  @override
  String get tipBeforePoint1 =>
      'Have a good meal at least 3 hours before donating.';

  @override
  String get tipBeforePoint2 =>
      'Drink plenty of water before and after donation.';

  @override
  String get tipBeforePoint3 =>
      'Avoid alcohol or smoking 24 hours before donating.';

  @override
  String get tipBeforePoint4 => 'Sleep well the night before donation.';

  @override
  String get tipDuringTitle => 'During Donation';

  @override
  String get tipDuringPoint1 =>
      'Relax and take deep breaths during the process.';

  @override
  String get tipDuringPoint2 => 'Squeeze the stress ball gently as instructed.';

  @override
  String get tipDuringPoint3 =>
      'Inform staff immediately if you feel dizzy or uncomfortable.';

  @override
  String get tipAfterTitle => 'After Donation';

  @override
  String get tipAfterPoint1 => 'Rest for 10–15 minutes and enjoy refreshments.';

  @override
  String get tipAfterPoint2 =>
      'Avoid heavy exercise or lifting for the rest of the day.';

  @override
  String get tipAfterPoint3 => 'Keep the bandage on for a few hours.';

  @override
  String get tipAfterPoint4 =>
      'If you feel dizzy, sit or lie down immediately.';

  @override
  String get tipBenefitsTitle => 'Benefits of Blood Donation';

  @override
  String get tipBenefitsPoint1 =>
      'Helps save lives in emergencies and surgeries.';

  @override
  String get tipBenefitsPoint2 =>
      'Improves heart health by balancing iron levels.';

  @override
  String get tipBenefitsPoint3 => 'Promotes the production of new blood cells.';

  @override
  String get tipBenefitsPoint4 =>
      'Brings a sense of pride and community contribution.';

  @override
  String get tipEligibilityTitle => 'Eligibility & Restrictions';

  @override
  String get tipEligibilityPoint1 =>
      'Donors must be 18–60 years old and healthy.';

  @override
  String get tipEligibilityPoint2 => 'Minimum weight should be at least 50 kg.';

  @override
  String get tipEligibilityPoint3 =>
      'Avoid donating if you have fever, cold, or infection.';

  @override
  String get tipEligibilityPoint4 =>
      'Wait at least 3 months between donations.';

  @override
  String get splashSaveLives => 'Save Lives';

  @override
  String get splashEveryDropCounts => 'Every Drop Counts ❤';

  @override
  String get totalRequests => 'Total Requests';

  @override
  String get yesDelete => 'Yes, Delete';

  @override
  String get supportEmailSubject => 'App Support - Blood Donation App';

  @override
  String get errorEmailApp => 'Could not open email app';

  @override
  String get fillBothPasswords => 'Please fill both password fields';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get change => 'Change';

  @override
  String get noEmailFound => 'No email found for this account';

  @override
  String resetPasswordConfirm(String email) {
    return 'A password reset email will be sent to $email. Continue?';
  }

  @override
  String get send => 'Send';

  @override
  String get currentPassword => 'Current password';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get passwordIncorrect => 'Password is incorrect';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get reLoginRequired => 'Please re-login recently and try again.';

  @override
  String developedBy(String name) {
    return 'Developed by: $name';
  }

  @override
  String get aboutDescription =>
      'The Blood Donation App is a community-driven platform designed to bridge the gap between blood donors and those in need.\nOur mission is to make finding and donating blood simple, fast, and reliable.\n\nBuilt with ❤ using Flutter and Firebase.\nTogether, we can save lives — one donation at a time.';

  @override
  String get privacyPolicyContent =>
      'Privacy Policy\n\nThank you for using our Blood Donation App.\nYour privacy is important to us.\n\n1. Information We Collect\n• Personal Information: Name, email, phone number, city, blood group, and account type.\n\n2. How We Use Your Information\n• To display your donor or user profile.\n• To manage blood requests and donations.\n\n3. Data Security\nYour data is securely stored using Firebase.\n\n4. Contact Us\n📧 Almohsen@gmail.com';

  @override
  String get termsConditionsContent =>
      'Terms & Conditions\n\nWelcome to our Blood Donation App. By using this app, you agree to the following terms:\n\n1. User Responsibilities\n• Provide accurate personal information.\n• Donors must ensure they are medically fit to donate.\n\n2. App Usage\n• The app is for humanitarian purposes only.\n\n3. Liability\nWe serve as a platform only.\n\nThank you for using our app to help save lives!';

  @override
  String get showQrCode => 'Show QR Code';

  @override
  String get donorCard => 'Donor Card';

  @override
  String get qrCodeTitle => 'Verification QR Code';

  @override
  String get scanToVerify =>
      'Scan this code at the hospital to verify or complete the process';

  @override
  String get requestId => 'Request ID';

  @override
  String get donorId => 'Donor ID';

  @override
  String get close => 'Close';

  @override
  String get hospitalAdminDashboard => 'Hospital Admin Dashboard';

  @override
  String get verifyRequest => 'Verify Request';

  @override
  String get registerDonation => 'Register Successful Donation';

  @override
  String get scanRequestQr => 'Scan Request QR';

  @override
  String get scanDonorQr => 'Scan Donor QR';

  @override
  String get scanSuccess => 'Scan Successful';

  @override
  String donorDetected(String name) {
    return 'Donor Detected: $name';
  }

  @override
  String requestDetected(String patient) {
    return 'Request Detected for: $patient';
  }

  @override
  String get confirmDonationTitle => 'Confirm Donation';

  @override
  String get confirmDonationBody =>
      'Are you sure you want to link this donor to this request and close it?';

  @override
  String get verifySuccess => 'Request verified successfully!';

  @override
  String get donationSuccess => 'Donation registered and request closed!';

  @override
  String get statusUnverified => 'Pending Verification';

  @override
  String get statusVerified => 'Verified & Active';

  @override
  String get statusCompleted => 'Donation Completed';

  @override
  String get invalidQr => 'Invalid QR code';

  @override
  String get waitingForDonor => 'Waiting for Donor QR...';

  @override
  String get waitingForRequest => 'Waiting for Request QR...';

  @override
  String get next => 'Next';

  @override
  String get step1Of2 => 'Step 1 of 2: Scan Donor';

  @override
  String get step2Of2 => 'Step 2 of 2: Scan Request';

  @override
  String get incomingRequests => 'Incoming Blood Requests';

  @override
  String get noRequestsFound => 'No requests found for your hospital';

  @override
  String get invalidHospital => 'This request is for another hospital!';

  @override
  String get adminDashboard => 'Super Admin Dashboard';

  @override
  String get manageHospitalAdmins => 'Manage Hospital Admins';

  @override
  String get manageCities => 'Manage Cities';

  @override
  String get manageHospitals => 'Manage Hospitals';

  @override
  String get addHospital => 'Add Hospital';

  @override
  String get hospitalAdded => 'Hospital added successfully!';

  @override
  String get hospitalDeleted => 'Hospital deleted successfully!';

  @override
  String get noHospitalsFound => 'No hospitals found';

  @override
  String get notificationPermissionTitle => 'Enable Notifications';

  @override
  String get notificationPermissionBody =>
      'Enable notifications to receive urgent blood request alerts in your city and track your donation status.';

  @override
  String get allow => 'Allow';

  @override
  String get later => 'Later';

  @override
  String get selectCity => 'Select City';

  @override
  String get createAdmin => 'Create Hospital Admin';

  @override
  String get hospitalId => 'Hospital ID';

  @override
  String get addCity => 'Add City';

  @override
  String get cityName => 'City Name';

  @override
  String get cityAdded => 'City added successfully!';

  @override
  String get cityDeleted => 'City deleted successfully!';

  @override
  String get adminCreated => 'Hospital Admin created successfully!';

  @override
  String get adminDeleted => 'Hospital Admin deleted successfully!';

  @override
  String get adminUpdated => 'Hospital Admin updated successfully!';

  @override
  String get editAdmin => 'Edit Admin';

  @override
  String get noAdminsFound => 'No hospital admins found';

  @override
  String get noCitiesFound => 'No cities found';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotificationsFound => 'No notifications yet';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get receiveAlerts => 'Receive alerts for emergency requests';

  @override
  String get testNotifications => 'Test Notifications';

  @override
  String get sendTestPush => 'Send Test Push to Me';

  @override
  String get checkingStatus => 'Checking OneSignal Status...';

  @override
  String get statusSubscribed => 'Subscribed';

  @override
  String get statusNotSubscribed => 'Not Subscribed';

  @override
  String userId(String id) {
    return 'User ID (External): $id';
  }

  @override
  String pushToken(String token) {
    return 'Push Token: $token';
  }

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get notifToday => 'Today';

  @override
  String get notifYesterday => 'Yesterday';

  @override
  String get notifEarlier => 'Earlier';

  @override
  String get notifTabEmergency => 'Emergency';

  @override
  String get notifTabVerification => 'Verification';

  @override
  String get notifTabDonation => 'Donation';

  @override
  String get notifTabSystem => 'System';

  @override
  String get noNotificationsInTab => 'No notifications in this category';

  @override
  String get profileCompletion => 'Profile Completion';

  @override
  String get profileSections => 'Complete your profile';

  @override
  String get completionFull => 'Your profile is 100% complete!';

  @override
  String get completionGood => 'Almost there — great progress!';

  @override
  String get completionPartial => 'Keep going — halfway done!';

  @override
  String get completionLow => 'Start completing your profile';

  @override
  String get verified => 'Verified';

  @override
  String get healthInfoTitle => 'Health Profile';

  @override
  String get healthInfoSubtitle => 'Height, weight, gender and smoking status';

  @override
  String get medicalHistoryTitle => 'Medical History';

  @override
  String get medicalHistorySubtitle => 'Last donation, diseases and allergies';

  @override
  String get emergencyContactTitle => 'Emergency Contact';

  @override
  String get emergencyContactSubtitle => 'Trusted person for emergencies';

  @override
  String get emergencyContactHint =>
      'This person will be contacted in case of emergency during donation';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get gender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get smokingStatus => 'Smoking Status';

  @override
  String get smokingNever => 'Non-smoker';

  @override
  String get smokingFormer => 'Former smoker';

  @override
  String get smokingCurrent => 'Current smoker';

  @override
  String get chronicDiseases => 'Chronic Diseases';

  @override
  String get chronicDiseasesHint =>
      'e.g. Diabetes, Hypertension (leave blank if none)';

  @override
  String get allergies => 'Allergies';

  @override
  String get allergiesHint => 'e.g. Penicillin, Latex (leave blank if none)';

  @override
  String get noneKnown => 'Leave blank if none known';

  @override
  String get emergencyContactName => 'Contact Full Name';

  @override
  String get emergencyContactPhone => 'Contact Phone Number';

  @override
  String get verifyDonorBloodGroup => 'Verify Donor Blood Group';

  @override
  String get scanDonorQrForVerification =>
      'Scan the donor\'s QR card to verify their blood group';

  @override
  String get bloodGroupVerificationTitle => 'Blood Group Verification';

  @override
  String get confirmBloodGroupVerification => 'Confirm Verification';

  @override
  String get bloodGroupVerifiedSuccess => 'Blood group verified successfully!';

  @override
  String get bloodGroupAlreadyVerified => 'Blood group already verified';

  @override
  String get donationHistory => 'Donation History';

  @override
  String get donationHistoryInfo =>
      'Populated automatically when a hospital admin registers your donation via QR scan';

  @override
  String get noDonationsYet => 'No donations recorded yet';

  @override
  String get noDonationsYetSubtitle =>
      'Once a hospital registers your donation, it will appear here automatically';

  @override
  String get donationSingular => 'Donation';

  @override
  String get donationPlural => 'Donations';

  @override
  String get totalBloodDonated => 'Total blood donated';

  @override
  String get donation => 'Donation';

  @override
  String get completed => 'Completed';

  @override
  String get unknownHospital => 'Unknown Hospital';

  @override
  String get viewDonationHistory => 'View Donation History';

  @override
  String get errorLoadingData => 'Failed to load data. Please try again.';

  @override
  String get bloodCompatibilityTitle => 'Blood Compatibility Guide';

  @override
  String get compatCanDonateTo => 'Can Donate To';

  @override
  String get compatCanReceiveFrom => 'Can Receive From';

  @override
  String get yourBloodGroup => 'Your Blood Group';

  @override
  String get universalDonor => 'Universal Donor';

  @override
  String get universalRecipient => 'Universal Recipient';

  @override
  String get canDonateTo => 'Donate To';

  @override
  String get canReceiveFrom => 'Receive From';

  @override
  String get compatSummary => 'Compatibility Summary';

  @override
  String get compatNone => 'None';

  @override
  String get viewCompatibilityGuide => 'Blood Compatibility Guide';

  @override
  String get offlineBannerTitle => 'You\'re offline';

  @override
  String get offlineBannerSubtitle => 'Showing cached data';

  @override
  String get backOnlineMessage => 'Back online ✓';

  @override
  String offlineCachedAt(String time) {
    return 'Last updated: $time';
  }

  @override
  String get requestSavedOffline =>
      'No internet — your request will be sent automatically when back online';

  @override
  String get pendingRequestsSynced => 'All pending requests have been sent';

  @override
  String hasPendingRequests(int count) {
    return 'You have $count pending request(s) waiting to sync';
  }

  @override
  String get offlineActionDisabled =>
      'This action requires an internet connection';

  @override
  String cachedDonorsLabel(int count) {
    return 'Showing $count cached donors';
  }

  @override
  String get basicInfoTitle => 'Basic Information';

  @override
  String get basicInfoSubtitle =>
      'Name, phone, city, blood group, date of birth';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get myPoints => 'My Points';

  @override
  String get pointsBalance => 'pts';

  @override
  String get donorTier => 'Tier';

  @override
  String get tierBronze => 'Bronze';

  @override
  String get tierSilver => 'Silver';

  @override
  String get tierGold => 'Gold';

  @override
  String get tierPlatinum => 'Platinum';

  @override
  String get pointsHistory => 'Points History';

  @override
  String get noPointsYet => 'No points yet';

  @override
  String get rewardsTab =>
      'Earn points and redeem rewards from sponsor organizations';

  @override
  String get availableRewards => 'Available Rewards';

  @override
  String get noRewardsFound => 'No rewards found in this city';

  @override
  String get rewardTitle => 'Reward Title';

  @override
  String get rewardDescription => 'Reward Description';

  @override
  String get pointsRequired => 'Points Required';

  @override
  String get redeemReward => 'Redeem';

  @override
  String get notEnoughPoints => 'Not enough points';

  @override
  String get showMyQr => 'Show My QR';

  @override
  String get sponsorDashboard => 'Sponsor Dashboard';

  @override
  String get myRewards => 'My Rewards';

  @override
  String get addReward => 'Add Reward';

  @override
  String get editReward => 'Edit Reward';

  @override
  String get deleteReward => 'Delete Reward';

  @override
  String get confirmDeleteReward =>
      'Are you sure you want to delete this reward?';

  @override
  String get rewardSaved => 'Reward saved successfully';

  @override
  String get rewardDeleted => 'Reward deleted';

  @override
  String get noRewardsAdded => 'No rewards added yet';

  @override
  String get scanDonorQrRedeem => 'Scan Donor QR to Redeem';

  @override
  String get redeemSuccess => 'Redeemed successfully';

  @override
  String get insufficientPoints => 'Donor has insufficient points';

  @override
  String get sponsorOrgName => 'Organization / Shop Name';

  @override
  String get sponsorPhone => 'Phone Number';

  @override
  String get sponsorAddress => 'Address / Location';

  @override
  String get manageSponsorOrgs => 'Manage Sponsor Organizations';

  @override
  String get createSponsor => 'Create Sponsor';

  @override
  String get sponsorCreated => 'Sponsor organization created successfully';

  @override
  String get sponsorDeleted => 'Sponsor deleted';

  @override
  String get noSponsorsFound => 'No sponsor organizations found';

  @override
  String get totalRedeemed => 'Total Redeemed';

  @override
  String get activeRewards => 'Active Rewards';

  @override
  String get filterByCity => 'Filter by City';

  @override
  String get allCities => 'All Cities';

  @override
  String get superAdminLabel => 'Super Admin';

  @override
  String get adminOverview => 'Overview';

  @override
  String get totalDonors => 'Total Donors';

  @override
  String get totalHospitals => 'Hospitals';

  @override
  String get openRequests => 'Open Requests';

  @override
  String get totalDonations => 'Donations';

  @override
  String get manageDonors => 'Donors';

  @override
  String get allBloodRequests => 'Blood Requests';

  @override
  String get broadcastNotif => 'Broadcast';

  @override
  String get donorDeleted => 'Donor deleted successfully';

  @override
  String get confirmDeleteBody => 'This action cannot be undone. Are you sure?';

  @override
  String get notifTitleField => 'Notification Title';

  @override
  String get notifBodyField => 'Notification Message';

  @override
  String get targetAudience => 'Target Audience';

  @override
  String get targetAll => 'All Users';

  @override
  String get targetByCity => 'Specific City';

  @override
  String get targetByBloodGroup => 'Specific Blood Group';

  @override
  String get sendNotif => 'Send Notification';

  @override
  String get notifSent => 'Notification sent successfully';

  @override
  String get filterByBloodGroup => 'Filter by Blood Group';

  @override
  String get allBloodGroups => 'All Blood Groups';

  @override
  String get searchDonors => 'Search donors...';

  @override
  String get editHospital => 'Edit Hospital';

  @override
  String get hospitalUpdated => 'Hospital updated successfully';

  @override
  String get requestDeletedSuccess => 'Request deleted successfully';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get announcementHistory => 'Sent Announcements';

  @override
  String get noAnnouncementsYet => 'No announcements sent yet';

  @override
  String get manageHospitalAdminsSubtitle => 'Assign admins to hospitals';

  @override
  String get assignedHospital => 'Hospital';

  @override
  String get editCity => 'Edit City';

  @override
  String get cityUpdated => 'City updated successfully';

  @override
  String get editSponsor => 'Edit Sponsor';

  @override
  String get sponsorUpdated => 'Sponsor updated successfully';
}
