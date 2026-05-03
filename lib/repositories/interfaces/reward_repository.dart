/// Abstract interface for sponsor reward and redemption operations.
/// Every map returned contains an `'id'` key with the document identifier.
abstract class RewardRepository {
  /// Live stream of rewards created by [sponsorId], newest first.
  Stream<List<Map<String, dynamic>>> watchBySponsor(String sponsorId);

  /// Live stream of active rewards available in [city].
  /// Pass an empty string to get rewards for all cities.
  Stream<List<Map<String, dynamic>>> watchByCity(String city);

  /// Live count of all redemptions linked to [sponsorId].
  Stream<int> watchRedemptionsCount(String sponsorId);
}
