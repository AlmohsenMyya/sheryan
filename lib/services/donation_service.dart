import 'package:sheryan/repositories/firebase/firebase_donation_repository.dart';
import 'package:sheryan/repositories/firebase/firebase_request_repository.dart';
import 'package:sheryan/repositories/firebase/firebase_user_repository.dart';
import 'package:sheryan/repositories/interfaces/donation_repository.dart';
import 'package:sheryan/repositories/interfaces/request_repository.dart';
import 'package:sheryan/repositories/interfaces/user_repository.dart';
import 'package:sheryan/services/points_service.dart';

/// Mediates all donation-registration business logic.
/// Calls repositories for every data operation — never touches Firebase directly.
class DonationService {
  static final DonationService _instance = DonationService._internal();
  factory DonationService() => _instance;
  DonationService._internal();

  // ── Swap these three lines to migrate backend ──────────────────────────────
  final DonationRepository _repo = FirebaseDonationRepository();
  final RequestRepository _requestRepo = FirebaseRequestRepository();
  final UserRepository _userRepo = FirebaseUserRepository();
  // ──────────────────────────────────────────────────────────────────────────

  final PointsService _points = PointsService();

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchByHospital(String hospitalId) =>
      _repo.watchByHospital(hospitalId);

  Stream<int> watchTotalCount() => _repo.watchTotalCount();

  // ── Business logic ─────────────────────────────────────────────────────────

  /// Registers a general donation not linked to a specific request.
  Future<Map<String, dynamic>?> registerGeneralDonation({
    required String donorId,
    required String hospitalId,
    required String hospitalName,
    required String adminUid,
  }) async {
    await _repo.registerGeneralDonationBatch(
      donorId: donorId,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
      adminUid: adminUid,
    );

    final donorData = await _userRepo.getById(donorId);
    await _points.awardGeneralDonationPoints(donorId, hospitalName);

    return donorData;
  }

  /// Atomically registers a donation, then awards points to the donor.
  ///
  /// Returns a record with the updated [donorData] and [requestData] maps
  /// so that callers can dispatch the appropriate notification events.
  Future<({Map<String, dynamic>? donorData, Map<String, dynamic>? requestData})>
      registerDonation({
    required String donorId,
    required String requestId,
    required String hospitalId,
    required String hospitalName,
    required String adminUid,
    bool manualOverride = false,
  }) async {
    await _repo.registerDonationBatch(
      donorId: donorId,
      requestId: requestId,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
      adminUid: adminUid,
      manualOverride: manualOverride,
    );

    final donorData = await _userRepo.getById(donorId);
    final requestData = await _requestRepo.getById(requestId);

    final donorBloodGroup = donorData?['bloodGroup'] as String? ?? '';
    final isUrgent = requestData?['isUrgent'] == true;

    await _points.awardDonationPoints(
      donorId,
      hospitalName,
      isEmergency: isUrgent,
      donorBloodGroup: donorBloodGroup,
    );

    return (donorData: donorData, requestData: requestData);
  }
}
