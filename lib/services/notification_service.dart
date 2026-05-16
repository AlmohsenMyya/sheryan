import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

// استيرادات التطبيق الخاصة بك (تأكد من مساراتك هنا إذا اختلفت)
import 'package:sheryan/main.dart';
import 'package:sheryan/screens/donors/request_response_screen.dart';
import 'package:sheryan/providers/emergency/emergency_provider.dart';

import '../core/models/app_notification.dart';
import '../core/utils/blood_logic.dart';
import '../l10n/app_localizations.dart';

// ملاحظة: تأكد من استيراد الموديلات (Models) مثل AppNotification و BloodLogic و NotificationType
// import 'package:sheryan/models/app_notification.dart';
// import 'package:sheryan/models/blood_logic.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📩 [FCM] Handling background message: ${message.messageId}");

  // 🛡️ [Phase A] إظهار إشعار محلي يدوياً لرسائل الـ Data-only في الخلفية
  final notificationService = NotificationService();
  await notificationService.setupLocalNotificationsForBackground();
  notificationService.showLocalNotification(message);
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _prefKeyPermissionRequested =
      "notification_permission_requested";
  static const String _prefKeyEnabled = "notification_enabled";

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
  );

  // ─── FCM Service Account ────────────────────────────────────────────────────

  Map<String, dynamic> get _serviceAccount => {
    "type": "service_account",
    "project_id": dotenv.env['FCM_PROJECT_ID'],
    "private_key_id": dotenv.env['FCM_PRIVATE_KEY_ID'],
    "private_key": dotenv.env['FCM_PRIVATE_KEY']?.replaceAll('\\n', '\n'),
    "client_email": dotenv.env['FCM_CLIENT_EMAIL'],
    "client_id": dotenv.env['FCM_CLIENT_ID'],
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40blood-f5990.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  };

  Future<String?> _getAccessToken() async {
    try {
      final account = _serviceAccount;
      if (account["private_key"] == null) {
        debugPrint("❌ [FCM] Error: FCM_PRIVATE_KEY is missing in .env");
        return null;
      }
      final client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(account),
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );
      return client.credentials.accessToken.data;
    } catch (e) {
      debugPrint("❌ [FCM] Access Token Error: $e");
      return null;
    }
  }

  // ─── Initialization & Lifecycle Hooks ───────────────────────────────────────

  Future<void> initializeNotificationHandlers() async {
    await _setupLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("🚀 [FCM] Foreground message received");
      // 🛡️ [Fix] تحديث حالة التبويب فور وصول الرسالة (بدون نقل المستخدم قسراً)
      _updateEmergencyState(message.data);
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🚀 [FCM] App opened from background notification");
      _handleRouting(message.data);
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("🚀 [FCM] App opened from terminated state");
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleRouting(initialMessage.data);
      });
    }
  }

  Future<void> init(BuildContext context) async {
    await _saveFcmToken();

    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_prefKeyEnabled) ?? true;

    if (isEnabled) {
      final alreadyRequested =
          prefs.getBool(_prefKeyPermissionRequested) ?? false;
      if (!alreadyRequested) await _requestPermissions(context);
    }
  }

  // ─── Phase B: The State Shield & Routing ────────────────────────────────────

  void _updateEmergencyState(Map<String, dynamic> data) {
    final requestId = data['requestId'] as String?;
    final type = data['type'] as String?;

    if (requestId != null && type == 'emergency') {
      // تحديث الحالة العالمية ليراها التبويب فوراً
      globalContainer.read(lastEmergencyRequestIdProvider.notifier).state = requestId;
      debugPrint("🛡️ [Shield] Emergency state updated with ID: $requestId");
    }
  }

  void _handleRouting(Map<String, dynamic> data) {
    _updateEmergencyState(data); // نضمن تحديث الحالة أولاً

    final requestId = data['requestId'] as String?;
    if (requestId != null && data['type'] == 'emergency') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => RequestResponseScreen(requestId: requestId),
        ),
      );
    }
  }

  // ─── Token Management ───────────────────────────────────────────────────────

  Future<void> _saveFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await _fcm.getToken();
      if (token != null) {
        await _fs.collection('users').doc(user.uid).update({'fcmToken': token});
        debugPrint("✅ [FCM] Token saved for ${user.uid}");
      }

      _fcm.onTokenRefresh.listen((newToken) async {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;
        await _fs.collection('users').doc(currentUser.uid).update({'fcmToken': newToken});
        debugPrint("✅ [FCM] Token refreshed for ${currentUser.uid}");
      });
    } catch (e) {
      debugPrint("⚠️ [FCM] Error saving token: $e");
    }
  }

  // ─── Local Notifications Setup ──────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings:  InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _handleRouting(data);
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> setupLocalNotificationsForBackground() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings:  InitializationSettings(android: androidInit, iOS: iosInit),
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    String? title;
    String? body;

    // 🔒 [Phase A] الدعم الكامل لرسائل الـ Data-only
    if (message.notification != null) {
      title = message.notification?.title;
      body = message.notification?.body;
    } else {
      title = message.data['titleEn'] ?? message.data['titleAr'];
      body = message.data['bodyEn'] ?? message.data['bodyAr'];
    }

    if (title != null) {
      _localNotifications.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void showLocalNotification(RemoteMessage message) => _showLocalNotification(message);

  // ─── Permissions & Preferences ──────────────────────────────────────────────

  Future<void> _requestPermissions(BuildContext context) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notificationPermissionTitle),
        content: Text(l10n.notificationPermissionBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.later)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.allow)),
        ],
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyPermissionRequested, true);
    if (allow == true) {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      await setNotificationEnabled(true);
    } else {
      await setNotificationEnabled(false);
    }
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, enabled);
  }

  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyEnabled) ?? true;
  }

  Future<void> sendUserTags({
    required String uid,
    required String city,
    required String bloodGroup,
    required String role,
  }) async {
    await _saveFcmToken();
  }

  // ─── Public Notification Methods ────────────────────────────────────────────

  /// [1] Emergency broadcast (Phase A: Pure Data Payload)
  Future<void> sendEmergencyNotification({
    required String city,
    required String bloodGroup,
    required String requestId,
    String? titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
  }) async {
    debugPrint("🔍 [FCM] Emergency broadcast for \"$bloodGroup\" in \"$city\"...");

    Query query = _fs.collection('users').where('role', isEqualTo: 'donor');

    if (city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }

    if (bloodGroup.isNotEmpty) {
      final compatibleTypes = BloodLogic.getCompatibleDonors(bloodGroup);
      query = query.where('bloodGroup', whereIn: compatibleTypes);
    }

    final donorsSnap = await query.get();

    if (donorsSnap.docs.isEmpty) {
      debugPrint("⚠️ [FCM] No compatible donors found for filters");
      return;
    }

    debugPrint("📋 [FCM] Found ${donorsSnap.docs.length} donor(s) to notify");

    final accessToken = await _getAccessToken();
    final projectId = dotenv.env['FCM_PROJECT_ID'];

    final finalTitleAr = titleAr ?? "🆘 طلب دم طارئ";
    final finalTitleEn = titleEn ?? "🆘 Emergency Blood Request";
    final finalBodyAr = bodyAr ??
        (bloodGroup.isNotEmpty && city.isNotEmpty
            ? "نداء عاجل! فصيلة $bloodGroup مطلوبة في $city. ساهم في الإنقاذ!"
            : "نداء عاجل للمساعدة في إنقاذ حياة. تفقد التفاصيل الآن!");
    final finalBodyEn = bodyEn ??
        (bloodGroup.isNotEmpty && city.isNotEmpty
            ? "Urgent! $bloodGroup blood needed in $city. Help save a life!"
            : "Urgent call for help. Check details now and help save a life!");

    final notificationData = AppNotification(
      id: '',
      titleAr: finalTitleAr,
      titleEn: finalTitleEn,
      bodyAr: finalBodyAr,
      bodyEn: finalBodyEn,
      timestamp: DateTime.now(),
      type: NotificationType.emergency,
      requestId: requestId,
    );

    final firestoreBatch = _fs.batch();
    final fcmFutures = <Future<void>>[];

    for (final donor in donorsSnap.docs) {
      final notifRef = _fs.collection('users').doc(donor.id).collection('notifications').doc();
      firestoreBatch.set(notifRef, notificationData.toMap());

      final data = donor.data() as Map<String, dynamic>?;
      final fcmToken = data?['fcmToken'] as String?;

      if (fcmToken != null && accessToken != null) {
        final message = {
          "message": {
            "token": fcmToken,
            // 🔒 [Phase A] Data-only payload. NO "notification" block.
            "data": {
              "requestId": requestId,
              "type": "emergency",
              "bloodGroup": bloodGroup,
              "titleEn": finalTitleEn,
              "titleAr": finalTitleAr,
              "bodyEn": finalBodyEn,
              "bodyAr": finalBodyAr,
              "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        };
        fcmFutures.add(_sendV1NotificationWithToken(message, accessToken, projectId!));
      }
    }

    await Future.wait([
      firestoreBatch.commit(),
      ...fcmFutures,
    ]);

    debugPrint("✅ [FCM] Emergency broadcast complete");
  }

  /// [2] Notify Hospital Admins
  Future<void> sendToHospitalAdmins({
    required String hospitalId,
    required String titleEn,
    required String titleAr,
    required String bodyEn,
    required String bodyAr,
    String? requestId,
  }) async {
    debugPrint("🔍 [FCM] Notifying admins of hospital: $hospitalId");

    final adminsSnap = await _fs
        .collection('users')
        .where('role', isEqualTo: 'hospitalAdmin')
        .where('hospitalId', isEqualTo: hospitalId)
        .get();

    if (adminsSnap.docs.isEmpty) return;

    for (final admin in adminsSnap.docs) {
      await sendDirectNotification(
        targetUid: admin.id,
        titleEn: titleEn,
        titleAr: titleAr,
        bodyEn: bodyEn,
        bodyAr: bodyAr,
        type: NotificationType.newRequest,
        requestId: requestId,
      );
    }
  }

  /// [3] Notify Matched Donor (Request Closed)
  Future<void> sendRequestClosedNotification({required String requestId}) async {
    try {
      final donationsSnap = await _fs
          .collection('donations')
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();

      if (donationsSnap.docs.isEmpty) return;

      final donorId = donationsSnap.docs.first.data()['donorId'] as String?;
      if (donorId == null) return;

      await sendDirectNotification(
        targetUid: donorId,
        titleEn: "Request Confirmed Closed ✅",
        titleAr: "تم تأكيد إغلاق الطلب ✅",
        bodyEn: "The recipient confirmed the blood request has been fulfilled. Thank you for your contribution! 🙏",
        bodyAr: "أكد صاحب الطلب اكتمال التبرع. شكراً جزيلاً لمساهمتك في إنقاذ حياة! 🙏",
        type: NotificationType.requestClosed,
        requestId: requestId,
      );
    } catch (e) {
      debugPrint("⚠️ [FCM] sendRequestClosedNotification error: $e");
    }
  }

  /// Sends Direct Push Notification
  Future<void> sendDirectNotification({
    required String targetUid,
    required String titleEn,
    required String titleAr,
    required String bodyEn,
    required String bodyAr,
    NotificationType type = NotificationType.general,
    String? requestId,
  }) async {
    debugPrint("🔍 [FCM] sendDirectNotification → $targetUid ($type)");

    final userDoc = await _fs.collection('users').doc(targetUid).get();
    final fcmToken = userDoc.data()?['fcmToken'] as String?;

    if (fcmToken != null) {
      final accessToken = await _getAccessToken();
      final projectId = dotenv.env['FCM_PROJECT_ID'];
      if (accessToken != null && projectId != null) {

        final isEmergency = type == NotificationType.emergency;

        final message = {
          "message": {
            "token": fcmToken,
            // 🔒 [Phase A] Data-only check applies here as well
            if (!isEmergency)
              "notification": {"title": titleEn, "body": bodyEn},
            "data": {
              "requestId": requestId ?? '',
              "type": type.name,
              "titleEn": titleEn,
              "titleAr": titleAr,
              "bodyEn": bodyEn,
              "bodyAr": bodyAr,
              "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        };
        await _sendV1NotificationWithToken(message, accessToken, projectId);
      }
    } else {
      debugPrint("⚠️ [FCM] No fcmToken for user $targetUid — saving to Firestore only");
    }

    await _fs
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .add(AppNotification(
      id: '',
      titleAr: titleAr,
      titleEn: titleEn,
      bodyAr: bodyAr,
      bodyEn: bodyEn,
      timestamp: DateTime.now(),
      type: type,
      requestId: requestId,
    ).toMap());
  }

  // ─── FCM HTTP v1 ─────────────────────────────────────────────────────────────

  Future<void> _sendV1NotificationWithToken(
      Map<String, dynamic> message,
      String accessToken,
      String projectId,
      ) async {
    try {
      final response = await http.post(
        Uri.parse("https://fcm.googleapis.com/v1/projects/$projectId/messages:send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(message),
      );
      if (response.statusCode == 200) {
        debugPrint("✅ [FCM] Push sent successfully");
      } else {
        debugPrint("❌ [FCM] Push failed (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ [FCM] Exception sending push: $e");
    }
  }

  // ─── Inbox Streams & Actions ─────────────────────────────────────────────────

  Stream<int> getUnreadCountStream(String userId) {
    return _fs
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _fs
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _fs.batch();
    final unread = await _fs
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> logout() async {}
}