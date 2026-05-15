import 'package:cloud_firestore/cloud_firestore.dart';

class PointsEvent {
  static const String accountCreated = 'account_created';
  static const String basicInfoComplete = 'basic_info_complete';
  static const String healthInfoComplete = 'health_info_complete';
  static const String medicalHistoryComplete = 'medical_history_complete';
  static const String emergencyContactComplete = 'emergency_contact_complete';
  static const String bloodGroupVerified = 'blood_group_verified';
  static const String profileComplete = 'profile_100_bonus';
  static const String donationRegistered = 'donation_registered';
  static const String consecutiveDonation = 'consecutive_donation_bonus';
  static const String bloodRarityBonus = 'blood_rarity_bonus';
  static const String emergencyDonationBonus = 'emergency_donation_bonus';
  static const String generalDonation = 'general_donation';
}

class PointsValue {
  static const int accountCreated = 20;
  static const int basicInfoComplete = 30;
  static const int healthInfoComplete = 30;
  static const int medicalHistoryComplete = 20;
  static const int emergencyContactComplete = 20;
  static const int bloodGroupVerified = 100;
  static const int profileComplete = 50;
  static const int donationRegistered = 200;
  static const int generalDonation = 150;
  static const int consecutiveDonation = 50;
  static const int bloodRarityBonus = 100;
  static const int emergencyDonationBonus = 200;
}

const List<String> _rareBloodTypes = ['O-', 'AB-', 'B-', 'A-'];

class PointsService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  String tierForPoints(int points) {
    if (points >= 2000) return 'platinum';
    if (points >= 1000) return 'gold';
    if (points >= 500) return 'silver';
    return 'bronze';
  }

  Future<int> getPoints(String uid) async {
    final doc = await _fs.collection('users').doc(uid).get();
    return (doc.data()?['points'] as int?) ?? 0;
  }

  Future<void> awardPoints({
    required String uid,
    required String event,
    required int points,
    required String descriptionAr,
    required String descriptionEn,
  }) async {
    final userRef = _fs.collection('users').doc(uid);
    final historyRef = userRef.collection('pointsHistory').doc();

    await _fs.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final current = (snap.data()?['points'] as int?) ?? 0;
      final newTotal = current + points;
      final tier = tierForPoints(newTotal);

      tx.update(userRef, {
        'points': newTotal, 
        'tier': tier,
        if (event == PointsEvent.donationRegistered) 'hasDonated': true,
      });
      tx.set(historyRef, {
        'event': event,
        'points': points,
        'descriptionAr': descriptionAr,
        'descriptionEn': descriptionEn,
        'total': newTotal,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<bool> hasEarnedEvent(String uid, String event) async {
    final snap = await _fs
        .collection('users')
        .doc(uid)
        .collection('pointsHistory')
        .where('event', isEqualTo: event)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> _hasPreviousDonation(String uid) async {
    final snap = await _fs
        .collection('users')
        .doc(uid)
        .collection('pointsHistory')
        .where('event', isEqualTo: PointsEvent.donationRegistered)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Awards profile milestone points and returns total points awarded this call.
  Future<int> checkAndAwardProfileMilestones(
      String uid, Map<String, dynamic> profile) async {
    int totalAwarded = 0;

    final bool basic = _basicComplete(profile);
    final bool health = _healthComplete(profile);
    final bool medical = _medicalComplete(profile);
    final bool emergency = _emergencyComplete(profile);
    final bool verified = profile['bloodGroupVerified'] == true;

    if (basic && !await hasEarnedEvent(uid, PointsEvent.basicInfoComplete)) {
      await awardPoints(
        uid: uid,
        event: PointsEvent.basicInfoComplete,
        points: PointsValue.basicInfoComplete,
        descriptionAr: 'اكتمال المعلومات الأساسية',
        descriptionEn: 'Basic info completed',
      );
      totalAwarded += PointsValue.basicInfoComplete;
    }

    if (health && !await hasEarnedEvent(uid, PointsEvent.healthInfoComplete)) {
      await awardPoints(
        uid: uid,
        event: PointsEvent.healthInfoComplete,
        points: PointsValue.healthInfoComplete,
        descriptionAr: 'اكتمال البيانات الصحية',
        descriptionEn: 'Health info completed',
      );
      totalAwarded += PointsValue.healthInfoComplete;
    }

    if (medical &&
        !await hasEarnedEvent(uid, PointsEvent.medicalHistoryComplete)) {
      await awardPoints(
        uid: uid,
        event: PointsEvent.medicalHistoryComplete,
        points: PointsValue.medicalHistoryComplete,
        descriptionAr: 'اكتمال السجل الطبي',
        descriptionEn: 'Medical history completed',
      );
      totalAwarded += PointsValue.medicalHistoryComplete;
    }

    if (emergency &&
        !await hasEarnedEvent(uid, PointsEvent.emergencyContactComplete)) {
      await awardPoints(
        uid: uid,
        event: PointsEvent.emergencyContactComplete,
        points: PointsValue.emergencyContactComplete,
        descriptionAr: 'اكتمال جهة الاتصال الطارئة',
        descriptionEn: 'Emergency contact completed',
      );
      totalAwarded += PointsValue.emergencyContactComplete;
    }

    if (verified &&
        !await hasEarnedEvent(uid, PointsEvent.bloodGroupVerified)) {
      await awardPoints(
        uid: uid,
        event: PointsEvent.bloodGroupVerified,
        points: PointsValue.bloodGroupVerified,
        descriptionAr: 'توثيق زمرة الدم',
        descriptionEn: 'Blood group verified',
      );
      totalAwarded += PointsValue.bloodGroupVerified;
    }

    if (basic &&
        health &&
        medical &&
        emergency &&
        verified &&
        !await hasEarnedEvent(uid, PointsEvent.profileComplete)) {
      await awardPoints(
        uid: uid,
        event: PointsEvent.profileComplete,
        points: PointsValue.profileComplete,
        descriptionAr: 'مكافأة إكمال الملف 100%',
        descriptionEn: '100% profile completion bonus',
      );
      totalAwarded += PointsValue.profileComplete;
    }

    return totalAwarded;
  }

  /// Awards points for a general periodic donation (150 pts).
  Future<void> awardGeneralDonationPoints(String uid, String hospitalName) async {
    await awardPoints(
      uid: uid,
      event: PointsEvent.generalDonation,
      points: PointsValue.generalDonation,
      descriptionAr: 'تبرع دوري عام - $hospitalName',
      descriptionEn: 'General periodic donation - $hospitalName',
    );
  }

  /// Awards points for a verified donation.
  /// Phase 2: includes emergency ×2 multiplier, rare blood type +100, streak +50.
  Future<int> awardDonationPoints(
    String uid,
    String hospitalName, {
    bool isEmergency = false,
    String donorBloodGroup = '',
  }) async {
    int pts = PointsValue.donationRegistered;

    final bool isRare = _rareBloodTypes.contains(donorBloodGroup);

    // Emergency multiplier ×2
    if (isEmergency) pts *= 2;

    // Rare blood type bonus +100
    if (isRare) pts += PointsValue.bloodRarityBonus;

    final rareSuffix = isRare ? ' (زمرة نادرة)' : '';
    final rareSuffixEn = isRare ? ' (rare blood type)' : '';

    await awardPoints(
      uid: uid,
      event: PointsEvent.donationRegistered,
      points: pts,
      descriptionAr: isEmergency
          ? 'تبرع طارئ موثق - $hospitalName$rareSuffix'
          : 'تبرع موثق - $hospitalName$rareSuffix',
      descriptionEn: isEmergency
          ? 'Emergency donation - $hospitalName$rareSuffixEn'
          : 'Verified donation - $hospitalName$rareSuffixEn',
    );

    int total = pts;

    // Consecutive donation streak bonus +50
    final hasPrev = await _hasPreviousDonation(uid);
    if (hasPrev) {
      await awardPoints(
        uid: uid,
        event: PointsEvent.consecutiveDonation,
        points: PointsValue.consecutiveDonation,
        descriptionAr: 'مكافأة الاستمرارية في التبرع',
        descriptionEn: 'Consecutive donation bonus',
      );
      total += PointsValue.consecutiveDonation;
    }

    return total;
  }

  Future<bool> deductPoints({
    required String donorUid,
    required String sponsorUid,
    required String rewardId,
    required String rewardTitle,
    required int pointsRequired,
  }) async {
    final userRef = _fs.collection('users').doc(donorUid);
    final redemptionRef = _fs.collection('redemptions').doc();

    bool success = false;
    await _fs.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data();
      final current = (data?['points'] as int?) ?? 0;
      final hasDonated = (data?['hasDonated'] as bool?) ?? false;

      if (current < pointsRequired || !hasDonated) {
        success = false;
        return;
      }
      final newTotal = current - pointsRequired;
      final tier = tierForPoints(newTotal);

      tx.update(userRef, {'points': newTotal, 'tier': tier});
      tx.set(redemptionRef, {
        'donorId': donorUid,
        'sponsorId': sponsorUid,
        'rewardId': rewardId,
        'rewardTitle': rewardTitle,
        'pointsDeducted': pointsRequired,
        'redeemedAt': FieldValue.serverTimestamp(),
      });
      success = true;
    });
    return success;
  }

  bool _basicComplete(Map<String, dynamic> d) =>
      _f(d['name']) && _f(d['phone']) && _f(d['city']) && _f(d['bloodGroup']);

  bool _healthComplete(Map<String, dynamic> d) =>
      d['height'] != null &&
      d['weight'] != null &&
      _f(d['gender']) &&
      _f(d['smokingStatus']);

  bool _medicalComplete(Map<String, dynamic> d) => _f(d['lastDonated']);

  bool _emergencyComplete(Map<String, dynamic> d) =>
      _f(d['emergencyContactName']) && _f(d['emergencyContactPhone']);

  bool _f(dynamic v) => v != null && v.toString().trim().isNotEmpty;
}
