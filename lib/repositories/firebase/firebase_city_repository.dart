import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/repositories/interfaces/city_repository.dart';

/// Firebase/Firestore implementation of [CityRepository].
class FirebaseCityRepository implements CityRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static List<Map<String, dynamic>> _fromSnap(QuerySnapshot s) => s.docs
      .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>? ?? {}})
      .toList();

  @override
  Stream<List<Map<String, dynamic>>> watchAll() =>
      _fs.collection('cities').orderBy('name').snapshots().map(_fromSnap);

  @override
  Future<void> add(String name) => _fs.collection('cities').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> update(String id, String name) =>
      _fs.collection('cities').doc(id).update({'name': name});

  @override
  Future<void> delete(String id) => _fs.collection('cities').doc(id).delete();
}
