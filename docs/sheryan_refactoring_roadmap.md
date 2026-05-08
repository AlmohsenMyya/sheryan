# Sheryan (شريان) - Comprehensive Refactoring Roadmap

تستهدف هذه الخطة تحويل المشروع من هيكلية "الطبقات حسب النوع" إلى هيكلية **"المميزات أولاً" (Feature-first Architecture)** مع الالتزام الصارم بمعايير `sheryan_architectural_standards.md`.

---

## المرحلة 0: تهيئة البنية التحتية (Infrastructure)
*الهدف: تجهيز الأساسيات التي ستعتمد عليها بقية الطبقات.*

1.  **إنشاء مجلد `lib/domain`:** تعريف الـ Models الأساسية (User, Request, Donation) كـ `Immutable Classes` (يفضل باستخدام `Freezed`).
2.  **تنظيف `lib/core`:** نقل الألوان، الثيمات، والثوابت إلى مكانها الصحيح وتوحيد الوصول إليها.
3.  **تطوير `BaseRepository`:** التأكد من أن جميع الـ Repositories تتبع واجهات (Interfaces) واضحة.

---

## المرحلة 1: تحويل ميزة الهوية (Auth & Profile Feature)
*الهدف: عزل منطق المستخدم تماماً عن الواجهات.*

1.  **الـ Service:** التأكد من أن `AuthService` لا يعيد `Firebase User` بل يعيد `Domain User Model`.
2.  **الـ Provider:** إنشاء `AuthNotifier` يدير حالات (Idle, Authenticating, Authenticated, Error).
3.  **الـ UI:** تنظيف شاشات `SignIn` و `SignUp` من أي `controllers` معقدة أو `validators` برمجية صعبة، ونقلها للـ Provider.
4.  **التنظيم:** نقل الملفات إلى `lib/ui/features/auth/`.

---

## المرحلة 2: تحويل ميزة الطلبات (Blood Requests Feature)
*الهدف: جعل شاشة إنشاء الطلب "غباء" (Dumb Widget).*

1.  **الـ Provider:** إنشاء `RequestNotifier` لمعالجة:
    *   جلب قائمة المدن والمستشفيات (عبر الـ Service).
    *   التحقق من الاتصال (Connectivity).
    *   إرسال الطلب وحفظه في حالة الـ Offline.
2.  **الـ UI (Refactor `RequestBloodScreen`):**
    *   إزالة `RequestService` و `PendingActionsService` من الشاشة.
    *   الاعتماد كلياً على `ref.watch` و `ref.read` للـ Notifier.
3.  **التنظيم:** نقل الملفات إلى `lib/ui/features/requests/`.

---

## المرحلة 3: تحويل ميزة المتبرعين والخرائط (Donors Feature)
*الهدف: معالجة البيانات الجغرافية والفلترة في طبقة المنطق.*

1.  **الـ logic:** نقل منطق "البحث عن المتبرعين القريبين" من الـ `build` الخاص بـ `NearbyDonorsScreen` إلى `DonorsNotifier`.
2.  **الـ UI:** تحويل قائمة المتبرعين إلى مكونات مشتركة (`lib/ui/shared/widgets`).
3.  **التنظيم:** نقل الملفات إلى `lib/ui/features/donors/`.

---

## المرحلة 4: تحويل ميزة إدارة المستشفى (Hospital Admin Feature)
*الهدف: تأمين عمليات التوثيق المعقدة.*

1.  **الـ Logic:** إنشاء `HospitalNotifier` لإدارة عمليات مسح الـ QR والتوثيق.
2.  **الـ Persistence:** التأكد من أن الـ `Batch Commits` تتم داخل الـ `Repository` فقط، وليس في الـ UI.
3.  **التنظيم:** نقل الملفات إلى `lib/ui/features/hospital/`.

---

## المرحلة 5: تنظيم المميزات الثانوية (Points, Notifications, Awareness)
*الهدف: إكمال شجرة المجلدات النهائية.*

1.  تجميع شاشات التوعية والنقاط تحت `features/rewards/` و `features/awareness/`.
2.  تنظيف `NotificationService` ليعمل كوسيط تقني فقط، بينما يدير `NotificationNotifier` الحالة في الواجهة.

---

## المرحلة 6: المراجعة النهائية (Final Polish)
1.  حذف المجلدات القديمة (`screens`, `services` بصيغتها الحالية).
2.  التأكد من عدم وجود كلمة `Firebase` أو `Firestore` في أي ملف داخل مجلد `ui/`.
3.  تطبيق معايير التسمية الموحدة (Naming Convention) على جميع الملفات.

---
*ملاحظة: سيتم البدء في تنفيذ هذه الخطة خطوة بخطوة، مع ضمان بقاء التطبيق قابلاً للتشغيل بعد كل مرحلة.*
