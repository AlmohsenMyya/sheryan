// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'شريان';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get donorDashboard => 'لوحة المتبرع';

  @override
  String get settings => 'الإعدادات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء الخير';

  @override
  String get friend => 'صديقي';

  @override
  String get motivationTitle => 'اقتباس تحفيزي';

  @override
  String get bloodGroup => 'فصيلة الدم';

  @override
  String get city => 'المدينة';

  @override
  String get usersBloodRequests => 'طلبات الدم للمستخدمين';

  @override
  String get viewAllRequestsFromUsersAcross => 'عرض جميع طلبات المستخدمين';

  @override
  String get nearbyRequests => 'الطلبات القريبة';

  @override
  String get checkNearbyBloodRequests => 'تحقق من طلبات الدم القريبة';

  @override
  String get awareness => 'التوعية';

  @override
  String get awarenessDonorSubtitle => 'نصائح وإرشادات أساسية';

  @override
  String get requestBlood => 'طلب دم';

  @override
  String get createNewBloodRequest => 'إنشاء طلب دم جديد';

  @override
  String get myRequests => 'طلباتي';

  @override
  String get trackPreviousRequests => 'تابع طلباتك السابقة';

  @override
  String get nearbyDonors => 'المتبرعون القريبون';

  @override
  String get trackNearbyDonors => 'تابع جميع المتبرعين القريبين';

  @override
  String get awarenessUserSubtitle => 'تبرع بأمان: نصائح أساسية للمتبرعين';

  @override
  String get homeTab => 'الرئيسية';

  @override
  String get donorsTab => 'المتبرعون';

  @override
  String get profileTab => 'الملف الشخصي';

  @override
  String get allDonorsTab => 'كل المتبرعين';

  @override
  String get roleWhoAreYou => 'من أنت؟';

  @override
  String get roleSelectContinue => 'اختر دورك للمتابعة';

  @override
  String get roleDonor => 'متبرع';

  @override
  String get roleDonorSubtitle => 'أريد التبرع بالدم';

  @override
  String get roleUser => 'مستخدم';

  @override
  String get roleUserSubtitle => 'أحتاج دماً أو أريد تصفح المتبرعين';

  @override
  String get alreadyHaveAccountLogin => 'لديك حساب بالفعل؟ سجل الدخول';

  @override
  String get loginEnterEmailPassword => 'أدخل البريد الإلكتروني وكلمة المرور';

  @override
  String loginFailed(String error) {
    return 'فشل تسجيل الدخول: $error';
  }

  @override
  String get welcomeBack => 'مرحباً بعودتك 👋';

  @override
  String get loginToAccount => 'سجل الدخول إلى حسابك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get dontHaveAccountSignUp => 'ليس لديك حساب؟ أنشئ حساباً';

  @override
  String get signupFillAllFields => 'يرجى تعبئة جميع الحقول';

  @override
  String get signupValidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get signupPasswordStrong =>
      'يجب أن تكون كلمة المرور 6 أحرف على الأقل وتحتوي على أحرف وأرقام';

  @override
  String get accountCreated => 'تم إنشاء الحساب';

  @override
  String get signupFailed => 'فشل إنشاء الحساب';

  @override
  String get emailAlreadyInUse => 'البريد الإلكتروني مستخدم بالفعل';

  @override
  String get createAccountTitle => 'إنشاء حساب 🩸';

  @override
  String get fillDetailsCreateAccount => 'املأ البيانات لإنشاء حساب';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phoneWithCountryCode => 'رقم الهاتف (مع رمز الدولة)';

  @override
  String get enterCityOrVillage => 'أدخل المدينة أو القرية';

  @override
  String get selectLastDonationDate => 'اختر تاريخ آخر تبرع';

  @override
  String lastDonatedOn(String date) {
    return 'آخر تبرع: $date';
  }

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get requestFillRequiredFields => 'يرجى تعبئة جميع الحقول المطلوبة';

  @override
  String get requestSubmittedSuccessfully => 'تم إرسال الطلب بنجاح';

  @override
  String requestSubmittingError(String error) {
    return 'خطأ أثناء الإرسال: $error';
  }

  @override
  String get createBloodRequest => 'إنشاء طلب دم';

  @override
  String get patientName => 'اسم المريض';

  @override
  String get hospitalName => 'اسم المستشفى';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get units => 'الوحدات';

  @override
  String get whenBloodNeededTap => 'متى تحتاج الدم؟ (اضغط للاختيار)';

  @override
  String neededAtValue(String date) {
    return 'مطلوب في: $date';
  }

  @override
  String get submitRequest => 'إرسال الطلب';

  @override
  String get notSpecified => 'غير محدد';

  @override
  String get markAsDone => 'تحديد كمكتمل';

  @override
  String get confirmRequestFulfilled => 'هل أنت متأكد أن طلب الدم تم تلبيته؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get yesDone => 'نعم، مكتمل';

  @override
  String get myBloodRequests => 'طلبات دمي';

  @override
  String get noBloodRequestsFound => 'لم يتم العثور على طلبات دم';

  @override
  String hospitalLabel(String value) {
    return '🏥 المستشفى: $value';
  }

  @override
  String cityLabel(String value) {
    return '📍 المدينة: $value';
  }

  @override
  String phoneLabel(String value) {
    return '📞 الهاتف: $value';
  }

  @override
  String unitsLabel(String value) {
    return '💉 الوحدات: $value';
  }

  @override
  String neededAtLabel(String value) {
    return '🕒 المطلوب في: $value';
  }

  @override
  String requestedOnLabel(String value) {
    return '📅 تاريخ الطلب: $value';
  }

  @override
  String get unknownPatient => 'مريض غير معروف';

  @override
  String get notAvailable => 'غير متوفر';

  @override
  String genericError(String error) {
    return 'خطأ: $error';
  }

  @override
  String get statusDone => 'مكتمل';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get account => 'الحساب';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get contactSupport => 'اتصل بالدعم';

  @override
  String get privacyLegal => 'الخصوصية والقانون';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get termsConditions => 'الشروط والأحكام';

  @override
  String get about => 'حول';

  @override
  String get aboutApp => 'حول التطبيق';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get enterCurrentPassword => 'أدخل كلمة المرور الحالية';

  @override
  String get enterNewPassword => 'أدخل كلمة المرور الجديدة';

  @override
  String get passwordUpdated => 'تم تحديث كلمة المرور بنجاح';

  @override
  String get currentPasswordIncorrect => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get forgotPassword => 'نسيت كلمة المرور';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get passwordResetSent =>
      'تم إرسال بريد إلكتروني لإعادة تعيين كلمة المرور';

  @override
  String sendResetLinkTo(String email) {
    return 'إرسال رابط إعادة التعيين إلى $email';
  }

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get confirmSignOut => 'هل أنت متأكد من تسجيل الخروج؟';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get confirmDeleteAccount =>
      'سيؤدي هذا إلى حذف حسابك وبياناتك نهائيًا. لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟';

  @override
  String get permanentlyDeleteData => 'حذف حسابك وبياناتك نهائيًا';

  @override
  String get confirmPasswordToDelete => 'أدخل كلمة المرور الحالية لحذف حسابك.';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get allRequestsDeleted => 'تم حذف جميع الطلبات بنجاح';

  @override
  String get resetAllRequests => 'إعادة تعيين جميع الطلبات';

  @override
  String get confirmResetRequests => 'هل أنت متأكد أنك تريد حذف جميع طلباتك؟';

  @override
  String get appPreferences => 'تفضيلات التطبيق';

  @override
  String get resetRequests => 'إعادة تعيين الطلبات';

  @override
  String get all => 'الكل';

  @override
  String get noPhoneNumber => 'لا يوجد رقم هاتف';

  @override
  String get cannotMakeCall => 'لا يمكن إجراء المكالمة';

  @override
  String get availableDonors => 'المتبرعون المتاحون';

  @override
  String get noDonorsFound => 'لم يتم العثور على متبرعين';

  @override
  String get unknown => 'غير معروف';

  @override
  String get quote1 =>
      '«الطريق الوحيد لربط قلوب البشر، هو ذلك المسار الأحمر الدافئ الذي يجري في عروقنا جميعاً.» — ون بيس';

  @override
  String get quote2 =>
      '«متى يموت الإنسان؟... يموت عندما ينساه الآخرون! تبرعك يخلّد أثرك.» — د. هيلولوك';

  @override
  String get quote3 =>
      '«نحن لا نستطيع العيش بدون مساعدة الآخرين... تبرع بالدم وكن سنداً لغيرك.» — مونكي دي لوفي';

  @override
  String get quote4 =>
      '«طالما أنك تتألم وتحتاج للمساعدة، فمن واجبي أن أمد لك يد العون.» — سانجي';

  @override
  String get quote5 =>
      '«لا يوجد مرض أو ألم لا يمكن تخفيفه بتكاتفنا... قطراتك تزرع الأمل.» — تشوبر';

  @override
  String get quote6 =>
      '«إذا تذكرك أحدهم يوماً، دعه يتذكرك كشخص منح الحياة بابتسامة.» — كورازون';

  @override
  String get quote7 =>
      '«طالما أننا على قيد الحياة فهناك دائمًا أمل! تبرع وامنح معجزة الحياة.» — بروك';

  @override
  String get donorDetails => 'تفاصيل المتبرع';

  @override
  String get donorNotFound => 'المتبرع غير موجود';

  @override
  String get unknownDonor => 'متبرع غير معروف';

  @override
  String bloodGroupLabel(String value) {
    return 'فصيلة الدم: $value';
  }

  @override
  String get phone => 'الهاتف';

  @override
  String get lastDonated => 'تاريخ آخر تبرع';

  @override
  String get availableToDonate => 'متاح للتبرع';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get callDonor => 'الاتصال بالمتبرع';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get profileUpdatedSuccessfully => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String get bloodDonor => 'متبرع بالدم';

  @override
  String get unknownCity => 'مدينة غير معروفة';

  @override
  String get name => 'الاسم';

  @override
  String get accountType => 'نوع الحساب';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get requiredField => 'حقل مطلوب';

  @override
  String get noNearbyRequests => 'لا توجد طلبات قريبة';

  @override
  String get call => 'اتصال';

  @override
  String get whatsapp => 'واتساب';

  @override
  String whatsappDonorMessage(String patient, String bloodGroup) {
    return 'مرحبا، تواصلت معك عبر تطبيق شريان بخصوص حالة المريض $patient. أنا فصيلتي $bloodGroup وجاهز للمساعدة، يرجى تزويدي بموقع المستشفى.';
  }

  @override
  String whatsappRecipientMessage(
    String donor,
    String bloodGroup,
    String city,
  ) {
    return 'مرحبا أخي $donor، رأيت ملفك في تطبيق شريان. نحن بحاجة ماسة لمتبرع من فصيلة $bloodGroup في مدينة $city. هل يمكنك مساعدتنا؟';
  }

  @override
  String get cannotOpenWhatsapp => 'تعذر فتح واتساب. يرجى التأكد من تثبيته.';

  @override
  String get unableToDetectCity => 'تعذر تحديد مدينتك.';

  @override
  String noDonorsFoundInCity(String city) {
    return 'لم يتم العثور على متبرعين في $city';
  }

  @override
  String get awarenessTitle => 'نصائح التبرع بالدم';

  @override
  String get tipBeforeTitle => 'قبل التبرع';

  @override
  String get tipBeforePoint1 =>
      'تناول وجبة جيدة قبل التبرع بـ 3 ساعات على الأقل.';

  @override
  String get tipBeforePoint2 => 'اشرب الكثير من الماء قبل وبعد التبرع.';

  @override
  String get tipBeforePoint3 =>
      'تجنب الكحول أو التدخين لمدة 24 ساعة قبل التبرع.';

  @override
  String get tipBeforePoint4 => 'نَم جيداً في الليلة التي تسبق التبرع.';

  @override
  String get tipDuringTitle => 'أثناء التبرع';

  @override
  String get tipDuringPoint1 => 'استرخِ وخذ أنفاساً عميقة أثناء العملية.';

  @override
  String get tipDuringPoint2 => 'اضغط على كرة الضغط برفق كما هو مطلوب.';

  @override
  String get tipDuringPoint3 =>
      'أبلغ الموظفين فوراً إذا شعرت بدوار أو عدم ارتياح.';

  @override
  String get tipAfterTitle => 'بعد التبرع';

  @override
  String get tipAfterPoint1 => 'استرح لمدة 10-15 دقيقة واستمتع بالمرطبات.';

  @override
  String get tipAfterPoint2 =>
      'تجنب التمارين الشاقة أو رفع الأثقال لبقية اليوم.';

  @override
  String get tipAfterPoint3 => 'حافظ على الضمادة لبضع ساعات.';

  @override
  String get tipAfterPoint4 => 'إذا شعرت بدوار، اجلس أو استلقِ على الفور.';

  @override
  String get tipBenefitsTitle => 'فوائد التبرع بالدم';

  @override
  String get tipBenefitsPoint1 =>
      'يساعد في إنقاذ الأرواح في حالات الطوارئ والعمليات الجراحية.';

  @override
  String get tipBenefitsPoint2 =>
      'يحسن صحة القلب من خلال توازن مستويات الحديد.';

  @override
  String get tipBenefitsPoint3 => 'يعزز إنتاج خلايا دم جديدة.';

  @override
  String get tipBenefitsPoint4 => 'يجلب الشعور بالفخر والمساهمة المجتمعية.';

  @override
  String get tipEligibilityTitle => 'الأهلية والقيود';

  @override
  String get tipEligibilityPoint1 =>
      'يجب أن يتراوح عمر المتبرعين بين 18-60 عاماً وبصحة جيدة.';

  @override
  String get tipEligibilityPoint2 => 'يجب ألا يقل الوزن الأدنى عن 50 كجم.';

  @override
  String get tipEligibilityPoint3 =>
      'تجنب التبرع إذا كنت تعاني من الحمى أو البرد أو العدوى.';

  @override
  String get tipEligibilityPoint4 =>
      'انتظر 3 أشهر على الأقل بين كل عملية تبرع.';

  @override
  String get splashSaveLives => 'إنقاذ الأرواح';

  @override
  String get splashEveryDropCounts => 'كل قطرة تهم ❤';

  @override
  String get totalRequests => 'إجمالي الطلبات';

  @override
  String get yesDelete => 'نعم، احذف';

  @override
  String get supportEmailSubject => 'دعم التطبيق - تطبيق التبرع بالدم';

  @override
  String get errorEmailApp => 'تعذر فتح تطبيق البريد الإلكتروني';

  @override
  String get fillBothPasswords => 'يرجى ملء كلا حقلي كلمة المرور';

  @override
  String get passwordMinLength =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';

  @override
  String get change => 'تغيير';

  @override
  String get noEmailFound => 'لم يتم العثور على بريد إلكتروني لهذا الحساب';

  @override
  String resetPasswordConfirm(String email) {
    return 'سيتم إرسال بريد إلكتروني لإعادة تعيين كلمة المرور إلى $email. هل تريد الاستمرار؟';
  }

  @override
  String get send => 'إرسال';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get enterPassword => 'يرجى إدخال كلمة المرور الخاصة بك';

  @override
  String get passwordIncorrect => 'كلمة المرور غير صحيحة';

  @override
  String get confirm => 'تأكيد';

  @override
  String get delete => 'حذف';

  @override
  String get reLoginRequired =>
      'يرجى إعادة تسجيل الدخول مؤخرًا والمحاولة مرة أخرى.';

  @override
  String developedBy(String name) {
    return 'تم التطوير بواسطة: $name';
  }

  @override
  String get aboutDescription =>
      'منصة شريان (Sheryan) هي منظومة رقمية متكاملة ومحصنة هندسياً، صُممت خصيصاً لإدارة عمليات التبرع بالدم وسد الفجوة بين المتبرعين والمستشفيات وطالبي الاستغاثة في أسرع وقت ممكن وبأعلى معايير الأمان الموزع.\n\nرسالتنا هي تحويل عملية إنقاذ الأرواح إلى تدفق رقمي ذكي، فوري، وموثوق بالكامل في أحلك الظروف الطارئة.\n\nتم تطوير المنصة وهندستها برمجياً بكفاءة عالية باستخدام Flutter و Firebase.\nمعاً، نصنع النبض وننقذ الأرواح — شريان يتدفق بالعطاء.';

  @override
  String get privacyPolicyContent =>
      'سياسة الخصوصية لمنصة شريان\n\nتلتزم منصة شريان لحلول التبرع بالدم الرقمية بحماية وتأمين بياناتكم الشخصية والطبية بأعلى معايير الحماية المشفرة. تشرح هذه السياسة آليات المعالجة والالتزام القانوني:\n\n1. البيانات التي يتم جمعها ومعالجتها:\n• البيانات التعريفية الأساسية: الاسم، البريد الإلكتروني، رقم الهاتف، والمدينة.\n• البيانات الحيوية والطبية: فصيلة الدم، وتاريخ آخر عملية تبرع بالدم.\n\n2. معالجة البيانات والنزاهة الطبية:\n• تُستخدم البيانات الحيوية حصرياً في مطابقة طلبات الاستغاثة وإطلاق الإشعارات المجدولة (Staged Notifications).\n• يتم قفل حقل \'تاريخ آخر تبرع\' برمجياً فور توثيق أول عملية تبرع رسمية من قبل المستشفيات الشريكة، وذلك لضمان تفعيل فترة الحظر الطبي (Cooldown Period) وحماية متلقي الدم.\n\n3. مشاركة وأمن البيانات:\n• يتم تخزين وإدارة البيانات بشكل آمن وموزع عبر بنية Firebase السحابية.\n• لا يتم بيع أو مشاركة البيانات مع أي أطراف ثالثة لأغراض تجارية. البيانات الموثقة للمستشفيات وطالبي الدم تظهر فقط لتسهيل عمليات الإنقاذ الفورية والآمنة.\n\n4. التواصل والخدمات القانونية:\n📧 Almohsen@gmail.com';

  @override
  String get termsConditionsContent =>
      'الشروط والأحكام القانونية لمنصة شريان\n\nمرحباً بكم في منصة شريان. باستخدامكم لهذا التطبيق، فإنكم توافقون بامتياز ودون قيد على الالتزام بالشروط والضوابط القانونية والطبية التالية:\n\n1. النزاهة الطبية ومسؤولية المستخدم:\n• يلتزم المستخدم بتقديم بيانات شخصية وطبية دقيقة ومطابقة للواقع بنسبة 100%.\n• يقر المتبرع بأ';

  @override
  String get showQrCode => 'عرض الرمز (QR)';

  @override
  String get donorCard => 'بطاقة المتبرع';

  @override
  String get qrCodeTitle => 'رمز التوثيق (QR)';

  @override
  String get scanToVerify =>
      'امسح هذا الرمز في المستشفى للتوثيق أو إتمام العملية';

  @override
  String get requestId => 'رقم الطلب';

  @override
  String get donorId => 'رقم المتبرع';

  @override
  String get close => 'إغلاق';

  @override
  String get hospitalAdminDashboard => 'شريان';

  @override
  String get verifyRequest => 'توثيق حالة';

  @override
  String get registerDonation => 'توثيق تبرع لحالة';

  @override
  String get registerGeneralDonation => 'تبرع عام / دوري';

  @override
  String get confirmGeneralDonationTitle => 'تأكيد تبرع عام';

  @override
  String get confirmGeneralDonationBody =>
      'هل أنت متأكد من تسجيل تبرع عام لهذا المتبرع؟ سيتم تحديث تاريخ آخر تبرع ومنحه 150 نقطة.';

  @override
  String get generalDonationSuccess => 'تم تسجيل التبرع العام بنجاح!';

  @override
  String get bloodBankStock => 'مخزون بنك الدم';

  @override
  String get scanRequestQr => 'مسح رمز الطلب';

  @override
  String get scanDonorQr => 'مسح رمز المتبرع';

  @override
  String get scanSuccess => 'تم المسح بنجاح';

  @override
  String donorDetected(String name) {
    return 'تم العثور على المتبرع: $name';
  }

  @override
  String requestDetected(String patient) {
    return 'تم العثور على طلب لـ: $patient';
  }

  @override
  String get confirmDonationTitle => 'تأكيد التبرع';

  @override
  String get confirmDonationBody =>
      'هل أنت متأكد من ربط هذا المتبرع بهذا الطلب وإغلاقه؟';

  @override
  String get verifySuccess => 'تم توثيق الطلب بنجاح!';

  @override
  String get donationSuccess => 'تم تسجيل التبرع وإغلاق الطلب!';

  @override
  String get statusUnverified => 'قيد التوثيق';

  @override
  String get statusVerified => 'موثق ونشط';

  @override
  String get statusCompleted => 'تم التبرع';

  @override
  String get invalidQr => 'رمز QR غير صحيح';

  @override
  String get waitingForDonor => 'في انتظار رمز المتبرع...';

  @override
  String get waitingForRequest => 'في انتظار رمز الطلب...';

  @override
  String get next => 'التالي';

  @override
  String get step1Of2 => 'الخطوة 1 من 2: مسح المتبرع';

  @override
  String get step2Of2 => 'الخطوة 2 من 2: مسح الطلب';

  @override
  String get incomingRequests => 'طلبات الدم الواردة';

  @override
  String get noRequestsFound => 'لا توجد طلبات واردة لمستشفاكم حالياً';

  @override
  String get invalidHospital => 'هذا الطلب تابع لمستشفى آخر!';

  @override
  String get adminDashboard => 'لوحة السوبر أدمن';

  @override
  String get manageHospitalAdmins => 'إدارة مسؤولي المستشفيات';

  @override
  String get manageCities => 'إدارة المدن';

  @override
  String get manageHospitals => 'إدارة المستشفيات';

  @override
  String get addHospital => 'إضافة مستشفى';

  @override
  String get hospitalAdded => 'تم إضافة المستشفى بنجاح!';

  @override
  String get hospitalDeleted => 'تم حذف المستشفى بنجاح!';

  @override
  String get noHospitalsFound => 'لم يتم العثور على مستشفيات';

  @override
  String get notificationPermissionTitle => 'تفعيل التنبيهات';

  @override
  String get notificationPermissionBody =>
      'قم بتفعيل التنبيهات لتصلك نداءات الاستغاثة العاجلة في مدينتك وتتابع حالة تبرعك.';

  @override
  String get allow => 'سماح';

  @override
  String get later => 'لاحقاً';

  @override
  String get selectCity => 'اختر المدينة';

  @override
  String get createAdmin => 'إنشاء حساب مسؤول مستشفى';

  @override
  String get hospitalId => 'معرف المستشفى';

  @override
  String get addCity => 'إضافة مدينة';

  @override
  String get cityName => 'اسم المدينة';

  @override
  String get cityAdded => 'تم إضافة المدينة بنجاح!';

  @override
  String get cityDeleted => 'تم حذف المدينة بنجاح!';

  @override
  String get adminCreated => 'تم إنشاء حساب المسؤول بنجاح!';

  @override
  String get adminDeleted => 'تم حذف حساب المسؤول بنجاح!';

  @override
  String get adminUpdated => 'تم تحديث حساب المسؤول بنجاح!';

  @override
  String get editAdmin => 'تعديل حساب المسؤول';

  @override
  String get noAdminsFound => 'لم يتم العثور على مسؤولين';

  @override
  String get noCitiesFound => 'لم يتم العثور على مدن';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get noNotificationsFound => 'لا توجد إشعارات حالياً';

  @override
  String get enableNotifications => 'تفعيل الإشعارات';

  @override
  String get receiveAlerts => 'استقبال تنبيهات لطلبات الاستغاثة العاجلة';

  @override
  String get testNotifications => 'اختبار الإشعارات';

  @override
  String get sendTestPush => 'إرسال إشعار تجريبي لنفسي';

  @override
  String get checkingStatus => 'جاري التحقق من حالة OneSignal...';

  @override
  String get statusSubscribed => 'مشترك';

  @override
  String get statusNotSubscribed => 'غير مشترك';

  @override
  String userId(String id) {
    return 'معرف المستخدم (الخارجي): $id';
  }

  @override
  String pushToken(String token) {
    return 'رمز الدفع (Push Token): $token';
  }

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get markAllRead => 'تحديد الكل كمقروء';

  @override
  String get notifToday => 'اليوم';

  @override
  String get notifYesterday => 'أمس';

  @override
  String get notifEarlier => 'سابقاً';

  @override
  String get notifTabEmergency => 'طوارئ';

  @override
  String get notifTabVerification => 'توثيق';

  @override
  String get notifTabDonation => 'تبرع';

  @override
  String get notifTabSystem => 'نظام';

  @override
  String get noNotificationsInTab => 'لا توجد إشعارات في هذه الفئة';

  @override
  String get profileCompletion => 'اكتمال الملف الشخصي';

  @override
  String get profileSections => 'أكمل ملفك الشخصي';

  @override
  String get completionFull => 'ملفك الشخصي مكتمل 100%!';

  @override
  String get completionGood => 'رائع! أنت قريب من الاكتمال';

  @override
  String get completionPartial => 'استمر — لقد أنجزت النصف';

  @override
  String get completionLow => 'ابدأ باكتمال ملفك الشخصي';

  @override
  String get verified => 'موثق';

  @override
  String get healthInfoTitle => 'البيانات الصحية';

  @override
  String get healthInfoSubtitle => 'الطول والوزن والجنس وحالة التدخين';

  @override
  String get medicalHistoryTitle => 'السجل الطبي';

  @override
  String get medicalHistorySubtitle => 'آخر تبرع والأمراض المزمنة والحساسية';

  @override
  String get emergencyContactTitle => 'جهة الاتصال الطارئة';

  @override
  String get emergencyContactSubtitle => 'شخص موثوق في حالات الطوارئ';

  @override
  String get emergencyContactHint =>
      'سيتم التواصل مع هذا الشخص في حالات الطوارئ خلال عملية التبرع';

  @override
  String get height => 'الطول';

  @override
  String get weight => 'الوزن';

  @override
  String get gender => 'الجنس';

  @override
  String get genderMale => 'ذكر';

  @override
  String get genderFemale => 'أنثى';

  @override
  String get smokingStatus => 'حالة التدخين';

  @override
  String get smokingNever => 'غير مدخن';

  @override
  String get smokingFormer => 'مدخن سابق';

  @override
  String get smokingCurrent => 'مدخن حالياً';

  @override
  String get chronicDiseases => 'الأمراض المزمنة';

  @override
  String get chronicDiseasesHint =>
      'مثال: السكري، ارتفاع ضغط الدم (اتركه فارغاً إن لم يوجد)';

  @override
  String get allergies => 'الحساسية';

  @override
  String get allergiesHint =>
      'مثال: البنسلين، اللاتكس (اتركه فارغاً إن لم يوجد)';

  @override
  String get noneKnown => 'اتركه فارغاً إن لم يكن هناك شيء';

  @override
  String get emergencyContactName => 'اسم جهة الاتصال';

  @override
  String get emergencyContactPhone => 'رقم هاتف جهة الاتصال';

  @override
  String get verifyDonorBloodGroup => 'توثيق زمرة دم متبرع';

  @override
  String get scanDonorQrForVerification =>
      'امسح رمز QR الخاص بالمتبرع لتوثيق زمرة دمه';

  @override
  String get bloodGroupVerificationTitle => 'توثيق زمرة الدم';

  @override
  String get confirmBloodGroupVerification => 'تأكيد التوثيق';

  @override
  String get bloodGroupVerifiedSuccess => 'تم توثيق زمرة الدم بنجاح!';

  @override
  String get bloodGroupAlreadyVerified => 'زمرة الدم موثقة مسبقاً';

  @override
  String get donationHistory => 'سجل التبرعات';

  @override
  String get donationHistoryInfo =>
      'يُملأ تلقائياً عندما يسجل مسؤول المستشفى تبرعك عبر مسح الرمز';

  @override
  String get noDonationsYet => 'لا يوجد سجل تبرعات بعد';

  @override
  String get noDonationsYetSubtitle =>
      'بمجرد أن يسجل المستشفى تبرعك، سيظهر هنا تلقائياً';

  @override
  String get donationSingular => 'تبرع';

  @override
  String get donationPlural => 'تبرعات';

  @override
  String get totalBloodDonated => 'إجمالي الدم المتبرع به';

  @override
  String get donation => 'تبرع';

  @override
  String get completed => 'مكتمل';

  @override
  String get unknownHospital => 'مستشفى غير معروف';

  @override
  String get viewDonationHistory => 'عرض سجل التبرعات';

  @override
  String get errorLoadingData => 'فشل تحميل البيانات. يرجى المحاولة مرة أخرى.';

  @override
  String get bloodCompatibilityTitle => 'دليل توافق الدم';

  @override
  String get compatCanDonateTo => 'يمكنه التبرع لـ';

  @override
  String get compatCanReceiveFrom => 'يمكنه الاستقبال من';

  @override
  String get yourBloodGroup => 'زمرة دمك';

  @override
  String get universalDonor => 'متبرع عالمي';

  @override
  String get universalRecipient => 'مستقبل عالمي';

  @override
  String get canDonateTo => 'يتبرع لـ';

  @override
  String get canReceiveFrom => 'يستقبل من';

  @override
  String get compatSummary => 'ملخص التوافق';

  @override
  String get compatNone => 'لا يوجد';

  @override
  String get viewCompatibilityGuide => 'دليل توافق الدم';

  @override
  String get offlineBannerTitle => 'أنت غير متصل بالإنترنت';

  @override
  String get offlineBannerSubtitle => 'البيانات المعروضة محفوظة مسبقاً';

  @override
  String get backOnlineMessage => 'تم استعادة الاتصال ✓';

  @override
  String offlineCachedAt(String time) {
    return 'آخر تحديث: $time';
  }

  @override
  String get requestSavedOffline =>
      'لا يوجد اتصال — سيُرسل طلبك تلقائياً عند عودة الإنترنت';

  @override
  String get pendingRequestsSynced => 'تم إرسال جميع الطلبات المعلقة بنجاح';

  @override
  String hasPendingRequests(int count) {
    return 'لديك $count طلب معلق بانتظار الإرسال';
  }

  @override
  String get offlineActionDisabled => 'هذا الإجراء يتطلب اتصالاً بالإنترنت';

  @override
  String cachedDonorsLabel(int count) {
    return 'عرض $count متبرع محفوظ';
  }

  @override
  String get basicInfoTitle => 'المعلومات الأساسية';

  @override
  String get basicInfoSubtitle =>
      'الاسم، الهاتف، المدينة، زمرة الدم، تاريخ الميلاد';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get myPoints => 'نقاطي';

  @override
  String get pointsBalance => 'نقطة';

  @override
  String get donorTier => 'المستوى';

  @override
  String get tierBronze => 'برونزي';

  @override
  String get tierSilver => 'فضي';

  @override
  String get tierGold => 'ذهبي';

  @override
  String get tierPlatinum => 'بلاتيني';

  @override
  String get pointsHistory => 'سجل النقاط';

  @override
  String get noPointsYet => 'لا توجد نقاط بعد';

  @override
  String get rewardsTab => 'اكسب نقاطك واستبدلها بمكافآت من الجهات الراعية';

  @override
  String get availableRewards => 'المكافآت المتاحة';

  @override
  String get noRewardsFound => 'لا توجد مكافآت في هذه المدينة';

  @override
  String get rewardTitle => 'اسم المكافأة';

  @override
  String get rewardDescription => 'وصف المكافأة';

  @override
  String get pointsRequired => 'النقاط المطلوبة';

  @override
  String get redeemReward => 'استبدال';

  @override
  String get notEnoughPoints => 'نقاطك غير كافية';

  @override
  String get showMyQr => 'عرض QR الخاص بي';

  @override
  String get sponsorDashboard => 'لوحة الجهة الراعية';

  @override
  String get myRewards => 'مكافآتي';

  @override
  String get addReward => 'إضافة مكافأة';

  @override
  String get editReward => 'تعديل المكافأة';

  @override
  String get deleteReward => 'حذف المكافأة';

  @override
  String get confirmDeleteReward => 'هل أنت متأكد من حذف هذه المكافأة؟';

  @override
  String get rewardSaved => 'تم حفظ المكافأة بنجاح';

  @override
  String get rewardDeleted => 'تم حذف المكافأة';

  @override
  String get noRewardsAdded => 'لم تضف أي مكافآت بعد';

  @override
  String get scanDonorQrRedeem => 'مسح QR المتبرع للاستبدال';

  @override
  String get redeemSuccess => 'تم الاستبدال بنجاح';

  @override
  String get insufficientPoints => 'نقاط المتبرع غير كافية';

  @override
  String get sponsorOrgName => 'اسم الجهة / المحل';

  @override
  String get sponsorPhone => 'رقم الهاتف';

  @override
  String get sponsorAddress => 'العنوان / الموقع';

  @override
  String get manageSponsorOrgs => 'إدارة الجهات الراعية';

  @override
  String get createSponsor => 'إنشاء جهة راعية';

  @override
  String get sponsorCreated => 'تم إنشاء الجهة الراعية بنجاح';

  @override
  String get sponsorDeleted => 'تم حذف الجهة الراعية';

  @override
  String get noSponsorsFound => 'لا توجد جهات راعية';

  @override
  String get totalRedeemed => 'إجمالي الاستبدالات';

  @override
  String get activeRewards => 'مكافآت نشطة';

  @override
  String get filterByCity => 'تصفية حسب المدينة';

  @override
  String get allCities => 'جميع المدن';

  @override
  String get superAdminLabel => 'سوبر أدمن';

  @override
  String get adminOverview => 'نظرة عامة';

  @override
  String get totalDonors => 'إجمالي المتبرعين';

  @override
  String get totalHospitals => 'المستشفيات';

  @override
  String get openRequests => 'طلبات مفتوحة';

  @override
  String get totalDonations => 'التبرعات الموثّقة';

  @override
  String get manageDonors => 'المتبرعون';

  @override
  String get allBloodRequests => 'طلبات الدم';

  @override
  String get broadcastNotif => 'الإشعارات';

  @override
  String get donorDeleted => 'تم حذف المتبرع بنجاح';

  @override
  String get confirmDeleteBody =>
      'لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟';

  @override
  String get notifTitleField => 'عنوان الإشعار';

  @override
  String get notifBodyField => 'نص الإشعار';

  @override
  String get targetAudience => 'الجمهور المستهدف';

  @override
  String get targetAll => 'جميع المستخدمين';

  @override
  String get targetByCity => 'مدينة محددة';

  @override
  String get targetByBloodGroup => 'زمرة دم محددة';

  @override
  String get sendNotif => 'إرسال الإشعار';

  @override
  String get notifSent => 'تم إرسال الإشعار بنجاح';

  @override
  String get filterByBloodGroup => 'تصفية حسب زمرة الدم';

  @override
  String get allBloodGroups => 'كل زمر الدم';

  @override
  String get searchDonors => 'بحث عن متبرع...';

  @override
  String get editHospital => 'تعديل المستشفى';

  @override
  String get hospitalUpdated => 'تم تحديث المستشفى بنجاح';

  @override
  String get requestDeletedSuccess => 'تم حذف الطلب بنجاح';

  @override
  String get allStatuses => 'كل الحالات';

  @override
  String get announcementHistory => 'الإشعارات المرسلة';

  @override
  String get noAnnouncementsYet => 'لا توجد إشعارات مرسلة بعد';

  @override
  String get requestDetails => 'تفاصيل الطلب';

  @override
  String get markAsVerified => 'تحديد كموثق';

  @override
  String get manualDonationTitle => 'تسجيل تبرع يدوي';

  @override
  String get enterDonorId => 'أدخل معرف المتبرع للبحث عنه.';

  @override
  String get urgentLabel => 'طارئ';

  @override
  String get requestDate => 'التاريخ';

  @override
  String get fulfilledLabel => 'مكتملة';

  @override
  String get verifiedLabel => 'موثقة';

  @override
  String get manualOverrideNote =>
      'رمز QR غير متاح؟ استخدم الأزرار أدناه للتحديث يدوياً.';

  @override
  String get manualBadge => 'يدوي';

  @override
  String get manageHospitalAdminsSubtitle => 'تعيين المسؤولين للمستشفيات';

  @override
  String get assignedHospital => 'المستشفى';

  @override
  String get editCity => 'تعديل المدينة';

  @override
  String get cityUpdated => 'تم تحديث المدينة بنجاح';

  @override
  String get editSponsor => 'تعديل الجهة الراعية';

  @override
  String get sponsorUpdated => 'تم تحديث الجهة الراعية بنجاح';

  @override
  String get community => 'المجتمع';

  @override
  String get needHelp => 'هل تحتاج إلى مساعدة؟';

  @override
  String get viewAllDonors => 'عرض كل المتبرعين';

  @override
  String get quickActions => 'اجراء سريع';

  @override
  String get nearbyHospitals => 'بنوك الدم القريبة';

  @override
  String get trackNearbyHospitals => 'ابحث عن بنوك الدم القريبة منك';

  @override
  String noHospitalsFoundInCity(String city) {
    return 'لم يتم العثور على مستشفيات في $city';
  }

  @override
  String get callHospital => 'اتصال بالمستشفى';

  @override
  String get hospitalProfile => 'ملف المستشفى';

  @override
  String get inquiryPhone => 'رقم الاستعلامات';

  @override
  String get fullAddress => 'العنوان التفصيلي';

  @override
  String get updateHospitalInfo => 'تحديث معلومات المستشفى';

  @override
  String get hospitalInfoUpdated => 'تم تحديث معلومات المستشفى بنجاح';

  @override
  String get myCard => 'بطاقتي';

  @override
  String get theme => 'المظهر';

  @override
  String get language => 'اللغة';

  @override
  String get redeemLockedMessage =>
      'يجب إجراء عملية تبرع واحدة على الأقل لتتمكن من استبدال النقاط.';

  @override
  String get firstDonationRequired => 'مطلوب أول تبرع';

  @override
  String get donationRequiredToRedeem => 'التبرع مطلوب للاستبدال';

  @override
  String get confirm_changing_blood =>
      'تغيير زمرة الدم سيؤدي لإلغاء التوثيق الحالي. ستحتاج للتوثيق مجدداً من المشفى. هل أنت متأكد؟';

  @override
  String stagedNotifiedCount(int count) {
    return 'تم إرسال إشعارات لـ $count متبرعين متوافقين.';
  }

  @override
  String nextBatchAvailable(String time) {
    return 'الدفعة القادمة متاحة خلال $time';
  }

  @override
  String get notifyMoreDonors => 'إخطار 10 متبرعين إضافيين';

  @override
  String get allDonorsNotified => 'تم إخطار جميع المتبرعين المتوافقين';

  @override
  String get emergencyRequest => 'طلب دم طارئ';

  @override
  String get declineButton => 'اعتذار';

  @override
  String get acceptButton => 'قبول';

  @override
  String get confirmDeclineTitle => 'تأكيد الاعتذار';

  @override
  String get confirmDeclineBody =>
      'هل أنت متأكد من الاعتذار عن هذا الطلب؟ سيتيح هذا لمتبرعين آخرين المساعدة بدلاً منك.';

  @override
  String get declineSuccessMessage =>
      'شكراً لإعلامنا. تم إخطار متبرع آخر بدلاً منك.';

  @override
  String get emergencyAlertsTab => 'نداءات الاستغاثة';

  @override
  String get allClearTitle => 'الوضع آمن';

  @override
  String get allClearSubtitle =>
      'لا توجد نداءات استغاثة نشطة حالياً، شكراً لجهوزيتك!';

  @override
  String get viewDetailsButton => 'عرض التفاصيل';

  @override
  String get requestAlreadyDeclined => 'لقد قمت بالاعتذار عن هذا الطلب مسبقاً.';

  @override
  String get requestAlreadyFulfilled =>
      'تم تأمين الدم بنجاح وإغلاق الطلب. شكراً لجهوزيتك!';

  @override
  String get invalidSyrianPhone =>
      'يرجى إدخال رقم هاتف سوري صحيح مكون من 9 أرقام';

  @override
  String get phonePrefix => '+963 ';

  @override
  String get developerProfileTitle => 'عن المطور';

  @override
  String get developerName => 'المهندس المحسن ميا';

  @override
  String get developerBio => 'مهندس البرمجيات المسؤول عن منظومة شريان';

  @override
  String get whatsappSupportMessage => 'مرحباً دعم شريان، لدي استفسار بخصوص...';

  @override
  String appVersion(String version, String build) {
    return 'الإصدار: $version ($build)';
  }

  @override
  String get contactDeveloper => 'تواصل مع المطور';

  @override
  String get visitGithub => 'زيارة GitHub';

  @override
  String get visitLinkedin => 'زيارة LinkedIn';
}
