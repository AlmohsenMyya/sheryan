import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sheryan/core/models/app_notification.dart';
import 'package:sheryan/core/utils/blood_logic.dart';
import 'package:sheryan/services/notification_service.dart';
import 'package:sheryan/services/user_service.dart';

class StagedNotificationService {
  static final StagedNotificationService _instance =
      StagedNotificationService._internal();
  factory StagedNotificationService() => _instance;
  StagedNotificationService._internal();

  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final UserService _userService = UserService();
  final NotificationService _notifService = NotificationService();

  /// Dispatches the next batch of up to 10 donors for a specific request.
  /// Enforces a 30-minute server-side cooldown.
  /// Side-effects (FCM pushes) are executed OUTSIDE the transaction.
  Future<void> dispatchNextBatch(String requestId) async {
    debugPrint("🚀 [StagedNotif] Starting batch dispatch for request: $requestId");

    final requestRef = _fs.collection('blood_requests').doc(requestId);
    List<Map<String, dynamic>>? batchToNotify;
    String? bloodGroup;
    String? city;

    try {
      // 1. Transaction Block: Handle State and Reads only
      await _fs.runTransaction((transaction) async {
        final requestDoc = await transaction.get(requestRef);
        if (!requestDoc.exists) throw Exception("Request not found");

        final requestData = requestDoc.data()!;
        final String status = requestData['status'] ?? 'pending';
        if (status == 'done' || status == 'completed') {
          debugPrint("🛑 [StagedNotif] Dispatch aborted: Request already completed.");
          return;
        }
        
        // 🔒 [Security Shield] Backend Cooldown Validation
        final Timestamp? lastSent = requestData['lastNotificationSentAt'];
        if (lastSent != null) {
          final DateTime now = DateTime.now();
          final DateTime cooldownExpiry = lastSent.toDate().add(const Duration(minutes: 30));
          if (now.isBefore(cooldownExpiry)) {
            final int remainingSecs = cooldownExpiry.difference(now).inSeconds;
            debugPrint("🛑 [StagedNotif] Cooldown active ($remainingSecs seconds left)");
            throw Exception("Cooldown active. Please wait $remainingSecs more seconds.");
          }
        }
        debugPrint("✅ [StagedNotif] Cooldown check passed.");

        city = requestData['city'] ?? '';
        bloodGroup = requestData['bloodGroup'] ?? '';
        final List<dynamic> notifiedIds = requestData['notifiedDonorIds'] ?? [];
        final List<dynamic> declinedIds = requestData['declinedDonorIds'] ?? [];

        // Fetch Candidate Pool
        final compatibleTypes = BloodLogic.getCompatibleDonors(bloodGroup!);
        final allCandidates = await _userService.getCompatibleDonors(
          city: city!,
          bloodGroups: compatibleTypes,
        );
        debugPrint("📊 [StagedNotif] Raw candidate pool: ${allCandidates.length} donors");

        // Filtering Logic
        final now = DateTime.now();
        final sixtyDaysAgo = now.subtract(const Duration(days: 60));

        final eligibleCandidates = allCandidates.where((donor) {
          final String uid = donor['id'];
          if (notifiedIds.contains(uid) || declinedIds.contains(uid)) return false;

          final String? lastDonatedStr = donor['lastDonated'];
          if (lastDonatedStr != null && lastDonatedStr.isNotEmpty) {
            try {
              final DateTime lastDonatedDate = DateTime.parse(lastDonatedStr);
              if (lastDonatedDate.isAfter(sixtyDaysAgo)) return false;
            } catch (_) {}
          }
          return true;
        }).toList();

        // Ranking Engine
        eligibleCandidates.sort((a, b) {
          final bool aVerified = a['bloodGroupVerified'] == true;
          final bool bVerified = b['bloodGroupVerified'] == true;
          if (aVerified != bVerified) return aVerified ? -1 : 1;
          return (b['points'] ?? 0).compareTo(a['points'] ?? 0);
        });

        // Select Top 10
        final selectedBatch = eligibleCandidates.take(10).toList();
        if (selectedBatch.isEmpty) {
          debugPrint("⚠️ [StagedNotif] Pool exhausted.");
          return;
        }

        final List<String> newUids = selectedBatch.map((e) => e['id'] as String).toList();
        
        // Atomic Update
        transaction.update(requestRef, {
          'notifiedDonorIds': FieldValue.arrayUnion(newUids),
          'lastNotificationSentAt': FieldValue.serverTimestamp(),
          'notificationBatchCount': FieldValue.increment(1),
          'isVerified': true,
        });

        // Store batch for notification OUTSIDE transaction
        batchToNotify = selectedBatch;
      });

      // 2. Action Block: Trigger side-effects AFTER transaction success
      if (batchToNotify != null && batchToNotify!.isNotEmpty) {
        debugPrint("📦 [StagedNotif] Batch committed. Dispatching FCM to: ${batchToNotify!.length} donors");
        _fireBatchNotifications(requestId, batchToNotify!, bloodGroup!, city!);
      }

    } catch (e) {
      debugPrint("❌ [StagedNotif] Transaction failed: $e");
      rethrow;
    }
  }

  /// Triggered when a donor declines a slot. Replenishes by notifying the next 1 best donor.
  Future<void> declineRequestSlot(String requestId, String donorId) async {
    debugPrint("🚪 [StagedNotif] Donor $donorId declining slot for request $requestId");

    final requestRef = _fs.collection('blood_requests').doc(requestId);
    Map<String, dynamic>? replacementDonor;
    String? bloodGroup;
    String? city;

    try {
      await _fs.runTransaction((transaction) async {
        final requestDoc = await transaction.get(requestRef);
        if (!requestDoc.exists) return;

        final requestData = requestDoc.data()!;
        city = requestData['city'] ?? '';
        bloodGroup = requestData['bloodGroup'] ?? '';
        final List<dynamic> notifiedIds = requestData['notifiedDonorIds'] ?? [];
        final List<dynamic> declinedIds = requestData['declinedDonorIds'] ?? [];

        // Fetch Candidates
        final compatibleTypes = BloodLogic.getCompatibleDonors(bloodGroup!);
        final allCandidates = await _userService.getCompatibleDonors(
          city: city!,
          bloodGroups: compatibleTypes,
        );

        // Filter & Medical Blocker
        final now = DateTime.now();
        final sixtyDaysAgo = now.subtract(const Duration(days: 60));

        final eligibleCandidates = allCandidates.where((donor) {
          final String uid = donor['id'];
          if (notifiedIds.contains(uid) || declinedIds.contains(uid) || uid == donorId) return false;

          final String? lastDonatedStr = donor['lastDonated'];
          if (lastDonatedStr != null && lastDonatedStr.isNotEmpty) {
            try {
              final DateTime d = DateTime.parse(lastDonatedStr);
              if (d.isAfter(sixtyDaysAgo)) return false;
            } catch (_) {}
          }
          return true;
        }).toList();

        // Rank
        eligibleCandidates.sort((a, b) {
          final bool aV = a['bloodGroupVerified'] == true;
          final bool bV = b['bloodGroupVerified'] == true;
          if (aV != bV) return aV ? -1 : 1;
          return (b['points'] ?? 0).compareTo(a['points'] ?? 0);
        });

        final nextDonor = eligibleCandidates.isNotEmpty ? eligibleCandidates.first : null;

        final updates = <String, dynamic>{
          'declinedDonorIds': FieldValue.arrayUnion([donorId]),
        };

        if (nextDonor != null) {
          updates['notifiedDonorIds'] = FieldValue.arrayUnion([nextDonor['id']]);
          replacementDonor = nextDonor;
        }

        transaction.update(requestRef, updates);
      });

      // Trigger side-effect outside
      if (replacementDonor != null) {
        debugPrint("🔄 [StagedNotif] Replenishing slot with donor: ${replacementDonor!['id']}");
        _fireBatchNotifications(requestId, [replacementDonor!], bloodGroup!, city!);
      }

    } catch (e) {
      debugPrint("❌ [StagedNotif] Decline transaction failed: $e");
    }
  }

  void _fireBatchNotifications(
    String requestId,
    List<Map<String, dynamic>> batch,
    String bloodGroup,
    String city,
  ) {
    Future.microtask(() async {
      for (final donor in batch) {
        await _notifService.sendDirectNotification(
          targetUid: donor['id'],
          requestId: requestId,
          titleAr: "🆘 طلب دم طارئ",
          titleEn: "🆘 Emergency Blood Request",
          bodyAr: "نداء عاجل! فصيلة $bloodGroup مطلوبة في $city. ساهم في الإنقاذ!",
          bodyEn: "Urgent! $bloodGroup blood needed in $city. Help save a life!",
          type: NotificationType.emergency,
        );
      }
    });
  }
}
