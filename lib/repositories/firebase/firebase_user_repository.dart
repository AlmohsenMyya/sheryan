import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/repositories/interfaces/user_repository.dart';

/// Firebase/Firestore implementation of [UserRepository].
/// Replace with LaravelUserRepository to migrate the backend.
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _fromDoc(DocumentSnapshot d) =>
      {'id': d.id, ...d.data() as Map<String, dynamic>? ?? {}};

  static List<Map<String, dynamic>> _fromSnap(QuerySnapshot s) =>
      s.docs.map(_fromDoc).toList();

  // ── Streams ────────────────────────────────────────────────────────────────

  @override
  Stream<Map<String, dynamic>?> watchProfile(String uid) => _fs
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? _fromDoc(s) : null);

  @override
  Stream<Map<String, dynamic>> watchPoints(String uid) =>
      _fs.collection('users').doc(uid).snapshots().map((s) => {
            'points': (s.data()?['points'] as int?) ?? 0,
            'tier': (s.data()?['tier'] as String?) ?? 'bronze',
          });

  @override
  Stream<List<Map<String, dynamic>>> watchPointsHistory(
    String uid, {
    int limit = 50,
  }) =>
      _fs
          .collection('users')
          .doc(uid)
          .collection('pointsHistory')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(_fromSnap);

  @override
  Stream<List<Map<String, dynamic>>> watchByRole(
    String role, {
    String? hospitalId,
  }) {
    Query q = _fs.collection('users').where('role', isEqualTo: role);
    if (hospitalId != null) {
      q = q.where('hospitalId', isEqualTo: hospitalId);
    }
    return q.snapshots().map(_fromSnap);
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>?> getById(String uid) async {
    final d = await _fs.collection('users').doc(uid).get();
    return d.exists ? _fromDoc(d) : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getCompatibleDonors({
    required String city,
    required List<String> bloodGroups,
  }) async {
    final snap = await _fs
        .collection('users')
        .where('role', isEqualTo: 'donor')
        .where('city', isEqualTo: city)
        .where('bloodGroup', whereIn: bloodGroups)
        .get();
    return _fromSnap(snap);
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  @override
  Future<void> updateFields(String uid, Map<String, dynamic> fields) =>
      _fs.collection('users').doc(uid).update(fields);

  @override
  Future<void> deleteById(String uid) =>
      _fs.collection('users').doc(uid).delete();
}
