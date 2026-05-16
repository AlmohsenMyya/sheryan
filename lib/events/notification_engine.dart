import 'package:flutter/foundation.dart';
import 'package:sheryan/core/models/app_notification.dart';
import 'package:sheryan/events/app_event.dart';
import 'package:sheryan/services/staged_notification_service.dart';

import '../services/notification_service.dart';

/// Central notification engine — the **only** class that calls
/// [NotificationService] for outbound push/inbox writes.
///
/// Screens and services fire domain [AppEvent]s; this engine translates
/// each event into the exact notification actions required.
///
/// Benefits:
///   • One place to change notification copy, type, or routing.
///   • Easy to add/remove notifications without touching screens.
///   • Errors are caught and logged here — callers never crash.
class NotificationEngine {
  static final NotificationEngine _instance = NotificationEngine._internal();
  factory NotificationEngine() => _instance;
  NotificationEngine._internal();

  final NotificationService _notif = NotificationService();

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Dispatch a domain event.  Fire-and-forget — errors are logged but never
  /// rethrown so that a notification failure never blocks the main action.
  Future<void> dispatch(AppEvent event) async {
    try {
      switch (event) {
        case BloodRequestCreatedEvent():
          await _onRequestCreated(event);
        case BloodRequestVerifiedEvent():
          await _onRequestVerified(event);
        case DonationRegisteredEvent():
          await _onDonationRegistered(event);
        case BloodRequestClosedEvent():
          await _onRequestClosed(event);
        case BloodGroupVerifiedEvent():
          await _onBloodGroupVerified(event);
        case AdminBroadcastEvent():
          await _onAdminBroadcast(event);
      }
    } catch (e, st) {
      debugPrint('⚠️ [NotificationEngine] ${event.runtimeType} error: $e\n$st');
    }
  }

  // ─── Handlers ──────────────────────────────────────────────────────────────

  /// Recipient created a blood request → notify all admins of that hospital.
  Future<void> _onRequestCreated(BloodRequestCreatedEvent e) async {
    debugPrint('[Engine] BloodRequestCreated → hospitalId=${e.hospitalId}');
    await _notif.sendToHospitalAdmins(
      hospitalId: e.hospitalId,
      titleEn: '🩸 New Blood Request',
      titleAr: '🩸 طلب دم جديد',
      bodyEn:
          'New request: ${e.patientName} needs ${e.bloodGroup} blood at ${e.hospitalName}. Please verify.',
      bodyAr:
          'طلب جديد: ${e.patientName} يحتاج دم فصيلة ${e.bloodGroup} في ${e.hospitalName}. يرجى التوثيق.',
      requestId: e.requestId,
    );
  }

  /// Hospital admin verified a request →
  ///   1. Direct confirmation to the requester (if known).
  ///   2. Emergency broadcast to compatible donors in the city.
  Future<void> _onRequestVerified(BloodRequestVerifiedEvent e) async {
    debugPrint(
        '[Engine] BloodRequestVerified → requestId=${e.requestId}, city=${e.city}');
    final futures = <Future>[];

    if (e.requesterId != null) {
      futures.add(
        _notif.sendDirectNotification(
          targetUid: e.requesterId!,
          titleEn: 'Request Verified! 🏥',
          titleAr: 'تم توثيق طلبك! 🏥',
          bodyEn:
              'Your blood request has been verified and broadcasted to donors.',
          bodyAr:
              'تم توثيق طلب الدم الخاص بك وتعميمه على المتبرعين.',
          type: NotificationType.verification,
          requestId: e.requestId,
        ),
      );
    }

    futures.add(
      StagedNotificationService().dispatchNextBatch(e.requestId),
    );

    await Future.wait(futures);
  }

  /// Donation registered by hospital admin →
  ///   1. Thank-you push to the donor.
  ///   2. Fulfilment confirmation to the requester (if known).
  Future<void> _onDonationRegistered(DonationRegisteredEvent e) async {
    debugPrint(
        '[Engine] DonationRegistered → donorId=${e.donorId}, requestId=${e.requestId}');
    final futures = <Future>[
      _notif.sendDirectNotification(
        targetUid: e.donorId,
        titleEn: 'Donation Successful! 🩸',
        titleAr: 'تم التبرع بنجاح! 🩸',
        bodyEn:
            'Thank you for your generous donation. You saved a life today!',
        bodyAr:
            'شكراً لعطائك. لقد ساهمت في إنقاذ حياة اليوم!',
        type: NotificationType.gratitude,
        requestId: e.requestId,
      ),
    ];

    if (e.requesterId != null) {
      futures.add(
        _notif.sendDirectNotification(
          targetUid: e.requesterId!,
          titleEn: 'Request Fulfilled! ✅',
          titleAr: 'تم تلبية طلبك! ✅',
          bodyEn:
              'Good news! A successful donation has been registered for your request.',
          bodyAr:
              'بشرى سارة! تم تسجيل عملية تبرع ناجحة لطلبك.',
          type: NotificationType.gratitude,
          requestId: e.requestId,
        ),
      );
    }

    await Future.wait(futures);
  }

  /// Recipient closed their own request → notify the matched donor.
  Future<void> _onRequestClosed(BloodRequestClosedEvent e) async {
    debugPrint('[Engine] BloodRequestClosed → requestId=${e.requestId}');
    await _notif.sendRequestClosedNotification(requestId: e.requestId);
  }

  /// Hospital admin verified a donor's blood group → confirm to the donor.
  Future<void> _onBloodGroupVerified(BloodGroupVerifiedEvent e) async {
    debugPrint('[Engine] BloodGroupVerified → donorId=${e.donorId}');
    await _notif.sendDirectNotification(
      targetUid: e.donorId,
      titleEn: 'Blood Group Verified ✅',
      titleAr: 'تم توثيق زمرة دمك ✅',
      bodyEn:
          'Your blood group (${e.bloodGroup}) has been medically verified. Your profile completion increased!',
      bodyAr:
          'تم توثيق زمرة دمك (${e.bloodGroup}) طبياً من قِبل المستشفى. اكتمال ملفك ازداد!',
      type: NotificationType.verification,
    );
  }

  /// SuperAdmin broadcast → emergency push to the target segment.
  Future<void> _onAdminBroadcast(AdminBroadcastEvent e) async {
    debugPrint(
        '[Engine] AdminBroadcast → city="${e.city}", bloodGroup="${e.bloodGroup}"');
    await _notif.sendEmergencyNotification(
      city: e.city,
      bloodGroup: e.bloodGroup,
      requestId: e.broadcastId,
      titleAr: e.titleAr,
      titleEn: e.titleEn,
      bodyAr: e.bodyAr,
      bodyEn: e.bodyEn,
    );
  }
}
