# Sheryan (شريان) - Architectural Standards & Best Practices Guide

هذا الملف يمثل الدستور البرمجي لمشروع "شريان"، ويهدف لنقل المشروع من مجرد تطبيق يعمل إلى نظام برمجى عالمي يتبع معايير **Clean Architecture** و **SOLID Principles**.

---

## 1. القاعدة الذهبية: فصل المسؤوليات (Separation of Concerns)

يجب ألا يعرف أي جزء من الكود أكثر مما يحتاجه للقيام بمهمته.

### أ. طبقة الواجهة (UI Layer - Dumb Widgets)
*   **القاعدة الصارمة:** الشاشات (Widgets) يجب أن تكون "غباء" (Dumb). لا يُسمح بوجود أي عمليات حسابية، أو فلترة بيانات، أو اتصال مباشر بـ Firebase داخل الـ `build` ميثود.
*   **المهمة الوحيدة:** رسم الواجهة بناءً على "الحالة" التي يوفرها الـ Provider، وتمرير أوامر المستخدم (مثل الضغط على زر) إلى الـ Provider.
*   **مثال:** بدلاً من عمل `FirebaseFirestore.instance.collection...` داخل الزر، نقوم باستدعاء `ref.read(provider.notifier).submitData()`.

### ب. طبقة إدارة الحالة (State Management - Riverpod Providers)
*   **القاعدة الصارمة:** الـ Provider هو "مدير الأوركسترا". هو يعلم "ماذا" يحدث و "متى"، لكنه لا يعلم "كيف" يتم جلب البيانات.
*   **المهمة الوحيدة:** الاحتفاظ بالحالة (State) وتحديثها. يطلب البيانات من الـ Service ويحولها إلى حالة مفهومة للواجهة (Loading, Error, Success).
*   **ممنوع:** لا تضع أكواد Firebase Messaging أو Firestore Query داخل الـ Notifier مباشرة.

### ج. طبقة البيانات (Data/Service Layer)
*   **القاعدة الصارمة:** هذا هو المكان الوحيد المسموح فيه بكتابة `http.post` أو `FirebaseFirestore`.
*   **المهمة الوحيدة:** تنفيذ العمليات التقنية الخام وإعادة البيانات (Raw Data/Models) إلى الطبقات الأعلى.

---

## 2. الهيكلية المقترحة للمجلدات (The Future Tree)

لتحقيق الترتيب العالمي، سيتم تنظيم الـ `lib` كالتالي:

```text
lib/
├── core/                # الثيم، الألوان، الثوابت، ومنطق الـ Blood Logic العام
├── data/                # كل ما يتعلق بمصدر البيانات
│   ├── models/          # الداتا موديلز (User, Request, Notification)
│   ├── repositories/    # تنفيذ الـ Interfaces (التعامل الفعلي مع Firebase)
│   └── services/        # خدمات تقنية بحتة (NotificationService, AuthService)
├── domain/              # منطق العمل الصافي (اختياري للمشاريع المعقدة)
│   └── use_cases/       # عمليات مركبة (مثل: عملية التبرع التي تشمل نقاط وإشعارات)
└── ui/                  # كل ما يراه المستخدم
    ├── shared/          # مكونات مشتركة (Custom Button, Input Field)
    └── features/        # تنظيم حسب المميزات (Feature-first)
        ├── auth/        # (Screens + Providers الخاصة بالهوية)
        ├── donations/   # (Screens + Providers الخاصة بالتبرع)
        └── notifications/
```

---

## 3. قوانين برمجية صارمة (Strict Rules)

1.  **Immutability:** يجب أن تكون جميع الـ Models عبارة عن `final fields`. لا تعدل على الموديل مباشرة، بل استخدم `copyWith`.
2.  **No Direct Firebase in UI:** أي ملف ينتهي بـ `_screen.dart` ويحتوي على كلمة `Firebase` أو `Firestore` يعتبر خرقاً للقوانين ويجب إعادة هيكلته (Refactoring).
3.  **Naming Convention:**
    *   الخدمات: `NotificationService`, `AuthService`.
    *   المستودعات: `UserRepository`, `RequestRepository`.
    *   إدارة الحالة: `AuthNotifier`, `DonationNotifier`.
4.  **Error Handling:** يجب معالجة الأخطاء في طبقة الـ Service وإعادتها كـ `Exception` مخصص أو `Result object` للـ Provider، والذي بدوره يظهرها للمستخدم.

---

## 4. خطة التحويل (Refactoring Roadmap)

سيتم العمل على تحويل الكود الحالي لهذه المعايير عبر المراحل التالية:

*   **المرحلة 1:** نقل كل ما تبقى من منطق Firebase من `HospitalDashboard` و `RequestBloodScreen` إلى `RequestService` و `DonationService`.
*   **المرحلة 2:** إعادة تنظيم مجلد `lib` ليتوافق مع الهيكلية المذكورة أعلاه (Data, UI, Core).
*   **المرحلة 3:** تحويل الـ Models لاستخدام مكتبة `Freezed` لضمان استقرار البيانات بنسبة 100%.

---
*هذا الدليل ملزم لكل تعديل كود قادم لضمان جودة مشروع "شريان".*
