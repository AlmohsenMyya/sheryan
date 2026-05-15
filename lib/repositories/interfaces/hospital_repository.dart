/// Abstract interface for all hospital data operations.
/// Every map returned contains an `'id'` key with the document identifier.
abstract class HospitalRepository {
  /// Live stream of every hospital, ordered by name.
  Stream<List<Map<String, dynamic>>> watchAll();

  /// Live stream of hospitals whose city matches [city].
  Stream<List<Map<String, dynamic>>> watchByCity(String city);

  /// Live count of all hospitals.
  Stream<int> watchCount();

  /// Fetches a single hospital document, returns null when not found.
  Future<Map<String, dynamic>?> getById(String id);

  /// Adds a new hospital with [name] and [city].
  Future<void> add({required String name, required String city});

  /// Updates the details of an existing hospital.
  Future<void> update(
    String id, {
    required String name,
    required String city,
    String? phone,
    String? address,
  });

  /// Permanently deletes the hospital document.
  Future<void> delete(String id);
}
