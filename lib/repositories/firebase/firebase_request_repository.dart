import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/repositories/interfaces/request_repository.dart';

/// Firebase/Firestore implementation of [RequestRepository].
class FirebaseRequestRepository implements RequestRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static Map<String, dynamic> _fromDoc(DocumentSnapshot d) =>
      {'id': d.id, ...d.data() as Map<String, dynamic>? ?? {}};

  static List<Map<String, dynamic>> _fromSnap(QuerySnapshot s) =>
      s.docs.map(_fromDoc).toList();

  Stream<int> _countQuery(Query q) =>
      q.snapshots().map((s) => s.docs.length);

  // ── Streams ────────────────────────────────────────────────────────────────

  @override
  Stream<List<Map<String, dynamic>>> watchByHospital(String hospitalId) => _fs
      .collection('blood_requests')
      .where('hospitalId', isEqualTo: hospitalId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_fromSnap);

  @override
  Stream<List<Map<String, dynamic>>> watchByUser(String userId) => _fs
      .collection('blood_requests')
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_fromSnap);

  @override
  Stream<List<Map<String, dynamic>>> watchAll({String? status}) {
    final col = _fs.collection('blood_requests');
    if (status == null || status.isEmpty) {
      return col
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(_fromSnap);
    }
    if (status == 'done') {
      return col
          .where('status', whereIn: ['done', 'completed'])
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(_fromSnap);
    }
    return col
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_fromSnap);
  }

  @override
  Stream<int> watchHospitalTotal(String hospitalId) => _countQuery(
        _fs
            .collection('blood_requests')
            .where('hospitalId', isEqualTo: hospitalId),
      );

  @override
  Stream<int> watchHospitalOpen(String hospitalId) => _countQuery(
        _fs
            .collection('blood_requests')
            .where('hospitalId', isEqualTo: hospitalId)
            .where('status', isEqualTo: 'pending'),
      );

  @override
  Stream<int> watchHospitalVerified(String hospitalId) => _countQuery(
        _fs
            .collection('blood_requests')
            .where('hospitalId', isEqualTo: hospitalId)
            .where('isVerified', isEqualTo: true),
      );

  @override
  Stream<int> watchHospitalFulfilled(String hospitalId) => _countQuery(
        _fs
            .collection('blood_requests')
            .where('hospitalId', isEqualTo: hospitalId)
            .where('status', whereIn: ['done', 'completed']),
      );

  @override
  Stream<int> watchOpenCount() => _countQuery(
        _fs
            .collection('blood_requests')
            .where('status', isEqualTo: 'pending'),
      );

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    final d = await _fs.collection('blood_requests').doc(id).get();
    return d.exists ? _fromDoc(d) : null;
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  @override
  Future<String> create(Map<String, dynamic> data) async {
    final ref = await _fs.collection('blood_requests').add(data);
    return ref.id;
  }

  @override
  Future<void> markVerified(String id) =>
      _fs.collection('blood_requests').doc(id).update({'isVerified': true});

  @override
  Future<void> updateStatus(String id, String status) =>
      _fs.collection('blood_requests').doc(id).update({'status': status});

  @override
  Future<void> deleteById(String id) =>
      _fs.collection('blood_requests').doc(id).delete();
}
