import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/repositories/interfaces/hospital_repository.dart';

/// Firebase/Firestore implementation of [HospitalRepository].
class FirebaseHospitalRepository implements HospitalRepository {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static Map<String, dynamic> _fromDoc(DocumentSnapshot d) =>
      {'id': d.id, ...d.data() as Map<String, dynamic>? ?? {}};

  static List<Map<String, dynamic>> _fromSnap(QuerySnapshot s) =>
      s.docs.map(_fromDoc).toList();

  @override
  Stream<List<Map<String, dynamic>>> watchAll() =>
      _fs.collection('hospitals').orderBy('name').snapshots().map(_fromSnap);

  @override
  Stream<List<Map<String, dynamic>>> watchByCity(String city) => _fs
      .collection('hospitals')
      .where('city', isEqualTo: city)
      .snapshots()
      .map(_fromSnap);

  @override
  Stream<int> watchCount() =>
      _fs.collection('hospitals').snapshots().map((s) => s.docs.length);

  @override
  Future<Map<String, dynamic>?> getById(String id) async {
    final d = await _fs.collection('hospitals').doc(id).get();
    return d.exists ? _fromDoc(d) : null;
  }

  @override
  Future<void> add({required String name, required String city}) =>
      _fs.collection('hospitals').add({
        'name': name,
        'city': city,
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> update(
    String id, {
    required String name,
    required String city,
  }) =>
      _fs.collection('hospitals').doc(id).update({'name': name, 'city': city});

  @override
  Future<void> delete(String id) =>
      _fs.collection('hospitals').doc(id).delete();
}
