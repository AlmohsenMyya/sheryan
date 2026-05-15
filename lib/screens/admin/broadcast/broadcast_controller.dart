import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sheryan/services/announcement_service.dart';
import 'package:sheryan/events/notification_engine.dart';
import 'package:sheryan/events/app_event.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class BroadcastState {
  final bool isSending;
  BroadcastState({this.isSending = false});
}

// 1. التغيير إلى StateNotifier
class BroadcastNotifier extends StateNotifier<BroadcastState> {
  // 2. إضافة المشيّد (Constructor) وتمرير الحالة الابتدائية
  BroadcastNotifier() : super(BroadcastState());

  Future<void> sendNotification({
    required BuildContext context,
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
    required bool filterByCity,
    required bool filterByBloodGroup,
    String? targetCity,
    String? targetBloodGroup,
    required VoidCallback onSuccess,
  }) async {
    // حماية: التأكد من أن المتحكم لا يزال يعمل قبل تغيير الحالة
    if (!mounted) return;
    state = BroadcastState(isSending: true);
    final l10n = AppLocalizations.of(context)!;

    try {
      String target = 'all';
      if (filterByCity && filterByBloodGroup) {
        target = 'both';
      } else if (filterByCity) {
        target = 'city';
      } else if (filterByBloodGroup) {
        target = 'bloodGroup';
      }

      await AnnouncementService().create(
        titleAr: titleAr,
        titleEn: titleEn,
        bodyAr: bodyAr,
        bodyEn: bodyEn,
        target: target,
        targetCity: filterByCity ? targetCity : null,
        targetBloodGroup: filterByBloodGroup ? targetBloodGroup : null,
      );

      await NotificationEngine().dispatch(AdminBroadcastEvent(
        titleAr: titleAr,
        titleEn: titleEn,
        bodyAr: bodyAr,
        bodyEn: bodyEn,
        city: filterByCity ? (targetCity ?? '') : '',
        bloodGroup: filterByBloodGroup ? (targetBloodGroup ?? '') : '',
        broadcastId: 'broadcast_${DateTime.now().millisecondsSinceEpoch}',
      ));

      if (context.mounted) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.notifSent), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      // حماية: التأكد من أن المتحكم لا يزال يعمل قبل إعادة الحالة للوضع الطبيعي
      if (mounted) {
        state = BroadcastState(isSending: false);
      }
    }
  }
}

// 3. التغيير إلى StateNotifierProvider
final broadcastProvider = StateNotifierProvider.autoDispose<BroadcastNotifier, BroadcastState>((ref) {
  return BroadcastNotifier();
});