import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/repositories/interfaces/donation_repository.dart';

/// Firebase/Firestore implementation of [DonationRepository].
class FirebaseDonationRepository implements DonationRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static List<Map<String, dynamic>> _fromSnap(QuerySnapshot s) => s.docs
      .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>? ?? {}})
      .toList();

  @override
  Stream<List<Map<String, dynamic>>> watchByHospital(String hospitalId) => _fs
      .collection('donations')
      .where('hospitalId', isEqualTo: hospitalId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(_fromSnap);

  @override
  Stream<int> watchTotalCount() =>
      _fs.collection('donations').snapshots().map((s) => s.docs.length);

  @override
  Future<void> registerDonationBatch({
    required String donorId,
    required String requestId,
    required String hospitalId,
    required String hospitalName,
    required String adminUid,
    bool manualOverride = false,
  }) async {
    final batch = _fs.batch();

    batch.update(
      _fs.collection('blood_requests').doc(requestId),
      {'status': 'done'},
    );

    batch.update(
      _fs.collection('users').doc(donorId),
      {'lastDonated': DateTime.now().toIso8601String()},
    );

    final donRef = _fs.collection('donations').doc();
    final donData = <String, dynamic>{
      'donorId': donorId,
      'requestId': requestId,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'timestamp': FieldValue.serverTimestamp(),
      'verifiedBy': adminUid,
      if (manualOverride) 'manualOverride': true,
    };
    batch.set(donRef, donData);

    await batch.commit();
  }

  @override
  Future<void> registerGeneralDonationBatch({
    required String donorId,
    required String hospitalId,
    required String hospitalName,
    required String adminUid,
  }) async {
    final batch = _fs.batch();

    batch.update(
      _fs.collection('users').doc(donorId),
      {'lastDonated': DateTime.now().toIso8601String()},
    );

    final donRef = _fs.collection('donations').doc();
    final donData = <String, dynamic>{
      'donorId': donorId,
      'requestId': null, // Explicitly null for general donations
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'timestamp': FieldValue.serverTimestamp(),
      'verifiedBy': adminUid,
      'type': 'general',
    };
    batch.set(donRef, donData);

    await batch.commit();
  }

  @override
  Future<String?> getDonorIdForRequest(String requestId) async {
    final snap = await _fs
        .collection('donations')
        .where('requestId', isEqualTo: requestId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data()['donorId'] as String?;
  }
}
