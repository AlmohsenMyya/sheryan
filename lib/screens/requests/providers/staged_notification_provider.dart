import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides a real-time stream of a specific blood request document.
/// Directly uses FirebaseFirestore instance for the stream.
final requestStreamProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, requestId) {
  return FirebaseFirestore.instance
      .collection('blood_requests')
      .doc(requestId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  });
});
