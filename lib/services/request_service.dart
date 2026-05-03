import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sheryan/repositories/firebase/firebase_request_repository.dart';
import 'package:sheryan/repositories/interfaces/request_repository.dart';

/// Mediates all blood-request business logic.
/// Calls [RequestRepository] for every data operation — never touches
/// Firebase directly. To migrate the backend, change [FirebaseRequestRepository]
/// to any other [RequestRepository] implementation.
class RequestService {
  static final RequestService _instance = RequestService._internal();
  factory RequestService() => _instance;
  RequestService._internal();

  // ── Swap this single line to migrate backend ───────────────────────────────
  final RequestRepository _repo = FirebaseRequestRepository();
  // ──────────────────────────────────────────────────────────────────────────

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchByHospital(String hospitalId) =>
      _repo.watchByHospital(hospitalId);

  Stream<List<Map<String, dynamic>>> watchByUser(String userId) =>
      _repo.watchByUser(userId);

  /// [status] null/empty → all; 'done' → done+completed; other → exact match.
  Stream<List<Map<String, dynamic>>> watchAll({String? status}) =>
      _repo.watchAll(status: status);

  Stream<int> watchHospitalTotal(String hospitalId) =>
      _repo.watchHospitalTotal(hospitalId);

  Stream<int> watchHospitalOpen(String hospitalId) =>
      _repo.watchHospitalOpen(hospitalId);

  Stream<int> watchHospitalVerified(String hospitalId) =>
      _repo.watchHospitalVerified(hospitalId);

  Stream<int> watchHospitalFulfilled(String hospitalId) =>
      _repo.watchHospitalFulfilled(hospitalId);

  Stream<int> watchOpenCount() => _repo.watchOpenCount();

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getById(String id) => _repo.getById(id);

  // ── Writes ─────────────────────────────────────────────────────────────────

  /// Creates a new request. Automatically adds [createdAt], [status], and
  /// [isVerified] — callers must NOT include those fields in [data].
  Future<String> create(Map<String, dynamic> data) => _repo.create({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'isVerified': false,
      });

  Future<void> markVerified(String id) => _repo.markVerified(id);

  Future<void> markDone(String id) => _repo.updateStatus(id, 'done');

  Future<void> updateStatus(String id, String status) =>
      _repo.updateStatus(id, status);

  Future<void> deleteById(String id) => _repo.deleteById(id);
}
