/// Abstract interface for all blood-request data operations.
/// Every map returned contains an `'id'` key with the document identifier.
abstract class RequestRepository {
  /// Live stream of requests belonging to [hospitalId], newest first.
  Stream<List<Map<String, dynamic>>> watchByHospital(String hospitalId);

  /// Live stream of requests created by [userId], newest first.
  Stream<List<Map<String, dynamic>>> watchByUser(String userId);

  /// Live stream of all requests, optionally filtered by [status].
  /// When [status] is null or empty, all requests are returned.
  /// When [status] is `'done'`, documents with status in {done, completed} are returned.
  Stream<List<Map<String, dynamic>>> watchAll({String? status});

  /// Live count of every request for [hospitalId].
  Stream<int> watchHospitalTotal(String hospitalId);

  /// Live count of pending (open) requests for [hospitalId].
  Stream<int> watchHospitalOpen(String hospitalId);

  /// Live count of verified requests for [hospitalId].
  Stream<int> watchHospitalVerified(String hospitalId);

  /// Live count of fulfilled (done/completed) requests for [hospitalId].
  Stream<int> watchHospitalFulfilled(String hospitalId);

  /// Live count of all pending requests across every hospital.
  Stream<int> watchOpenCount();

  /// Fetches a single request document, returns null when not found.
  Future<Map<String, dynamic>?> getById(String id);

  /// Creates a new request and returns the generated document id.
  Future<String> create(Map<String, dynamic> data);

  /// Sets `isVerified` to true on the given request.
  Future<void> markVerified(String id);

  /// Updates the `status` field of the given request.
  Future<void> updateStatus(String id, String status);

  /// Permanently deletes the request document.
  Future<void> deleteById(String id);
}
