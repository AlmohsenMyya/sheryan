# Super Admin Dashboard — شريان

## نظرة عامة

لوحة السوبر أدمن هي واجهة الإدارة الكاملة لتطبيق شريان. تم إعادة تصميمها بالكامل في هذه المرحلة بتصميم عصري يستخدم `NavigationRail` كشريط تنقل جانبي مع 8 أقسام وظيفية.

---

## التصميم الجديد

### المكونات البصرية
| المكون | الوصف |
|---|---|
| `NavigationRail` | شريط جانبي يتوسع على الشاشات العريضة (> 750px) ويصغر على الضيقة |
| `_SectionHeader` | رأس لكل قسم يحتوي على أيقونة ملونة + عنوان + زر الإجراء الأساسي |
| `_StatCard` | بطاقة إحصاء مع StreamBuilder حي من Firestore |
| `_StatusBadge` | شارة ملونة لحالة الطلب (pending/verified/done) |
| `_BloodGroupBadge` | شارة زمرة الدم بلون أحمر |
| `_FilterChip` | زر تصفية بتأثير انتقالي للأقسام |
| `_EmptyState` | حالة القائمة الفارغة بأيقونة ورسالة |

### ألوان الأقسام
| القسم | اللون |
|---|---|
| نظرة عامة | أزرق `#1565C0` |
| مديرو المستشفيات | بنفسجي `#6A1B9A` |
| المستشفيات | سماوي `#00838F` |
| المدن | أخضر `#2E7D32` |
| الجهات الراعية | برتقالي `#E65100` |
| المتبرعون | أحمر `primaryRed` |
| طلبات الدم | بنفسجي `#6A1B9A` |
| الإشعارات | أصفر `#F57F17` |

---

## الأقسام الثمانية

### 0. نظرة عامة (Overview)
**الوظيفة:** لوحة إحصاء مباشرة من Firestore

**بطاقات الإحصاء:**
- إجمالي المتبرعين — `users` where `role == 'donor'`
- المستشفيات — `hospitals` collection count
- الطلبات المفتوحة — `blood_requests` where `status == 'pending'`
- التبرعات الموثّقة — `donations` collection count

**القسم السفلي:** آخر 5 إشعارات عامة مُرسَلة من collection `announcements`

---

### 1. مديرو المستشفيات
**الوظيفة:** إدارة كاملة لحسابات `hospitalAdmin`

| الإجراء | التفاصيل |
|---|---|
| إنشاء | Dialog يحتوي: الاسم، الإيميل، كلمة المرور، اختيار المستشفى |
| تعديل | تغيير الاسم وإعادة تعيين المستشفى |
| حذف | حذف من collection `users` مع حوار تأكيد |

**Firestore:** `users` where `role == 'hospitalAdmin'`

---

### 2. المستشفيات
**الوظيفة:** إضافة/تعديل/حذف المستشفيات

| الإجراء | التفاصيل |
|---|---|
| إضافة | Dialog: اسم المستشفى + اختيار المدينة |
| تعديل | تغيير الاسم والمدينة (جديد في هذه المرحلة) |
| حذف | حذف مع حوار تأكيد |

**Firestore:** `hospitals` collection — الحقول: `name`, `city`, `createdAt`

---

### 3. المدن
**الوظيفة:** إدارة قائمة المدن المتاحة في التطبيق

| الإجراء | التفاصيل |
|---|---|
| إضافة | Dialog بسيط: اسم المدينة |
| حذف | حذف مع حوار تأكيد |

**Firestore:** `cities` collection — الحقل: `name`

---

### 4. الجهات الراعية
**الوظيفة:** إنشاء وحذف حسابات `sponsorOrg`

| الإجراء | التفاصيل |
|---|---|
| إنشاء | Dialog: الاسم، الإيميل، كلمة المرور، الهاتف، المدينة |
| حذف | حذف من collection `users` مع حوار تأكيد |

**Firestore:** `users` where `role == 'sponsorOrg'`

---

### 5. المتبرعون (جديد)
**الوظيفة:** عرض جميع المتبرعين مع إمكانية البحث والفلترة والحذف

**الميزات:**
- بحث نصي بالاسم أو الإيميل (client-side)
- فلترة حسب المدينة (dropdown من collection `cities`)
- فلترة حسب زمرة الدم (8 خيارات)
- عرض: الاسم، الإيميل، المدينة، زمرة الدم (badge)، النقاط، المستوى (Bronze/Silver/Gold/Platinum)
- حذف المتبرع مع حوار تأكيد

**حساب المستوى:**
```
< 500 نقطة  → Bronze
500–999     → Silver
1000–1999   → Gold
≥ 2000      → Platinum
```

**Firestore:** `users` where `role == 'donor'`

---

### 6. طلبات الدم (جديد)
**الوظيفة:** عرض جميع طلبات الدم من كل المدن مع إمكانية الفلترة والحذف

**الميزات:**
- فلترة بالحالة: كل الحالات / Pending / Verified / Done
- عرض: اسم المريض، زمرة الدم (badge)، المستشفى، المدينة، التاريخ، الحالة (badge ملون)
- حذف طلب مزيف/منتهٍ مع حوار تأكيد

**ألوان الحالات:**
- Pending → برتقالي
- Verified → أزرق
- Done/Completed → أخضر

**Firestore:** `blood_requests` مرتبة بـ `createdAt` تنازلياً

---

### 7. الإشعارات العامة (جديد)
**الوظيفة:** إرسال إشعار لجمهور محدد

**حقول النموذج:**
- عنوان الإشعار (required)
- نص الإشعار (required، متعدد الأسطر)
- الجمهور المستهدف:
  - **جميع المستخدمين** — يُحفظ في `announcements` بدون تصفية
  - **مدينة محددة** — يُظهر dropdown المدن ويُطلق `sendEmergencyNotification(city: ...)`
  - **زمرة دم محددة** — يُظهر dropdown زمر الدم ويُطلق `sendEmergencyNotification(bloodGroup: ...)`

**عملية الإرسال:**
1. حفظ في `announcements/{id}`: `{title, body, target, targetCity, targetBloodGroup, createdAt}`
2. إطلاق `NotificationService().sendEmergencyNotification()` للأهداف المحددة
3. عرض سجل الإشعارات المرسلة (آخر 20)

**Firestore:** `announcements` collection — الحقول: `title`, `body`, `target`, `targetCity`, `targetBloodGroup`, `createdAt`

---

## مفاتيح الترجمة الجديدة (i18n)

| المفتاح | English | العربية |
|---|---|---|
| `superAdminLabel` | Super Admin | سوبر أدمن |
| `adminOverview` | Overview | نظرة عامة |
| `totalDonors` | Total Donors | إجمالي المتبرعين |
| `totalHospitals` | Hospitals | المستشفيات |
| `openRequests` | Open Requests | طلبات مفتوحة |
| `totalDonations` | Donations | التبرعات الموثّقة |
| `manageDonors` | Donors | المتبرعون |
| `allBloodRequests` | Blood Requests | طلبات الدم |
| `broadcastNotif` | Broadcast | الإشعارات |
| `donorDeleted` | Donor deleted successfully | تم حذف المتبرع بنجاح |
| `confirmDeleteBody` | This action cannot be undone. Are you sure? | لا يمكن التراجع عن هذا الإجراء. هل أنت متأكد؟ |
| `notifTitleField` | Notification Title | عنوان الإشعار |
| `notifBodyField` | Notification Message | نص الإشعار |
| `targetAudience` | Target Audience | الجمهور المستهدف |
| `targetAll` | All Users | جميع المستخدمين |
| `targetByCity` | Specific City | مدينة محددة |
| `targetByBloodGroup` | Specific Blood Group | زمرة دم محددة |
| `sendNotif` | Send Notification | إرسال الإشعار |
| `notifSent` | Notification sent successfully | تم إرسال الإشعار بنجاح |
| `allBloodGroups` | All Blood Groups | كل زمر الدم |
| `searchDonors` | Search donors... | بحث عن متبرع... |
| `editHospital` | Edit Hospital | تعديل المستشفى |
| `hospitalUpdated` | Hospital updated successfully | تم تحديث المستشفى بنجاح |
| `requestDeletedSuccess` | Request deleted successfully | تم حذف الطلب بنجاح |
| `allStatuses` | All Statuses | كل الحالات |
| `announcementHistory` | Sent Announcements | الإشعارات المرسلة |
| `noAnnouncementsYet` | No announcements sent yet | لا توجد إشعارات مرسلة بعد |

---

## الملف الرئيسي
`lib/screens/admin/admin_dashboard.dart`

جميع الأقسام موجودة في ملف واحد منظّم بتعليقات واضحة:
- `AdminDashboard` — الـ Widget الرئيسي مع NavigationRail
- `_AdminOverview` — القسم 0
- `HospitalAdminManager` — القسم 1 (public — تُستخدم في اختبارات)
- `HospitalManager` — القسم 2 (public)
- `CityManager` — القسم 3 (public)
- `SponsorOrgManager` — القسم 4 (public)
- `_DonorManager` — القسم 5 (private)
- `_BloodRequestsAdmin` — القسم 6 (private)
- `_BroadcastNotif` — القسم 7 (private)

---

## ملاحظات التقنية

- **NavigationRail توسع تلقائي:** يتوسع (`extended: true`) عند عرض الشاشة > 750px
- **الفلترة:** تتم client-side لتجنب composite Firestore indexes في المتبرعين
- **حوار الحذف:** `_confirmDelete()` هي دالة مشتركة تُستخدم في جميع الأقسام
- **الإشعارات:** تعمل على Firestore + FCM — push delivery يعتمد على اشتراك المستخدمين في FCM topics
