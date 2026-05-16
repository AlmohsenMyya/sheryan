import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Shreyan'**
  String get appTitle;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @donorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Donor Dashboard'**
  String get donorDashboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @motivationTitle.
  ///
  /// In en, this message translates to:
  /// **'Motivational Quote'**
  String get motivationTitle;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get bloodGroup;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @usersBloodRequests.
  ///
  /// In en, this message translates to:
  /// **'Users Blood Requests'**
  String get usersBloodRequests;

  /// No description provided for @viewAllRequestsFromUsersAcross.
  ///
  /// In en, this message translates to:
  /// **'View all requests from users across'**
  String get viewAllRequestsFromUsersAcross;

  /// No description provided for @nearbyRequests.
  ///
  /// In en, this message translates to:
  /// **'Nearby Requests'**
  String get nearbyRequests;

  /// No description provided for @checkNearbyBloodRequests.
  ///
  /// In en, this message translates to:
  /// **'Check nearby blood requests'**
  String get checkNearbyBloodRequests;

  /// No description provided for @awareness.
  ///
  /// In en, this message translates to:
  /// **'Awareness'**
  String get awareness;

  /// No description provided for @awarenessDonorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Donate with confidence: Essential tips and guidelines'**
  String get awarenessDonorSubtitle;

  /// No description provided for @requestBlood.
  ///
  /// In en, this message translates to:
  /// **'Request Blood'**
  String get requestBlood;

  /// No description provided for @createNewBloodRequest.
  ///
  /// In en, this message translates to:
  /// **'Create a new blood request'**
  String get createNewBloodRequest;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @trackPreviousRequests.
  ///
  /// In en, this message translates to:
  /// **'Track your previous requests'**
  String get trackPreviousRequests;

  /// No description provided for @nearbyDonors.
  ///
  /// In en, this message translates to:
  /// **'Nearby Donors'**
  String get nearbyDonors;

  /// No description provided for @trackNearbyDonors.
  ///
  /// In en, this message translates to:
  /// **'Track all your nearby donors'**
  String get trackNearbyDonors;

  /// No description provided for @awarenessUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Safe, Donate Safe: Essential Tips for Blood Donors'**
  String get awarenessUserSubtitle;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @donorsTab.
  ///
  /// In en, this message translates to:
  /// **'Donors'**
  String get donorsTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @allDonorsTab.
  ///
  /// In en, this message translates to:
  /// **'All donors'**
  String get allDonorsTab;

  /// No description provided for @roleWhoAreYou.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get roleWhoAreYou;

  /// No description provided for @roleSelectContinue.
  ///
  /// In en, this message translates to:
  /// **'Select your role to continue'**
  String get roleSelectContinue;

  /// No description provided for @roleDonor.
  ///
  /// In en, this message translates to:
  /// **'Donor'**
  String get roleDonor;

  /// No description provided for @roleDonorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I want to donate blood'**
  String get roleDonorSubtitle;

  /// No description provided for @roleUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get roleUser;

  /// No description provided for @roleUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I need blood or browse donors'**
  String get roleUserSubtitle;

  /// No description provided for @alreadyHaveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccountLogin;

  /// No description provided for @loginEnterEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter email & password'**
  String get loginEnterEmailPassword;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back 👋'**
  String get welcomeBack;

  /// No description provided for @loginToAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get loginToAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @dontHaveAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccountSignUp;

  /// No description provided for @signupFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get signupFillAllFields;

  /// No description provided for @signupValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get signupValidEmail;

  /// No description provided for @signupPasswordStrong.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters and include letters & numbers'**
  String get signupPasswordStrong;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get accountCreated;

  /// No description provided for @signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Signup failed'**
  String get signupFailed;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get emailAlreadyInUse;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account 🩸'**
  String get createAccountTitle;

  /// No description provided for @fillDetailsCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Fill details to create an account'**
  String get fillDetailsCreateAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phoneWithCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Phone (with country code)'**
  String get phoneWithCountryCode;

  /// No description provided for @enterCityOrVillage.
  ///
  /// In en, this message translates to:
  /// **'Enter city or village'**
  String get enterCityOrVillage;

  /// No description provided for @selectLastDonationDate.
  ///
  /// In en, this message translates to:
  /// **'Select last donation date'**
  String get selectLastDonationDate;

  /// No description provided for @lastDonatedOn.
  ///
  /// In en, this message translates to:
  /// **'Last donated: {date}'**
  String lastDonatedOn(String date);

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @requestFillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get requestFillRequiredFields;

  /// No description provided for @requestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request submitted successfully'**
  String get requestSubmittedSuccessfully;

  /// No description provided for @requestSubmittingError.
  ///
  /// In en, this message translates to:
  /// **'Error submitting: {error}'**
  String requestSubmittingError(String error);

  /// No description provided for @createBloodRequest.
  ///
  /// In en, this message translates to:
  /// **'Create Blood Request'**
  String get createBloodRequest;

  /// No description provided for @patientName.
  ///
  /// In en, this message translates to:
  /// **'Patient Name'**
  String get patientName;

  /// No description provided for @hospitalName.
  ///
  /// In en, this message translates to:
  /// **'Hospital Name'**
  String get hospitalName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @whenBloodNeededTap.
  ///
  /// In en, this message translates to:
  /// **'When is blood needed? (tap to select)'**
  String get whenBloodNeededTap;

  /// No description provided for @neededAtValue.
  ///
  /// In en, this message translates to:
  /// **'Needed: {date}'**
  String neededAtValue(String date);

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @markAsDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as Done'**
  String get markAsDone;

  /// No description provided for @confirmRequestFulfilled.
  ///
  /// In en, this message translates to:
  /// **'Are you sure this blood request is fulfilled?'**
  String get confirmRequestFulfilled;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yesDone.
  ///
  /// In en, this message translates to:
  /// **'Yes, Done'**
  String get yesDone;

  /// No description provided for @myBloodRequests.
  ///
  /// In en, this message translates to:
  /// **'My Blood Requests'**
  String get myBloodRequests;

  /// No description provided for @noBloodRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No blood requests found'**
  String get noBloodRequestsFound;

  /// No description provided for @hospitalLabel.
  ///
  /// In en, this message translates to:
  /// **'🏥 Hospital: {value}'**
  String hospitalLabel(String value);

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'📍 City: {value}'**
  String cityLabel(String value);

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'📞 Phone: {value}'**
  String phoneLabel(String value);

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'💉 Units: {value}'**
  String unitsLabel(String value);

  /// No description provided for @neededAtLabel.
  ///
  /// In en, this message translates to:
  /// **'🕒 Needed At: {value}'**
  String neededAtLabel(String value);

  /// No description provided for @requestedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'📅 Requested On: {value}'**
  String requestedOnLabel(String value);

  /// No description provided for @unknownPatient.
  ///
  /// In en, this message translates to:
  /// **'Unknown Patient'**
  String get unknownPatient;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String genericError(String error);

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @privacyLegal.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Legal'**
  String get privacyLegal;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdated;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordIncorrect;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get passwordResetSent;

  /// No description provided for @sendResetLinkTo.
  ///
  /// In en, this message translates to:
  /// **'Send reset link to {email}'**
  String sendResetLinkTo(String email);

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmSignOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and data. This action cannot be undone. Are you sure?'**
  String get confirmDeleteAccount;

  /// No description provided for @permanentlyDeleteData.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and data'**
  String get permanentlyDeleteData;

  /// No description provided for @confirmPasswordToDelete.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password to delete your account.'**
  String get confirmPasswordToDelete;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @allRequestsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All requests deleted successfully'**
  String get allRequestsDeleted;

  /// No description provided for @resetAllRequests.
  ///
  /// In en, this message translates to:
  /// **'Reset All Requests'**
  String get resetAllRequests;

  /// No description provided for @confirmResetRequests.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all your requests?'**
  String get confirmResetRequests;

  /// No description provided for @appPreferences.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get appPreferences;

  /// No description provided for @resetRequests.
  ///
  /// In en, this message translates to:
  /// **'Reset Requests'**
  String get resetRequests;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get noPhoneNumber;

  /// No description provided for @cannotMakeCall.
  ///
  /// In en, this message translates to:
  /// **'Cannot make call'**
  String get cannotMakeCall;

  /// No description provided for @availableDonors.
  ///
  /// In en, this message translates to:
  /// **'Available Donors'**
  String get availableDonors;

  /// No description provided for @noDonorsFound.
  ///
  /// In en, this message translates to:
  /// **'No donors found'**
  String get noDonorsFound;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @quote1.
  ///
  /// In en, this message translates to:
  /// **'\"The only way to connect human hearts is through that warm red path flowing in our veins.\" — One Piece'**
  String get quote1;

  /// No description provided for @quote2.
  ///
  /// In en, this message translates to:
  /// **'\"When does a person die?... They die when others forget them! Your donation leaves an immortal mark.\" — Dr. Hiriluk'**
  String get quote2;

  /// No description provided for @quote3.
  ///
  /// In en, this message translates to:
  /// **'\"We simply cannot survive without the help of others... Donate blood and be someone\'s pillar.\" — Monkey D. Luffy'**
  String get quote3;

  /// No description provided for @quote4.
  ///
  /// In en, this message translates to:
  /// **'\"As long as you are in pain and need help, it is my duty to lend you a hand.\" — Sanji'**
  String get quote4;

  /// No description provided for @quote5.
  ///
  /// In en, this message translates to:
  /// **'\"There is no pain in this world that cannot be eased by standing together... Your drops plant hope.\" — Chopper'**
  String get quote5;

  /// No description provided for @quote6.
  ///
  /// In en, this message translates to:
  /// **'\"If someone remembers you in the future, let them remember you as the one who gave life with a smile.\" — Corazon'**
  String get quote6;

  /// No description provided for @quote7.
  ///
  /// In en, this message translates to:
  /// **'\"As long as we are alive, there is always hope! Donate and grant the miracle of life.\" — Brook'**
  String get quote7;

  /// No description provided for @donorDetails.
  ///
  /// In en, this message translates to:
  /// **'Donor Details'**
  String get donorDetails;

  /// No description provided for @donorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Donor not found'**
  String get donorNotFound;

  /// No description provided for @unknownDonor.
  ///
  /// In en, this message translates to:
  /// **'Unknown Donor'**
  String get unknownDonor;

  /// No description provided for @bloodGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood Group: {value}'**
  String bloodGroupLabel(String value);

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @lastDonated.
  ///
  /// In en, this message translates to:
  /// **'Last Donated'**
  String get lastDonated;

  /// No description provided for @availableToDonate.
  ///
  /// In en, this message translates to:
  /// **'Available to Donate'**
  String get availableToDonate;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @callDonor.
  ///
  /// In en, this message translates to:
  /// **'Call Donor'**
  String get callDonor;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @bloodDonor.
  ///
  /// In en, this message translates to:
  /// **'Blood Donor'**
  String get bloodDonor;

  /// No description provided for @unknownCity.
  ///
  /// In en, this message translates to:
  /// **'Unknown City'**
  String get unknownCity;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @noNearbyRequests.
  ///
  /// In en, this message translates to:
  /// **'No nearby requests'**
  String get noNearbyRequests;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @whatsappDonorMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello, I am contacting you via Sheryan app regarding the patient {patient}. My blood group is {bloodGroup} and I\'m ready to help. Please provide the hospital location.'**
  String whatsappDonorMessage(String patient, String bloodGroup);

  /// No description provided for @whatsappRecipientMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello {donor}, I saw your profile on Sheryan app. We are in urgent need of {bloodGroup} donor in {city}. Can you help us?'**
  String whatsappRecipientMessage(String donor, String bloodGroup, String city);

  /// No description provided for @cannotOpenWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp. Please check if it\'s installed.'**
  String get cannotOpenWhatsapp;

  /// No description provided for @unableToDetectCity.
  ///
  /// In en, this message translates to:
  /// **'Unable to detect your city.'**
  String get unableToDetectCity;

  /// No description provided for @noDonorsFoundInCity.
  ///
  /// In en, this message translates to:
  /// **'No donors found in {city}'**
  String noDonorsFoundInCity(String city);

  /// No description provided for @awarenessTitle.
  ///
  /// In en, this message translates to:
  /// **'Blood Donation Tips'**
  String get awarenessTitle;

  /// No description provided for @tipBeforeTitle.
  ///
  /// In en, this message translates to:
  /// **'Before Donation'**
  String get tipBeforeTitle;

  /// No description provided for @tipBeforePoint1.
  ///
  /// In en, this message translates to:
  /// **'Have a good meal at least 3 hours before donating.'**
  String get tipBeforePoint1;

  /// No description provided for @tipBeforePoint2.
  ///
  /// In en, this message translates to:
  /// **'Drink plenty of water before and after donation.'**
  String get tipBeforePoint2;

  /// No description provided for @tipBeforePoint3.
  ///
  /// In en, this message translates to:
  /// **'Avoid alcohol or smoking 24 hours before donating.'**
  String get tipBeforePoint3;

  /// No description provided for @tipBeforePoint4.
  ///
  /// In en, this message translates to:
  /// **'Sleep well the night before donation.'**
  String get tipBeforePoint4;

  /// No description provided for @tipDuringTitle.
  ///
  /// In en, this message translates to:
  /// **'During Donation'**
  String get tipDuringTitle;

  /// No description provided for @tipDuringPoint1.
  ///
  /// In en, this message translates to:
  /// **'Relax and take deep breaths during the process.'**
  String get tipDuringPoint1;

  /// No description provided for @tipDuringPoint2.
  ///
  /// In en, this message translates to:
  /// **'Squeeze the stress ball gently as instructed.'**
  String get tipDuringPoint2;

  /// No description provided for @tipDuringPoint3.
  ///
  /// In en, this message translates to:
  /// **'Inform staff immediately if you feel dizzy or uncomfortable.'**
  String get tipDuringPoint3;

  /// No description provided for @tipAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'After Donation'**
  String get tipAfterTitle;

  /// No description provided for @tipAfterPoint1.
  ///
  /// In en, this message translates to:
  /// **'Rest for 10–15 minutes and enjoy refreshments.'**
  String get tipAfterPoint1;

  /// No description provided for @tipAfterPoint2.
  ///
  /// In en, this message translates to:
  /// **'Avoid heavy exercise or lifting for the rest of the day.'**
  String get tipAfterPoint2;

  /// No description provided for @tipAfterPoint3.
  ///
  /// In en, this message translates to:
  /// **'Keep the bandage on for a few hours.'**
  String get tipAfterPoint3;

  /// No description provided for @tipAfterPoint4.
  ///
  /// In en, this message translates to:
  /// **'If you feel dizzy, sit or lie down immediately.'**
  String get tipAfterPoint4;

  /// No description provided for @tipBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Benefits of Blood Donation'**
  String get tipBenefitsTitle;

  /// No description provided for @tipBenefitsPoint1.
  ///
  /// In en, this message translates to:
  /// **'Helps save lives in emergencies and surgeries.'**
  String get tipBenefitsPoint1;

  /// No description provided for @tipBenefitsPoint2.
  ///
  /// In en, this message translates to:
  /// **'Improves heart health by balancing iron levels.'**
  String get tipBenefitsPoint2;

  /// No description provided for @tipBenefitsPoint3.
  ///
  /// In en, this message translates to:
  /// **'Promotes the production of new blood cells.'**
  String get tipBenefitsPoint3;

  /// No description provided for @tipBenefitsPoint4.
  ///
  /// In en, this message translates to:
  /// **'Brings a sense of pride and community contribution.'**
  String get tipBenefitsPoint4;

  /// No description provided for @tipEligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Eligibility & Restrictions'**
  String get tipEligibilityTitle;

  /// No description provided for @tipEligibilityPoint1.
  ///
  /// In en, this message translates to:
  /// **'Donors must be 18–60 years old and healthy.'**
  String get tipEligibilityPoint1;

  /// No description provided for @tipEligibilityPoint2.
  ///
  /// In en, this message translates to:
  /// **'Minimum weight should be at least 50 kg.'**
  String get tipEligibilityPoint2;

  /// No description provided for @tipEligibilityPoint3.
  ///
  /// In en, this message translates to:
  /// **'Avoid donating if you have fever, cold, or infection.'**
  String get tipEligibilityPoint3;

  /// No description provided for @tipEligibilityPoint4.
  ///
  /// In en, this message translates to:
  /// **'Wait at least 3 months between donations.'**
  String get tipEligibilityPoint4;

  /// No description provided for @splashSaveLives.
  ///
  /// In en, this message translates to:
  /// **'Save Lives'**
  String get splashSaveLives;

  /// No description provided for @splashEveryDropCounts.
  ///
  /// In en, this message translates to:
  /// **'Every Drop Counts ❤'**
  String get splashEveryDropCounts;

  /// No description provided for @totalRequests.
  ///
  /// In en, this message translates to:
  /// **'Total Requests'**
  String get totalRequests;

  /// No description provided for @yesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete'**
  String get yesDelete;

  /// No description provided for @supportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'App Support - Blood Donation App'**
  String get supportEmailSubject;

  /// No description provided for @errorEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app'**
  String get errorEmailApp;

  /// No description provided for @fillBothPasswords.
  ///
  /// In en, this message translates to:
  /// **'Please fill both password fields'**
  String get fillBothPasswords;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @noEmailFound.
  ///
  /// In en, this message translates to:
  /// **'No email found for this account'**
  String get noEmailFound;

  /// No description provided for @resetPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'A password reset email will be sent to {email}. Continue?'**
  String resetPasswordConfirm(String email);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// No description provided for @passwordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Password is incorrect'**
  String get passwordIncorrect;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @reLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please re-login recently and try again.'**
  String get reLoginRequired;

  /// No description provided for @developedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by: {name}'**
  String developedBy(String name);

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'The Blood Donation App is a community-driven platform designed to bridge the gap between blood donors and those in need.\nOur mission is to make finding and donating blood simple, fast, and reliable.\n\nBuilt with ❤ using Flutter and Firebase.\nTogether, we can save lives — one donation at a time.'**
  String get aboutDescription;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy\n\nThank you for using our Blood Donation App.\nYour privacy is important to us.\n\n1. Information We Collect\n• Personal Information: Name, email, phone number, city, blood group, and account type.\n\n2. How We Use Your Information\n• To display your donor or user profile.\n• To manage blood requests and donations.\n\n3. Data Security\nYour data is securely stored using Firebase.\n\n4. Contact Us\n📧 Almohsen@gmail.com'**
  String get privacyPolicyContent;

  /// No description provided for @termsConditionsContent.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions\n\nWelcome to our Blood Donation App. By using this app, you agree to the following terms:\n\n1. User Responsibilities\n• Provide accurate personal information.\n• Donors must ensure they are medically fit to donate.\n\n2. App Usage\n• The app is for humanitarian purposes only.\n\n3. Liability\nWe serve as a platform only.\n\nThank you for using our app to help save lives!'**
  String get termsConditionsContent;

  /// No description provided for @showQrCode.
  ///
  /// In en, this message translates to:
  /// **'Show QR Code'**
  String get showQrCode;

  /// No description provided for @donorCard.
  ///
  /// In en, this message translates to:
  /// **'Donor Card'**
  String get donorCard;

  /// No description provided for @qrCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification QR Code'**
  String get qrCodeTitle;

  /// No description provided for @scanToVerify.
  ///
  /// In en, this message translates to:
  /// **'Scan this code at the hospital to verify or complete the process'**
  String get scanToVerify;

  /// No description provided for @requestId.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get requestId;

  /// No description provided for @donorId.
  ///
  /// In en, this message translates to:
  /// **'Donor ID'**
  String get donorId;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @hospitalAdminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Sheryan'**
  String get hospitalAdminDashboard;

  /// No description provided for @verifyRequest.
  ///
  /// In en, this message translates to:
  /// **'Verify Request'**
  String get verifyRequest;

  /// No description provided for @registerDonation.
  ///
  /// In en, this message translates to:
  /// **'Register Request Donation'**
  String get registerDonation;

  /// No description provided for @registerGeneralDonation.
  ///
  /// In en, this message translates to:
  /// **'General/Periodic Donation'**
  String get registerGeneralDonation;

  /// No description provided for @confirmGeneralDonationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm General Donation'**
  String get confirmGeneralDonationTitle;

  /// No description provided for @confirmGeneralDonationBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to register a general donation for this donor? This will update their last donation date and award 150 points.'**
  String get confirmGeneralDonationBody;

  /// No description provided for @generalDonationSuccess.
  ///
  /// In en, this message translates to:
  /// **'General donation registered successfully!'**
  String get generalDonationSuccess;

  /// No description provided for @bloodBankStock.
  ///
  /// In en, this message translates to:
  /// **'Blood Bank Inventory'**
  String get bloodBankStock;

  /// No description provided for @scanRequestQr.
  ///
  /// In en, this message translates to:
  /// **'Scan Request QR'**
  String get scanRequestQr;

  /// No description provided for @scanDonorQr.
  ///
  /// In en, this message translates to:
  /// **'Scan Donor QR'**
  String get scanDonorQr;

  /// No description provided for @scanSuccess.
  ///
  /// In en, this message translates to:
  /// **'Scan Successful'**
  String get scanSuccess;

  /// No description provided for @donorDetected.
  ///
  /// In en, this message translates to:
  /// **'Donor Detected: {name}'**
  String donorDetected(String name);

  /// No description provided for @requestDetected.
  ///
  /// In en, this message translates to:
  /// **'Request Detected for: {patient}'**
  String requestDetected(String patient);

  /// No description provided for @confirmDonationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Donation'**
  String get confirmDonationTitle;

  /// No description provided for @confirmDonationBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to link this donor to this request and close it?'**
  String get confirmDonationBody;

  /// No description provided for @verifySuccess.
  ///
  /// In en, this message translates to:
  /// **'Request verified successfully!'**
  String get verifySuccess;

  /// No description provided for @donationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Donation registered and request closed!'**
  String get donationSuccess;

  /// No description provided for @statusUnverified.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get statusUnverified;

  /// No description provided for @statusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified & Active'**
  String get statusVerified;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Donation Completed'**
  String get statusCompleted;

  /// No description provided for @invalidQr.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get invalidQr;

  /// No description provided for @waitingForDonor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Donor QR...'**
  String get waitingForDonor;

  /// No description provided for @waitingForRequest.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Request QR...'**
  String get waitingForRequest;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @step1Of2.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2: Scan Donor'**
  String get step1Of2;

  /// No description provided for @step2Of2.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2: Scan Request'**
  String get step2Of2;

  /// No description provided for @incomingRequests.
  ///
  /// In en, this message translates to:
  /// **'Incoming Blood Requests'**
  String get incomingRequests;

  /// No description provided for @noRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No requests found for your hospital'**
  String get noRequestsFound;

  /// No description provided for @invalidHospital.
  ///
  /// In en, this message translates to:
  /// **'This request is for another hospital!'**
  String get invalidHospital;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Super Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @manageHospitalAdmins.
  ///
  /// In en, this message translates to:
  /// **'Manage Hospital Admins'**
  String get manageHospitalAdmins;

  /// No description provided for @manageCities.
  ///
  /// In en, this message translates to:
  /// **'Manage Cities'**
  String get manageCities;

  /// No description provided for @manageHospitals.
  ///
  /// In en, this message translates to:
  /// **'Manage Hospitals'**
  String get manageHospitals;

  /// No description provided for @addHospital.
  ///
  /// In en, this message translates to:
  /// **'Add Hospital'**
  String get addHospital;

  /// No description provided for @hospitalAdded.
  ///
  /// In en, this message translates to:
  /// **'Hospital added successfully!'**
  String get hospitalAdded;

  /// No description provided for @hospitalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Hospital deleted successfully!'**
  String get hospitalDeleted;

  /// No description provided for @noHospitalsFound.
  ///
  /// In en, this message translates to:
  /// **'No hospitals found'**
  String get noHospitalsFound;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive urgent blood request alerts in your city and track your donation status.'**
  String get notificationPermissionBody;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Select City'**
  String get selectCity;

  /// No description provided for @createAdmin.
  ///
  /// In en, this message translates to:
  /// **'Create Hospital Admin'**
  String get createAdmin;

  /// No description provided for @hospitalId.
  ///
  /// In en, this message translates to:
  /// **'Hospital ID'**
  String get hospitalId;

  /// No description provided for @addCity.
  ///
  /// In en, this message translates to:
  /// **'Add City'**
  String get addCity;

  /// No description provided for @cityName.
  ///
  /// In en, this message translates to:
  /// **'City Name'**
  String get cityName;

  /// No description provided for @cityAdded.
  ///
  /// In en, this message translates to:
  /// **'City added successfully!'**
  String get cityAdded;

  /// No description provided for @cityDeleted.
  ///
  /// In en, this message translates to:
  /// **'City deleted successfully!'**
  String get cityDeleted;

  /// No description provided for @adminCreated.
  ///
  /// In en, this message translates to:
  /// **'Hospital Admin created successfully!'**
  String get adminCreated;

  /// No description provided for @adminDeleted.
  ///
  /// In en, this message translates to:
  /// **'Hospital Admin deleted successfully!'**
  String get adminDeleted;

  /// No description provided for @adminUpdated.
  ///
  /// In en, this message translates to:
  /// **'Hospital Admin updated successfully!'**
  String get adminUpdated;

  /// No description provided for @editAdmin.
  ///
  /// In en, this message translates to:
  /// **'Edit Admin'**
  String get editAdmin;

  /// No description provided for @noAdminsFound.
  ///
  /// In en, this message translates to:
  /// **'No hospital admins found'**
  String get noAdminsFound;

  /// No description provided for @noCitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No cities found'**
  String get noCitiesFound;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotificationsFound.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsFound;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @receiveAlerts.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts for emergency requests'**
  String get receiveAlerts;

  /// No description provided for @testNotifications.
  ///
  /// In en, this message translates to:
  /// **'Test Notifications'**
  String get testNotifications;

  /// No description provided for @sendTestPush.
  ///
  /// In en, this message translates to:
  /// **'Send Test Push to Me'**
  String get sendTestPush;

  /// No description provided for @checkingStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking OneSignal Status...'**
  String get checkingStatus;

  /// No description provided for @statusSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get statusSubscribed;

  /// No description provided for @statusNotSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Not Subscribed'**
  String get statusNotSubscribed;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID (External): {id}'**
  String userId(String id);

  /// No description provided for @pushToken.
  ///
  /// In en, this message translates to:
  /// **'Push Token: {token}'**
  String pushToken(String token);

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @notifToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notifToday;

  /// No description provided for @notifYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notifYesterday;

  /// No description provided for @notifEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notifEarlier;

  /// No description provided for @notifTabEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get notifTabEmergency;

  /// No description provided for @notifTabVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get notifTabVerification;

  /// No description provided for @notifTabDonation.
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get notifTabDonation;

  /// No description provided for @notifTabSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notifTabSystem;

  /// No description provided for @noNotificationsInTab.
  ///
  /// In en, this message translates to:
  /// **'No notifications in this category'**
  String get noNotificationsInTab;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletion;

  /// No description provided for @profileSections.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileSections;

  /// No description provided for @completionFull.
  ///
  /// In en, this message translates to:
  /// **'Your profile is 100% complete!'**
  String get completionFull;

  /// No description provided for @completionGood.
  ///
  /// In en, this message translates to:
  /// **'Almost there — great progress!'**
  String get completionGood;

  /// No description provided for @completionPartial.
  ///
  /// In en, this message translates to:
  /// **'Keep going — halfway done!'**
  String get completionPartial;

  /// No description provided for @completionLow.
  ///
  /// In en, this message translates to:
  /// **'Start completing your profile'**
  String get completionLow;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @healthInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Profile'**
  String get healthInfoTitle;

  /// No description provided for @healthInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Height, weight, gender and smoking status'**
  String get healthInfoSubtitle;

  /// No description provided for @medicalHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get medicalHistoryTitle;

  /// No description provided for @medicalHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last donation, diseases and allergies'**
  String get medicalHistorySubtitle;

  /// No description provided for @emergencyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContactTitle;

  /// No description provided for @emergencyContactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted person for emergencies'**
  String get emergencyContactSubtitle;

  /// No description provided for @emergencyContactHint.
  ///
  /// In en, this message translates to:
  /// **'This person will be contacted in case of emergency during donation'**
  String get emergencyContactHint;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @smokingStatus.
  ///
  /// In en, this message translates to:
  /// **'Smoking Status'**
  String get smokingStatus;

  /// No description provided for @smokingNever.
  ///
  /// In en, this message translates to:
  /// **'Non-smoker'**
  String get smokingNever;

  /// No description provided for @smokingFormer.
  ///
  /// In en, this message translates to:
  /// **'Former smoker'**
  String get smokingFormer;

  /// No description provided for @smokingCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current smoker'**
  String get smokingCurrent;

  /// No description provided for @chronicDiseases.
  ///
  /// In en, this message translates to:
  /// **'Chronic Diseases'**
  String get chronicDiseases;

  /// No description provided for @chronicDiseasesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Diabetes, Hypertension (leave blank if none)'**
  String get chronicDiseasesHint;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @allergiesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Penicillin, Latex (leave blank if none)'**
  String get allergiesHint;

  /// No description provided for @noneKnown.
  ///
  /// In en, this message translates to:
  /// **'Leave blank if none known'**
  String get noneKnown;

  /// No description provided for @emergencyContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact Full Name'**
  String get emergencyContactName;

  /// No description provided for @emergencyContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone Number'**
  String get emergencyContactPhone;

  /// No description provided for @verifyDonorBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Verify Donor Blood Group'**
  String get verifyDonorBloodGroup;

  /// No description provided for @scanDonorQrForVerification.
  ///
  /// In en, this message translates to:
  /// **'Scan the donor\'s QR card to verify their blood group'**
  String get scanDonorQrForVerification;

  /// No description provided for @bloodGroupVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Blood Group Verification'**
  String get bloodGroupVerificationTitle;

  /// No description provided for @confirmBloodGroupVerification.
  ///
  /// In en, this message translates to:
  /// **'Confirm Verification'**
  String get confirmBloodGroupVerification;

  /// No description provided for @bloodGroupVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Blood group verified successfully!'**
  String get bloodGroupVerifiedSuccess;

  /// No description provided for @bloodGroupAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'Blood group already verified'**
  String get bloodGroupAlreadyVerified;

  /// No description provided for @donationHistory.
  ///
  /// In en, this message translates to:
  /// **'Donation History'**
  String get donationHistory;

  /// No description provided for @donationHistoryInfo.
  ///
  /// In en, this message translates to:
  /// **'Populated automatically when a hospital admin registers your donation via QR scan'**
  String get donationHistoryInfo;

  /// No description provided for @noDonationsYet.
  ///
  /// In en, this message translates to:
  /// **'No donations recorded yet'**
  String get noDonationsYet;

  /// No description provided for @noDonationsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Once a hospital registers your donation, it will appear here automatically'**
  String get noDonationsYetSubtitle;

  /// No description provided for @donationSingular.
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get donationSingular;

  /// No description provided for @donationPlural.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get donationPlural;

  /// No description provided for @totalBloodDonated.
  ///
  /// In en, this message translates to:
  /// **'Total blood donated'**
  String get totalBloodDonated;

  /// No description provided for @donation.
  ///
  /// In en, this message translates to:
  /// **'Donation'**
  String get donation;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @unknownHospital.
  ///
  /// In en, this message translates to:
  /// **'Unknown Hospital'**
  String get unknownHospital;

  /// No description provided for @viewDonationHistory.
  ///
  /// In en, this message translates to:
  /// **'View Donation History'**
  String get viewDonationHistory;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data. Please try again.'**
  String get errorLoadingData;

  /// No description provided for @bloodCompatibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Blood Compatibility Guide'**
  String get bloodCompatibilityTitle;

  /// No description provided for @compatCanDonateTo.
  ///
  /// In en, this message translates to:
  /// **'Can Donate To'**
  String get compatCanDonateTo;

  /// No description provided for @compatCanReceiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Can Receive From'**
  String get compatCanReceiveFrom;

  /// No description provided for @yourBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Your Blood Group'**
  String get yourBloodGroup;

  /// No description provided for @universalDonor.
  ///
  /// In en, this message translates to:
  /// **'Universal Donor'**
  String get universalDonor;

  /// No description provided for @universalRecipient.
  ///
  /// In en, this message translates to:
  /// **'Universal Recipient'**
  String get universalRecipient;

  /// No description provided for @canDonateTo.
  ///
  /// In en, this message translates to:
  /// **'Donate To'**
  String get canDonateTo;

  /// No description provided for @canReceiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Receive From'**
  String get canReceiveFrom;

  /// No description provided for @compatSummary.
  ///
  /// In en, this message translates to:
  /// **'Compatibility Summary'**
  String get compatSummary;

  /// No description provided for @compatNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get compatNone;

  /// No description provided for @viewCompatibilityGuide.
  ///
  /// In en, this message translates to:
  /// **'Blood Compatibility Guide'**
  String get viewCompatibilityGuide;

  /// No description provided for @offlineBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineBannerTitle;

  /// No description provided for @offlineBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Showing cached data'**
  String get offlineBannerSubtitle;

  /// No description provided for @backOnlineMessage.
  ///
  /// In en, this message translates to:
  /// **'Back online ✓'**
  String get backOnlineMessage;

  /// No description provided for @offlineCachedAt.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String offlineCachedAt(String time);

  /// No description provided for @requestSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet — your request will be sent automatically when back online'**
  String get requestSavedOffline;

  /// No description provided for @pendingRequestsSynced.
  ///
  /// In en, this message translates to:
  /// **'All pending requests have been sent'**
  String get pendingRequestsSynced;

  /// No description provided for @hasPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'You have {count} pending request(s) waiting to sync'**
  String hasPendingRequests(int count);

  /// No description provided for @offlineActionDisabled.
  ///
  /// In en, this message translates to:
  /// **'This action requires an internet connection'**
  String get offlineActionDisabled;

  /// No description provided for @cachedDonorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} cached donors'**
  String cachedDonorsLabel(int count);

  /// No description provided for @basicInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfoTitle;

  /// No description provided for @basicInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, phone, city, blood group, date of birth'**
  String get basicInfoSubtitle;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @myPoints.
  ///
  /// In en, this message translates to:
  /// **'My Points'**
  String get myPoints;

  /// No description provided for @pointsBalance.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get pointsBalance;

  /// No description provided for @donorTier.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get donorTier;

  /// No description provided for @tierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get tierBronze;

  /// No description provided for @tierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get tierSilver;

  /// No description provided for @tierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get tierGold;

  /// No description provided for @tierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get tierPlatinum;

  /// No description provided for @pointsHistory.
  ///
  /// In en, this message translates to:
  /// **'Points History'**
  String get pointsHistory;

  /// No description provided for @noPointsYet.
  ///
  /// In en, this message translates to:
  /// **'No points yet'**
  String get noPointsYet;

  /// No description provided for @rewardsTab.
  ///
  /// In en, this message translates to:
  /// **'redeem rewards from sponsor organizations'**
  String get rewardsTab;

  /// No description provided for @availableRewards.
  ///
  /// In en, this message translates to:
  /// **'Available Rewards'**
  String get availableRewards;

  /// No description provided for @noRewardsFound.
  ///
  /// In en, this message translates to:
  /// **'No rewards found in this city'**
  String get noRewardsFound;

  /// No description provided for @rewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Reward Title'**
  String get rewardTitle;

  /// No description provided for @rewardDescription.
  ///
  /// In en, this message translates to:
  /// **'Reward Description'**
  String get rewardDescription;

  /// No description provided for @pointsRequired.
  ///
  /// In en, this message translates to:
  /// **'Points Required'**
  String get pointsRequired;

  /// No description provided for @redeemReward.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get redeemReward;

  /// No description provided for @notEnoughPoints.
  ///
  /// In en, this message translates to:
  /// **'Not enough points'**
  String get notEnoughPoints;

  /// No description provided for @showMyQr.
  ///
  /// In en, this message translates to:
  /// **'Show My QR'**
  String get showMyQr;

  /// No description provided for @sponsorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Sponsor Dashboard'**
  String get sponsorDashboard;

  /// No description provided for @myRewards.
  ///
  /// In en, this message translates to:
  /// **'My Rewards'**
  String get myRewards;

  /// No description provided for @addReward.
  ///
  /// In en, this message translates to:
  /// **'Add Reward'**
  String get addReward;

  /// No description provided for @editReward.
  ///
  /// In en, this message translates to:
  /// **'Edit Reward'**
  String get editReward;

  /// No description provided for @deleteReward.
  ///
  /// In en, this message translates to:
  /// **'Delete Reward'**
  String get deleteReward;

  /// No description provided for @confirmDeleteReward.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reward?'**
  String get confirmDeleteReward;

  /// No description provided for @rewardSaved.
  ///
  /// In en, this message translates to:
  /// **'Reward saved successfully'**
  String get rewardSaved;

  /// No description provided for @rewardDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reward deleted'**
  String get rewardDeleted;

  /// No description provided for @noRewardsAdded.
  ///
  /// In en, this message translates to:
  /// **'No rewards added yet'**
  String get noRewardsAdded;

  /// No description provided for @scanDonorQrRedeem.
  ///
  /// In en, this message translates to:
  /// **'Scan Donor QR to Redeem'**
  String get scanDonorQrRedeem;

  /// No description provided for @redeemSuccess.
  ///
  /// In en, this message translates to:
  /// **'Redeemed successfully'**
  String get redeemSuccess;

  /// No description provided for @insufficientPoints.
  ///
  /// In en, this message translates to:
  /// **'Donor has insufficient points'**
  String get insufficientPoints;

  /// No description provided for @sponsorOrgName.
  ///
  /// In en, this message translates to:
  /// **'Organization / Shop Name'**
  String get sponsorOrgName;

  /// No description provided for @sponsorPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get sponsorPhone;

  /// No description provided for @sponsorAddress.
  ///
  /// In en, this message translates to:
  /// **'Address / Location'**
  String get sponsorAddress;

  /// No description provided for @manageSponsorOrgs.
  ///
  /// In en, this message translates to:
  /// **'Manage Sponsor Organizations'**
  String get manageSponsorOrgs;

  /// No description provided for @createSponsor.
  ///
  /// In en, this message translates to:
  /// **'Create Sponsor'**
  String get createSponsor;

  /// No description provided for @sponsorCreated.
  ///
  /// In en, this message translates to:
  /// **'Sponsor organization created successfully'**
  String get sponsorCreated;

  /// No description provided for @sponsorDeleted.
  ///
  /// In en, this message translates to:
  /// **'Sponsor deleted'**
  String get sponsorDeleted;

  /// No description provided for @noSponsorsFound.
  ///
  /// In en, this message translates to:
  /// **'No sponsor organizations found'**
  String get noSponsorsFound;

  /// No description provided for @totalRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Total Redeemed'**
  String get totalRedeemed;

  /// No description provided for @activeRewards.
  ///
  /// In en, this message translates to:
  /// **'Active Rewards'**
  String get activeRewards;

  /// No description provided for @filterByCity.
  ///
  /// In en, this message translates to:
  /// **'Filter by City'**
  String get filterByCity;

  /// No description provided for @allCities.
  ///
  /// In en, this message translates to:
  /// **'All Cities'**
  String get allCities;

  /// No description provided for @superAdminLabel.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdminLabel;

  /// No description provided for @adminOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminOverview;

  /// No description provided for @totalDonors.
  ///
  /// In en, this message translates to:
  /// **'Total Donors'**
  String get totalDonors;

  /// No description provided for @totalHospitals.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get totalHospitals;

  /// No description provided for @openRequests.
  ///
  /// In en, this message translates to:
  /// **'Open Requests'**
  String get openRequests;

  /// No description provided for @totalDonations.
  ///
  /// In en, this message translates to:
  /// **'Donations'**
  String get totalDonations;

  /// No description provided for @manageDonors.
  ///
  /// In en, this message translates to:
  /// **'Donors'**
  String get manageDonors;

  /// No description provided for @allBloodRequests.
  ///
  /// In en, this message translates to:
  /// **'Blood Requests'**
  String get allBloodRequests;

  /// No description provided for @broadcastNotif.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcastNotif;

  /// No description provided for @donorDeleted.
  ///
  /// In en, this message translates to:
  /// **'Donor deleted successfully'**
  String get donorDeleted;

  /// No description provided for @confirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Are you sure?'**
  String get confirmDeleteBody;

  /// No description provided for @notifTitleField.
  ///
  /// In en, this message translates to:
  /// **'Notification Title'**
  String get notifTitleField;

  /// No description provided for @notifBodyField.
  ///
  /// In en, this message translates to:
  /// **'Notification Message'**
  String get notifBodyField;

  /// No description provided for @targetAudience.
  ///
  /// In en, this message translates to:
  /// **'Target Audience'**
  String get targetAudience;

  /// No description provided for @targetAll.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get targetAll;

  /// No description provided for @targetByCity.
  ///
  /// In en, this message translates to:
  /// **'Specific City'**
  String get targetByCity;

  /// No description provided for @targetByBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Specific Blood Group'**
  String get targetByBloodGroup;

  /// No description provided for @sendNotif.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotif;

  /// No description provided for @notifSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent successfully'**
  String get notifSent;

  /// No description provided for @filterByBloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Filter by Blood Group'**
  String get filterByBloodGroup;

  /// No description provided for @allBloodGroups.
  ///
  /// In en, this message translates to:
  /// **'All Blood Groups'**
  String get allBloodGroups;

  /// No description provided for @searchDonors.
  ///
  /// In en, this message translates to:
  /// **'Search donors...'**
  String get searchDonors;

  /// No description provided for @editHospital.
  ///
  /// In en, this message translates to:
  /// **'Edit Hospital'**
  String get editHospital;

  /// No description provided for @hospitalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Hospital updated successfully'**
  String get hospitalUpdated;

  /// No description provided for @requestDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Request deleted successfully'**
  String get requestDeletedSuccess;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @announcementHistory.
  ///
  /// In en, this message translates to:
  /// **'Sent Announcements'**
  String get announcementHistory;

  /// No description provided for @noAnnouncementsYet.
  ///
  /// In en, this message translates to:
  /// **'No announcements sent yet'**
  String get noAnnouncementsYet;

  /// No description provided for @requestDetails.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get requestDetails;

  /// No description provided for @markAsVerified.
  ///
  /// In en, this message translates to:
  /// **'Mark as Verified'**
  String get markAsVerified;

  /// No description provided for @manualDonationTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Donation Manually'**
  String get manualDonationTitle;

  /// No description provided for @enterDonorId.
  ///
  /// In en, this message translates to:
  /// **'Enter the donor\'s ID to look them up.'**
  String get enterDonorId;

  /// No description provided for @urgentLabel.
  ///
  /// In en, this message translates to:
  /// **'URGENT'**
  String get urgentLabel;

  /// No description provided for @requestDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get requestDate;

  /// No description provided for @fulfilledLabel.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled'**
  String get fulfilledLabel;

  /// No description provided for @verifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedLabel;

  /// No description provided for @manualOverrideNote.
  ///
  /// In en, this message translates to:
  /// **'QR unavailable? Use the buttons below to update manually.'**
  String get manualOverrideNote;

  /// No description provided for @manualBadge.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualBadge;

  /// No description provided for @manageHospitalAdminsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Assign admins to hospitals'**
  String get manageHospitalAdminsSubtitle;

  /// No description provided for @assignedHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get assignedHospital;

  /// No description provided for @editCity.
  ///
  /// In en, this message translates to:
  /// **'Edit City'**
  String get editCity;

  /// No description provided for @cityUpdated.
  ///
  /// In en, this message translates to:
  /// **'City updated successfully'**
  String get cityUpdated;

  /// No description provided for @editSponsor.
  ///
  /// In en, this message translates to:
  /// **'Edit Sponsor'**
  String get editSponsor;

  /// No description provided for @sponsorUpdated.
  ///
  /// In en, this message translates to:
  /// **'Sponsor updated successfully'**
  String get sponsorUpdated;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'community'**
  String get community;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'needHelp'**
  String get needHelp;

  /// No description provided for @viewAllDonors.
  ///
  /// In en, this message translates to:
  /// **'viewAllDonors'**
  String get viewAllDonors;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'quickActions'**
  String get quickActions;

  /// No description provided for @nearbyHospitals.
  ///
  /// In en, this message translates to:
  /// **'Nearby Blood Banks'**
  String get nearbyHospitals;

  /// No description provided for @trackNearbyHospitals.
  ///
  /// In en, this message translates to:
  /// **'Find blood banks near you'**
  String get trackNearbyHospitals;

  /// No description provided for @noHospitalsFoundInCity.
  ///
  /// In en, this message translates to:
  /// **'No hospitals found in {city}'**
  String noHospitalsFoundInCity(String city);

  /// No description provided for @callHospital.
  ///
  /// In en, this message translates to:
  /// **'Call Hospital'**
  String get callHospital;

  /// No description provided for @hospitalProfile.
  ///
  /// In en, this message translates to:
  /// **'Hospital Profile'**
  String get hospitalProfile;

  /// No description provided for @inquiryPhone.
  ///
  /// In en, this message translates to:
  /// **'Inquiry Phone'**
  String get inquiryPhone;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddress;

  /// No description provided for @updateHospitalInfo.
  ///
  /// In en, this message translates to:
  /// **'Update Hospital Information'**
  String get updateHospitalInfo;

  /// No description provided for @hospitalInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Hospital information updated successfully'**
  String get hospitalInfoUpdated;

  /// No description provided for @myCard.
  ///
  /// In en, this message translates to:
  /// **'My Card'**
  String get myCard;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @redeemLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'At least one donation is required to redeem points.'**
  String get redeemLockedMessage;

  /// No description provided for @firstDonationRequired.
  ///
  /// In en, this message translates to:
  /// **'First donation required'**
  String get firstDonationRequired;

  /// No description provided for @donationRequiredToRedeem.
  ///
  /// In en, this message translates to:
  /// **'Donation required to redeem'**
  String get donationRequiredToRedeem;

  /// No description provided for @confirm_changing_blood.
  ///
  /// In en, this message translates to:
  /// **'Changing your blood group will reset your verification status. You will need to verify it again at a hospital. Are you sure?'**
  String get confirm_changing_blood;

  /// No description provided for @stagedNotifiedCount.
  ///
  /// In en, this message translates to:
  /// **'Notifications sent to {count} compatible donors.'**
  String stagedNotifiedCount(int count);

  /// No description provided for @nextBatchAvailable.
  ///
  /// In en, this message translates to:
  /// **'Next batch available in {time}'**
  String nextBatchAvailable(String time);

  /// No description provided for @notifyMoreDonors.
  ///
  /// In en, this message translates to:
  /// **'Notify 10 More Donors'**
  String get notifyMoreDonors;

  /// No description provided for @allDonorsNotified.
  ///
  /// In en, this message translates to:
  /// **'All compatible donors notified'**
  String get allDonorsNotified;

  /// No description provided for @emergencyRequest.
  ///
  /// In en, this message translates to:
  /// **'Emergency Blood Request'**
  String get emergencyRequest;

  /// No description provided for @declineButton.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButton;

  /// No description provided for @acceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButton;

  /// No description provided for @confirmDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline Request'**
  String get confirmDeclineTitle;

  /// No description provided for @confirmDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to decline this request? This will allow other donors to help instead.'**
  String get confirmDeclineBody;

  /// No description provided for @declineSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for letting us know. We\'ve notified another donor.'**
  String get declineSuccessMessage;

  /// No description provided for @emergencyAlertsTab.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alerts'**
  String get emergencyAlertsTab;

  /// No description provided for @allClearTitle.
  ///
  /// In en, this message translates to:
  /// **'System All Clear'**
  String get allClearTitle;

  /// No description provided for @allClearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No active emergency alerts currently. Thank you for being ready to help!'**
  String get allClearSubtitle;

  /// No description provided for @viewDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetailsButton;

  /// No description provided for @requestAlreadyDeclined.
  ///
  /// In en, this message translates to:
  /// **'You have already declined this request.'**
  String get requestAlreadyDeclined;

  /// No description provided for @requestAlreadyFulfilled.
  ///
  /// In en, this message translates to:
  /// **'This request has been successfully fulfilled. Thank you!'**
  String get requestAlreadyFulfilled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
