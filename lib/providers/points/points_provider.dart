import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/repositories/firebase/firebase_reward_repository.dart';
import 'package:sheryan/services/user_service.dart';

final pointsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value({'points': 0, 'tier': 'bronze'});
  return UserService().watchPoints(user.uid);
});

final pointsHistoryProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return UserService().watchPointsHistory(user.uid);
});

// RewardRepository used directly: rewards are read-only, sponsor-scoped data
// that don't belong to UserService business logic.
final _rewardRepo = FirebaseRewardRepository();

final sponsorRewardsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, sponsorId) {
  return _rewardRepo.watchBySponsor(sponsorId);
});

final cityRewardsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, city) {
  return _rewardRepo.watchByCity(city);
});

final sponsorRedemptionsCountProvider =
    StreamProvider.family<int, String>((ref, sponsorId) {
  return _rewardRepo.watchRedemptionsCount(sponsorId);
});
