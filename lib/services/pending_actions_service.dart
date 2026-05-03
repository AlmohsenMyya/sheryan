import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheryan/events/app_event.dart';
import 'package:sheryan/events/notification_engine.dart';
import 'package:sheryan/services/request_service.dart';

const _kPendingRequestsKey = 'sheryan_pending_blood_requests';

class PendingActionsService {
  static final PendingActionsService _instance =
      PendingActionsService._internal();
  factory PendingActionsService() => _instance;
  PendingActionsService._internal();

  Future<void> saveRequest(Map<String, dynamic> requestData) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_kPendingRequestsKey) ?? [];
    final entry = jsonEncode({
      ...requestData,
      '_savedAt': DateTime.now().toIso8601String(),
    });
    existing.add(entry);
    await prefs.setStringList(_kPendingRequestsKey, existing);
  }

  Future<int> getPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kPendingRequestsKey) ?? [];
    return list.length;
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kPendingRequestsKey) ?? [];
    return list.map((s) {
      final decoded = jsonDecode(s) as Map<String, dynamic>;
      decoded.remove('_savedAt');
      return decoded;
    }).toList();
  }

  Future<int> syncPendingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kPendingRequestsKey) ?? [];
    if (list.isEmpty) return 0;

    int synced = 0;
    final remaining = <String>[];

    for (final item in list) {
      try {
        final data = jsonDecode(item) as Map<String, dynamic>;
        data.remove('_savedAt');

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          remaining.add(item);
          continue;
        }

        final requestId = await RequestService().create({
          ...data,
          'userId': uid,
          '_syncedFromOffline': true,
        });

        NotificationEngine().dispatch(BloodRequestCreatedEvent(
          hospitalId: data['hospitalId'] ?? '',
          hospitalName: data['hospital'] ?? '',
          patientName: data['patientName'] ?? '',
          bloodGroup: data['bloodGroup'] ?? '',
          requestId: requestId,
        ));

        synced++;
      } catch (_) {
        remaining.add(item);
      }
    }

    await prefs.setStringList(_kPendingRequestsKey, remaining);
    return synced;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingRequestsKey);
  }
}
