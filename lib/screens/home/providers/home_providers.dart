import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/enums/user_role.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  
  return profileAsync.maybeWhen(
    data: (profile) {
      if (profile == null) return UserRole.recipient;
      final roleStr = profile['role'] as String?;
      if (roleStr == 'hospitalAdmin') return UserRole.hospitalAdmin;
      if (roleStr == 'superAdmin') return UserRole.superAdmin;
      if (roleStr == 'sponsorOrg') return UserRole.sponsorOrg;
      if (roleStr == 'donor') return UserRole.donor;
      return UserRole.recipient;
    },
    orElse: () => UserRole.recipient,
  );
});
