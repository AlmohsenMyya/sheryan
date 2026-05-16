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
  /// Handles in-memory filtering for medical cooldowns and ranking.
  Future<void> dispatchNextBatch(String requestId) async {
    debugPrint("🚀 [StagedNotif] Starting batch dispatch for request: $requestId");

    final requestRef = _fs.collection('blood_requests').doc(requestId);

    try {
      await _fs.runTransaction((transaction) async {
        final requestDoc = await transaction.get(requestRef);
        if (!requestDoc.exists) throw Exception("Request not found");

        final requestData = requestDoc.data()!;
        
        // 🔒 [Security] Backend Cooldown Validation
        final Timestamp? lastSent = requestData['lastNotificationSentAt'];
        if (lastSent != null) {
          final DateTime now = DateTime.now();
          final DateTime cooldownExpiry = lastSent.toDate().add(const Duration(minutes: 30));
          if (now.isBefore(cooldownExpiry)) {
            final int remainingSecs = cooldownExpiry.difference(now).inSeconds;
            debugPrint("🛑 [StagedNotif] Backend Validation Failed: Cooldown active ($remainingSecs seconds left)");
            throw Exception("Cooldown active. Please wait $remainingSecs more seconds.");
          }
        }
        debugPrint("✅ [StagedNotif] Backend Validation: Cooldown check passed.");

        final String city = requestData['city'] ?? '';
        final String bloodGroup = requestData['bloodGroup'] ?? '';
        final List<dynamic> notifiedDonorIds =
            requestData['notifiedDonorIds'] ?? [];

        // 1. Fetch Candidate Pool
        final compatibleTypes = BloodLogic.getCompatibleDonors(bloodGroup);
        final allCandidates = await _userService.getCompatibleDonors(
          city: city,
          bloodGroups: compatibleTypes,
        );
        debugPrint("📊 [StagedNotif] Raw candidate pool from Firestore: ${allCandidates.length} donors");

// 2. In-Memory Filtering
        final now = DateTime.now();
        final sixtyDaysAgo = now.subtract(const Duration(days: 60));

        int excludedAlreadyNotified = 0;
        int excludedMedicalBlocker = 0;

        final eligibleCandidates = allCandidates.where((donor) {
          final String uid = donor['id'];

          if (notifiedDonorIds.contains(uid)) {
            excludedAlreadyNotified++;
            return false;
          }

          // 💡 الإصلاح هنا: قراءة الحقل كـ String وتحويله برمجياً
          final String? lastDonatedStr = donor['lastDonated'];
          if (lastDonatedStr != null && lastDonatedStr.isNotEmpty) {
            try {
              final DateTime lastDonatedDate = DateTime.parse(lastDonatedStr);
              if (lastDonatedDate.isAfter(sixtyDaysAgo)) {
                excludedMedicalBlocker++;
                return false;
              }
            } catch (e) {
              debugPrint("⚠️ [StagedNotif] Failed to parse lastDonated date for user $uid: $e");
            }
          }

          return true;
        }).toList();

        debugPrint("🧹 [StagedNotif] Filter results: Excluded $excludedAlreadyNotified (already notified), Excluded $excludedMedicalBlocker (medical blocker)");
        debugPrint("🎯 [StagedNotif] Eligible pool size: ${eligibleCandidates.length}");

        // 3. Ranking Logic
        eligibleCandidates.sort((a, b) {
          final bool aVerified = a['bloodGroupVerified'] == true;
          final bool bVerified = b['bloodGroupVerified'] == true;
          if (aVerified != bVerified) return aVerified ? -1 : 1;

          final int aPoints = a['points'] ?? 0;
          final int bPoints = b['points'] ?? 0;
          return bPoints.compareTo(aPoints); 
        });

        // 4. Select the Top 10
        final selectedBatch = eligibleCandidates.take(10).toList();
        if (selectedBatch.isEmpty) {
          debugPrint("⚠️ [StagedNotif] Dispatch aborted: No more eligible donors found.");
          return;
        }

        final List<String> newUids = selectedBatch.map((e) => e['id'] as String).toList();
        debugPrint("📦 [StagedNotif] Batch selected: ${newUids.length} donors (IDs: $newUids)");

        // 5. Atomic State Update
        transaction.update(requestRef, {
          'notifiedDonorIds': FieldValue.arrayUnion(newUids),
          'lastNotificationSentAt': FieldValue.serverTimestamp(),
          'notificationBatchCount': FieldValue.increment(1),
          'isVerified': true,
        });

        // 6. Trigger FCM v1 Pushes
        _fireNotifications(requestId, selectedBatch, bloodGroup, city);
      });
    } catch (e) {
      debugPrint("❌ [StagedNotif] Transaction aborted: $e");
      rethrow;
    }
  }

  /// Sends both Firestore Inbox notifications and direct FCM pushes.
  void _fireNotifications(
    String requestId,
    List<Map<String, dynamic>> batch,
    String bloodGroup,
    String city,
  ) {
    // Fire-and-forget background execution
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
      debugPrint("✅ [StagedNotif] Batch dispatch complete for ${batch.length} donors.");
    });
  }
}
