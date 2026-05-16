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
  /// Strictly enforces a 30-minute server-side cooldown.
  Future<void> dispatchNextBatch(String requestId) async {
    debugPrint("🚀 [StagedNotif] Starting batch dispatch for request: $requestId");

    final requestRef = _fs.collection('blood_requests').doc(requestId);

    try {
      await _fs.runTransaction((transaction) async {
        final requestDoc = await transaction.get(requestRef);
        if (!requestDoc.exists) throw Exception("Request not found");

        final requestData = requestDoc.data()!;
        
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

        final String city = requestData['city'] ?? '';
        final String bloodGroup = requestData['bloodGroup'] ?? '';
        final List<dynamic> notifiedIds = requestData['notifiedDonorIds'] ?? [];
        final List<dynamic> declinedIds = requestData['declinedDonorIds'] ?? [];

        // 1. Fetch Candidate Pool
        final compatibleTypes = BloodLogic.getCompatibleDonors(bloodGroup);
        final allCandidates = await _userService.getCompatibleDonors(
          city: city,
          bloodGroups: compatibleTypes,
        );
        debugPrint("📊 [StagedNotif] Raw candidate pool: ${allCandidates.length} donors");

        // 2. In-Memory Filtering & Medical Blocker
        final now = DateTime.now();
        final sixtyDaysAgo = now.subtract(const Duration(days: 60));

        int countExcludedHistory = 0;
        int countExcludedMedical = 0;

        final eligibleCandidates = allCandidates.where((donor) {
          final String uid = donor['id'];

          // Exclusion Filter: Already notified or explicitly declined
          if (notifiedIds.contains(uid) || declinedIds.contains(uid)) {
            countExcludedHistory++;
            return false;
          }

          // Data Integrity Fix: Parsing ISO 8601 String to DateTime
          final String? lastDonatedStr = donor['lastDonated'];
          if (lastDonatedStr != null && lastDonatedStr.isNotEmpty) {
            try {
              final DateTime lastDonatedDate = DateTime.parse(lastDonatedStr);
              if (lastDonatedDate.isAfter(sixtyDaysAgo)) {
                countExcludedMedical++;
                return false;
              }
            } catch (e) {
              debugPrint("⚠️ [StagedNotif] Parse error for user $uid: $e");
            }
          }

          return true;
        }).toList();

        debugPrint("🧹 [StagedNotif] Excluded: $countExcludedHistory (history), $countExcludedMedical (medical)");
        debugPrint("🎯 [StagedNotif] Final eligible pool: ${eligibleCandidates.length}");

        // 3. Ranking Engine
        eligibleCandidates.sort((a, b) {
          final bool aVerified = a['bloodGroupVerified'] == true;
          final bool bVerified = b['bloodGroupVerified'] == true;
          if (aVerified != bVerified) return aVerified ? -1 : 1;

          final int aPoints = a['points'] ?? 0;
          final int bPoints = b['points'] ?? 0;
          return bPoints.compareTo(aPoints); // Descending
        });

        // 4. Batch Selection (Top 10)
        final batch = eligibleCandidates.take(10).toList();
        if (batch.isEmpty) {
          debugPrint("⚠️ [StagedNotif] Dispatch aborted: Pool exhausted.");
          return;
        }

        final List<String> newUids = batch.map((e) => e['id'] as String).toList();
        debugPrint("📦 [StagedNotif] Batch selected: $newUids");

        // 5. Atomic State Update
        transaction.update(requestRef, {
          'notifiedDonorIds': FieldValue.arrayUnion(newUids),
          'lastNotificationSentAt': FieldValue.serverTimestamp(),
          'notificationBatchCount': FieldValue.increment(1),
          'isVerified': true,
        });

        // 6. Async FCM Dispatch
        _fireBatchNotifications(requestId, batch, bloodGroup, city);
      });
    } catch (e) {
      debugPrint("❌ [StagedNotif] Transaction failed: $e");
      rethrow;
    }
  }

  /// Triggered when a donor declines a slot. Replenishes by notifying the next 1 best donor.
  Future<void> declineRequestSlot(String requestId, String donorId) async {
    debugPrint("🚪 [StagedNotif] Donor $donorId declining slot for request $requestId");

    final requestRef = _fs.collection('blood_requests').doc(requestId);

    try {
      await _fs.runTransaction((transaction) async {
        final requestDoc = await transaction.get(requestRef);
        if (!requestDoc.exists) return;

        final requestData = requestDoc.data()!;
        final String city = requestData['city'] ?? '';
        final String bloodGroup = requestData['bloodGroup'] ?? '';
        final List<dynamic> notifiedIds = requestData['notifiedDonorIds'] ?? [];
        final List<dynamic> declinedIds = requestData['declinedDonorIds'] ?? [];

        // 1. Fetch Candidates
        final compatibleTypes = BloodLogic.getCompatibleDonors(bloodGroup);
        final allCandidates = await _userService.getCompatibleDonors(
          city: city,
          bloodGroups: compatibleTypes,
        );

        // 2. Filter & Medical Blocker
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

        // 3. Rank
        eligibleCandidates.sort((a, b) {
          final bool aV = a['bloodGroupVerified'] == true;
          final bool bV = b['bloodGroupVerified'] == true;
          if (aV != bV) return aV ? -1 : 1;
          return (b['points'] ?? 0).compareTo(a['points'] ?? 0);
        });

        // 4. Select Next 1
        final nextDonor = eligibleCandidates.isNotEmpty ? eligibleCandidates.first : null;

        // 5. Update: Add to declined list, and potentially add replacement to notified list
        final updates = <String, dynamic>{
          'declinedDonorIds': FieldValue.arrayUnion([donorId]),
        };

        if (nextDonor != null) {
          final String nextUid = nextDonor['id'];
          updates['notifiedDonorIds'] = FieldValue.arrayUnion([nextUid]);
          debugPrint("🔄 [StagedNotif] Replenishing slot with donor: $nextUid");
          _fireBatchNotifications(requestId, [nextDonor], bloodGroup, city);
        } else {
          debugPrint("⚠️ [StagedNotif] No replacement found for declined slot.");
        }

        transaction.update(requestRef, updates);
      });
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
