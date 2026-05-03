import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/repositories/firebase/firebase_announcement_repository.dart';
import 'package:sheryan/repositories/interfaces/announcement_repository.dart';

/// Mediates all broadcast-announcement business logic.
/// Calls [AnnouncementRepository] for every data operation — never touches
/// Firebase directly.
class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  // ── Swap this line to migrate backend ─────────────────────────────────────
  final AnnouncementRepository _repo = FirebaseAnnouncementRepository();
  // ──────────────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchRecent({int limit = 20}) =>
      _repo.watchRecent(limit: limit);

  Future<void> create({
    required String title,
    required String body,
    required String target,
    String? targetCity,
    String? targetBloodGroup,
  }) =>
      _repo.create({
        'title': title,
        'body': body,
        'target': target,
        'targetCity': targetCity,
        'targetBloodGroup': targetBloodGroup,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
