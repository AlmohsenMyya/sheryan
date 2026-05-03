import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/repositories/interfaces/reward_repository.dart';

/// Firebase/Firestore implementation of [RewardRepository].
class FirebaseRewardRepository implements RewardRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static List<Map<String, dynamic>> _fromSnap(QuerySnapshot s) => s.docs
      .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>? ?? {}})
      .toList();

  @override
  Stream<List<Map<String, dynamic>>> watchBySponsor(String sponsorId) => _fs
      .collection('rewards')
      .where('sponsorId', isEqualTo: sponsorId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_fromSnap);

  @override
  Stream<List<Map<String, dynamic>>> watchByCity(String city) {
    Query q = _fs.collection('rewards').where('isActive', isEqualTo: true);
    if (city.isNotEmpty) q = q.where('city', isEqualTo: city);
    return q.orderBy('pointsRequired').snapshots().map(_fromSnap);
  }

  @override
  Stream<int> watchRedemptionsCount(String sponsorId) => _fs
      .collection('redemptions')
      .where('sponsorId', isEqualTo: sponsorId)
      .snapshots()
      .map((s) => s.docs.length);
}
