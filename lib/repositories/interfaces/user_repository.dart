/// Abstract interface for all user-related data operations.
/// Swap [FirebaseUserRepository] for any other implementation
/// (e.g. LaravelUserRepository) to migrate the backend without touching
/// any Service, Provider, or UI file.
abstract class UserRepository {
  /// Live stream of a user's full profile document, or null when not found.
  Stream<Map<String, dynamic>?> watchProfile(String uid);

  /// Live stream of the user's current points and tier only.
  Stream<Map<String, dynamic>> watchPoints(String uid);

  /// Live stream of the user's points history, most-recent first.
  Stream<List<Map<String, dynamic>>> watchPointsHistory(
    String uid, {
    int limit = 50,
  });

  /// Live stream of all users with [role], optionally filtered by [hospitalId].
  Stream<List<Map<String, dynamic>>> watchByRole(
    String role, {
    String? hospitalId,
    String? city,
  });

  /// Fetches a single user document, returns null when not found.
  /// The returned map always contains an `'id'` key.
  Future<Map<String, dynamic>?> getById(String uid);

  /// Returns donors whose [bloodGroup] is in [bloodGroups] and [city] matches.
  Future<List<Map<String, dynamic>>> getCompatibleDonors({
    required String city,
    required List<String> bloodGroups,
  });

  /// Merges [fields] into the user document (partial update).
  Future<void> updateFields(String uid, Map<String, dynamic> fields);

  /// Permanently deletes the user document.
  Future<void> deleteById(String uid);
}
