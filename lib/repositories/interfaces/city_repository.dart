/// Abstract interface for all city data operations.
/// Every map returned contains an `'id'` key with the document identifier.
abstract class CityRepository {
  /// Live stream of every city, ordered by name.
  Stream<List<Map<String, dynamic>>> watchAll();

  /// Adds a new city with [name].
  Future<void> add(String name);

  /// Renames an existing city document.
  Future<void> update(String id, String name);

  /// Permanently deletes the city document.
  Future<void> delete(String id);
}
