/// Abstract interface for broadcast announcement data operations.
/// Every map returned contains an `'id'` key with the document identifier.
abstract class AnnouncementRepository {
  /// Live stream of the most-recent [limit] announcements, newest first.
  Stream<List<Map<String, dynamic>>> watchRecent({int limit = 20});

  /// Creates a new announcement document from [data].
  Future<void> create(Map<String, dynamic> data);
}
