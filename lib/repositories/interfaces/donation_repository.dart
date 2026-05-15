/// Abstract interface for all donation-record data operations.
/// Every map returned contains an `'id'` key with the document identifier.
abstract class DonationRepository {
  /// Live stream of donations recorded at [hospitalId], newest first.
  Stream<List<Map<String, dynamic>>> watchByHospital(String hospitalId);

  /// Live count of every donation record across the platform.
  Stream<int> watchTotalCount();

  /// Atomically registers a donation:
  ///   • marks the request as done
  ///   • updates the donor's lastDonated timestamp
  ///   • writes the new donation record
  ///
  /// This is a single atomic write; a REST backend would implement it as
  /// one POST request. The Firebase implementation uses a Firestore batch.
  Future<void> registerDonationBatch({
    required String donorId,
    required String requestId,
    required String hospitalId,
    required String hospitalName,
    required String adminUid,
    bool manualOverride,
  });

  /// Atomically registers a general donation (not linked to a specific request):
  ///   • updates the donor's lastDonated timestamp
  ///   • writes the new donation record
  Future<void> registerGeneralDonationBatch({
    required String donorId,
    required String hospitalId,
    required String hospitalName,
    required String adminUid,
  });

  /// Returns the donorId for the first donation linked to [requestId],
  /// or null if none exists yet.
  Future<String?> getDonorIdForRequest(String requestId);
}
