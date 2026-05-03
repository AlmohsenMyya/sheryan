import 'package:sheryan/repositories/firebase/firebase_user_repository.dart';
import 'package:sheryan/repositories/interfaces/user_repository.dart';
import 'package:sheryan/services/points_service.dart';

/// Mediates all user-profile business logic.
/// Calls [UserRepository] for every data operation — never touches Firebase directly.
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // ── Swap this line to migrate backend ─────────────────────────────────────
  final UserRepository _repo = FirebaseUserRepository();
  // ──────────────────────────────────────────────────────────────────────────

  final PointsService _points = PointsService();

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>?> watchProfile(String uid) =>
      _repo.watchProfile(uid);

  Stream<Map<String, dynamic>> watchPoints(String uid) =>
      _repo.watchPoints(uid);

  Stream<List<Map<String, dynamic>>> watchPointsHistory(
    String uid, {
    int limit = 50,
  }) =>
      _repo.watchPointsHistory(uid, limit: limit);

  Stream<List<Map<String, dynamic>>> watchByRole(
    String role, {
    String? hospitalId,
  }) =>
      _repo.watchByRole(role, hospitalId: hospitalId);

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getById(String uid) => _repo.getById(uid);

  Future<List<Map<String, dynamic>>> getCompatibleDonors({
    required String city,
    required List<String> bloodGroups,
  }) =>
      _repo.getCompatibleDonors(city: city, bloodGroups: bloodGroups);

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<void> updateFields(String uid, Map<String, dynamic> fields) =>
      _repo.updateFields(uid, fields);

  Future<void> deleteById(String uid) => _repo.deleteById(uid);

  /// Marks the donor's blood group as medically verified and awards any
  /// applicable profile milestone points.
  Future<void> markBloodGroupVerified(String uid) async {
    await _repo.updateFields(uid, {'bloodGroupVerified': true});
    final updated = await _repo.getById(uid);
    if (updated != null) {
      await _points.checkAndAwardProfileMilestones(uid, updated);
    }
  }
}
