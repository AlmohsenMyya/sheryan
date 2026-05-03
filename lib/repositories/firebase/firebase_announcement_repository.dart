import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/repositories/interfaces/announcement_repository.dart';

/// Firebase/Firestore implementation of [AnnouncementRepository].
class FirebaseAnnouncementRepository implements AnnouncementRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static List<Map<String, dynamic>> _fromSnap(QuerySnapshot s) => s.docs
      .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>? ?? {}})
      .toList();

  @override
  Stream<List<Map<String, dynamic>>> watchRecent({int limit = 20}) => _fs
      .collection('announcements')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(_fromSnap);

  @override
  Future<void> create(Map<String, dynamic> data) =>
      _fs.collection('announcements').add(data);
}
