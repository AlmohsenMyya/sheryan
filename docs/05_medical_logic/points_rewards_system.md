# نظام النقاط والمكافآت — شريان

## نظرة عامة

نظام تحفيزي كامل يكسب المتبرعون من خلاله نقاط عند إكمال ملفهم الشخصي وعند كل تبرع موثّق، ثم يستبدلون هذه النقاط بمكافآت من الجهات الراعية.

---

## مصادر النقاط

### 1. إنشاء الحساب
| الحدث | النقاط |
|---|---|
| التسجيل كمتبرع جديد | +20 نقطة |

**الملف:** `lib/screens/auth/sign_up_screen.dart`
```dart
await PointsService().addPoints(uid: uid, reason: 'signup', points: 20);
```

---

### 2. إكمال الملف الشخصي
| القسم | النقاط |
|---|---|
| المعلومات الأساسية (Basic Info) | +10 نقطة |
| الملف الصحي (Health Info) | +30 نقطة |
| السجل الطبي (Medical History) | +20 نقطة |
| جهة الطوارئ (Emergency Contact) | +20 نقطة |

**الشرط:** النقاط تُمنح مرة واحدة فقط (يُتحقق من Firestore قبل الإضافة)

**الملفات:**
- `lib/screens/profile/sections/basic_info_screen.dart`
- `lib/screens/profile/sections/health_info_screen.dart`
- `lib/screens/profile/sections/medical_history_screen.dart`
- `lib/screens/profile/sections/emergency_contact_screen.dart`

---

### 3. التبرع الموثّق
| الحدث | النقاط |
|---|---|
| تبرع عادي | +200 نقطة |
| تبرع طارئ (`isUrgent: true`) | +400 نقطة (×2 مضاعف) |
| زمرة دم نادرة (O−، AB−، B−، A−) | +100 نقطة إضافية |
| تبرع متكرر (سبق وتبرّع) | +50 نقطة استمرارية |

**الملف:** `lib/screens/hospital/hospital_dashboard.dart`

**منطق الحساب:**
```dart
int pts = 200;
if (isUrgent) pts *= 2;
if (['O-', 'AB-', 'B-', 'A-'].contains(bloodGroup)) pts += 100;
if (donorHasPreviousDonations) pts += 50;
await PointsService().addPoints(uid: donorId, reason: 'donation', points: pts);
```

---

### 4. التحقق من زمرة الدم
| الحدث | النقاط |
|---|---|
| توثيق زمرة الدم عبر QR في المستشفى | +100 نقطة |

**الملف:** `lib/screens/hospital/hospital_dashboard.dart`

---

## مستويات المتبرعين (Tiers)

| المستوى | النقاط المطلوبة | اللون |
|---|---|---|
| Bronze | 0–499 | بني `#8D6E63` |
| Silver | 500–999 | رمادي `#9E9E9E` |
| Gold | 1000–1999 | ذهبي `#FFD700` |
| Platinum | 2000+ | سماوي `#00BCD4` |

**الحساب:** يتم في `PointsService` و `_DonorManager` لوحة الأدمن.

---

## PointsService

**الملف:** `lib/services/points_service.dart`

### الدوال الرئيسية

```dart
// إضافة نقاط مع حفظ في سجل النقاط
Future<void> addPoints({
  required String uid,
  required String reason,
  required int points,
})

// جلب رصيد النقاط الحالي
Future<int> getPoints(String uid)

// جلب سجل النقاط
Stream<QuerySnapshot> getPointsHistory(String uid)
```

### Firestore Collections
- `users/{uid}/points` — رصيد النقاط الحالي
- `users/{uid}/pointsHistory/{id}` — سجل كل عملية إضافة: `{reason, points, createdAt}`

---

## واجهة عرض النقاط

**الملف:** `lib/core/utils/points_ui_utils.dart`

```dart
// يعرض SnackBar ذهبي عند كسب النقاط
showPointsGainedSnack(context, points: 200);
// → "⭐ +200 نقطة مكتسبة! 🎉"
```

---

## نظام المكافآت

### إضافة مكافأة (من Sponsor Dashboard)
الجهة الراعية تضيف مكافأة بـ:
- اسم المكافأة
- وصف
- النقاط المطلوبة للاستبدال

**Firestore:** `rewards/{id}` — الحقول: `title`, `description`, `pointsRequired`, `sponsorId`, `city`, `active`

### استبدال المكافأة
1. المتبرع يذهب للجهة الراعية ويُبيّن QR الخاص به
2. موظف الجهة الراعية يمسح QR المتبرع
3. التطبيق يتحقق من رصيد النقاط
4. عند الموافقة: تُخصم النقاط وتُحفظ عملية الاستبدال

**Firestore:** `redemptions/{id}` — الحقول: `donorId`, `rewardId`, `sponsorId`, `pointsSpent`, `createdAt`

---

## ملفات النظام

| الملف | الوظيفة |
|---|---|
| `lib/services/points_service.dart` | منطق النقاط والقراءة/الكتابة من Firestore |
| `lib/core/utils/points_ui_utils.dart` | دوال UI للإشعارات البصرية |
| `lib/screens/profile/sections/` | شاشات إكمال الملف الشخصي |
| `lib/screens/hospital/hospital_dashboard.dart` | توثيق التبرع + توثيق زمرة الدم |
| `lib/screens/auth/sign_up_screen.dart` | منح نقاط التسجيل |
| `lib/screens/sponsor/` | لوحة الجهة الراعية + استبدال المكافآت |
