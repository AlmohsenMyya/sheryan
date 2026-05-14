import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheryan/core/models/app_notification.dart';
import 'package:sheryan/core/utils/blood_logic.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

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
    "private_key":
    dotenv.env['FCM_PRIVATE_KEY']?.replaceAll('\\n', '\n'),
    "client_email": dotenv.env['FCM_CLIENT_EMAIL'],
    "client_id": dotenv.env['FCM_CLIENT_ID'],
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url":
    "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
    "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40blood-f5990.iam.gserviceaccount.com",
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

  // ─── Initialization ─────────────────────────────────────────────────────────

  Future<void> init(BuildContext context) async {
    await _setupLocalNotifications();
    await _saveFcmToken();

    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_prefKeyEnabled) ?? true;

    if (isEnabled) {
      final alreadyRequested =
          prefs.getBool(_prefKeyPermissionRequested) ?? false;
      if (!alreadyRequested) await _requestPermissions(context);
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          "🚀 [FCM] Foreground message: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("🚀 [FCM] App opened from notification: ${message.data}");
    });
  }

  /// Saves (or refreshes) the device FCM token into Firestore so we can
  /// send direct notifications to this user at any time.
  Future<void> _saveFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await _fcm.getToken();
      if (token != null) {
        await _fs
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
        debugPrint("✅ [FCM] Token saved for ${user.uid}");
      }

      _fcm.onTokenRefresh.listen((newToken) async {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;
        await _fs
            .collection('users')
            .doc(currentUser.uid)
            .update({'fcmToken': newToken});
        debugPrint("✅ [FCM] Token refreshed for ${currentUser.uid}");
      });
    } catch (e) {
      debugPrint("⚠️ [FCM] Error saving token: $e");
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings:
      InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification != null && android != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
    }
  }

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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.later)),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.allow)),
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

  // ─── Preferences ────────────────────────────────────────────────────────────

  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, enabled);
  }

  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyEnabled) ?? true;
  }

  /// Called after login to refresh the FCM token in Firestore.
  /// Topic subscriptions have been removed — we use Direct FCM instead.
  Future<void> sendUserTags({
    required String uid,
    required String city,
    required String bloodGroup,
    required String role,
  }) async {
    await _saveFcmToken();
  }

  // ─── Public Notification Methods ────────────────────────────────────────────

  /// [1] Emergency broadcast: sent when a hospital admin verifies a request
  /// OR when SuperAdmin sends a filtered broadcast.
  ///
  /// If [city] is empty, it targets all cities.
  /// If [bloodGroup] is empty, it targets all blood groups.
  /// If both are empty, it targets ALL donors.
  Future<void> sendEmergencyNotification({
    required String city,
    required String bloodGroup,
    required String requestId,
    String? titleAr,
    String? titleEn,
    String? bodyAr,
    String? bodyEn,
  }) async {
    debugPrint(
        "🔍 [FCM] Emergency broadcast for \"$bloodGroup\" in \"$city\"...");

    Query query = _fs.collection('users').where('role', isEqualTo: 'donor');

    // 1. Apply City filter if provided
    if (city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }

    // 2. Apply Blood Group filter if provided (uses compatible types logic)
    if (bloodGroup.isNotEmpty) {
      final compatibleTypes = BloodLogic.getCompatibleDonors(bloodGroup);
      query = query.where('bloodGroup', whereIn: compatibleTypes);
    }

    final donorsSnap = await query.get();

    if (donorsSnap.docs.isEmpty) {
      debugPrint("⚠️ [FCM] No compatible donors found for filters");
      return;
    }

    debugPrint(
        "📋 [FCM] Found ${donorsSnap.docs.length} donor(s) to notify");

    final accessToken = await _getAccessToken();
    final projectId = dotenv.env['FCM_PROJECT_ID'];

    // If custom strings are missing, fall back to default emergency template
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

    // Batch Firestore writes + fire FCM pushes concurrently
    final firestoreBatch = _fs.batch();
    final fcmFutures = <Future>[];

    for (final donor in donorsSnap.docs) {
      // 1. Firestore in-app notification
      final notifRef = _fs
          .collection('users')
          .doc(donor.id)
          .collection('notifications')
          .doc();
      firestoreBatch.set(notifRef, notificationData.toMap());

      // 2. Direct FCM push
      // Cast the data to a Map to allow subscript access []
      final data = donor.data() as Map<String, dynamic>?;

      // Use the null-aware operator ?. to get the token
      final fcmToken = data?['fcmToken'] as String?;

      if (fcmToken != null && accessToken != null) {
        final message = {
          "message": {
            "token": fcmToken,
            "notification": {
              "title": finalTitleEn,
              "body": finalBodyEn
            },
            "data": {
              "requestId": requestId,
              "type": "emergency",
              "bloodGroup": bloodGroup,
              "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        };
        fcmFutures.add(_sendV1NotificationWithToken(
            message, accessToken, projectId!));
      }
    }
    await Future.wait([
      firestoreBatch.commit(),
      ...fcmFutures,
    ]);

    debugPrint("✅ [FCM] Emergency broadcast complete");
  }

  /// [2] Notify all hospital admins of a specific hospital.
  /// Called when a user creates a new blood request.
  Future<void> sendToHospitalAdmins({
    required String hospitalId,
    required String titleEn,
    required String titleAr,
    required String bodyEn,
    required String bodyAr,
    String? requestId,
  }) async {
    debugPrint(
        "🔍 [FCM] Notifying admins of hospital: $hospitalId");

    final adminsSnap = await _fs
        .collection('users')
        .where('role', isEqualTo: 'hospitalAdmin')
        .where('hospitalId', isEqualTo: hospitalId)
        .get();

    if (adminsSnap.docs.isEmpty) {
      debugPrint("⚠️ [FCM] No admins found for hospital $hospitalId");
      return;
    }

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
    debugPrint(
        "✅ [FCM] Notified ${adminsSnap.docs.length} admin(s)");
  }

  /// [3] Notify the matched donor when the requester manually closes a request.
  /// Looks up the donations collection to find the donor linked to this request.
  Future<void> sendRequestClosedNotification({
    required String requestId,
  }) async {
    try {
      final donationsSnap = await _fs
          .collection('donations')
          .where('requestId', isEqualTo: requestId)
          .limit(1)
          .get();

      if (donationsSnap.docs.isEmpty) return;

      final donorId =
      donationsSnap.docs.first.data()['donorId'] as String?;
      if (donorId == null) return;

      await sendDirectNotification(
        targetUid: donorId,
        titleEn: "Request Confirmed Closed ✅",
        titleAr: "تم تأكيد إغلاق الطلب ✅",
        bodyEn:
        "The recipient confirmed the blood request has been fulfilled. Thank you for your contribution! 🙏",
        bodyAr:
        "أكد صاحب الطلب اكتمال التبرع. شكراً جزيلاً لمساهمتك في إنقاذ حياة! 🙏",
        type: NotificationType.requestClosed,
        requestId: requestId,
      );
    } catch (e) {
      debugPrint("⚠️ [FCM] sendRequestClosedNotification error: $e");
    }
  }

  /// Sends a direct push notification + saves to Firestore inbox for one user.
  Future<void> sendDirectNotification({
    required String targetUid,
    required String titleEn,
    required String titleAr,
    required String bodyEn,
    required String bodyAr,
    NotificationType type = NotificationType.general,
    String? requestId,
  }) async {
    debugPrint("🔍 [FCM] sendDirectNotification → $targetUid");

    final userDoc = await _fs.collection('users').doc(targetUid).get();
    final fcmToken = userDoc.data()?['fcmToken'] as String?;

    if (fcmToken != null) {
      final accessToken = await _getAccessToken();
      final projectId = dotenv.env['FCM_PROJECT_ID'];
      if (accessToken != null && projectId != null) {
        final message = {
          "message": {
            "token": fcmToken,
            "notification": {"title": titleEn, "body": bodyEn},
            "data": {
              "requestId": requestId ?? '',
              "type": type.name,
              "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
          }
        };
        await _sendV1NotificationWithToken(
            message, accessToken, projectId);
      }
    } else {
      debugPrint(
          "⚠️ [FCM] No fcmToken for user $targetUid — saving to Firestore only");
    }

    // Always save to Firestore inbox regardless of push result
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
        Uri.parse(
            "https://fcm.googleapis.com/v1/projects/$projectId/messages:send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(message),
      );
      if (response.statusCode == 200) {
        debugPrint("✅ [FCM] Push sent successfully");
      } else {
        debugPrint(
            "❌ [FCM] Push failed (${response.statusCode}): ${response.body}");
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
