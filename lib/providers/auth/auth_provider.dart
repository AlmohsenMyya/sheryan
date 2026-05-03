import 'package:flutter_riverpod/legacy.dart';
import 'package:sheryan/core/enums/user_role.dart';
import 'package:sheryan/services/auth_service.dart';
import 'package:sheryan/services/user_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provides a single instance of AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Listens to authentication state changes from Firebase
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Fetches and listens to the current user's profile document
final userProfileProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return UserService().watchProfile(user.uid);
});

/// Holds the selected role
final roleProvider = StateNotifierProvider<RoleNotifier, UserRole?>(
  (ref) => RoleNotifier(),
);

class RoleNotifier extends StateNotifier<UserRole?> {
  RoleNotifier() : super(null);

  void setRole(UserRole role) => state = role;

  void setRoleFromString(String? roleStr) {
    switch (roleStr) {
      case 'donor':
        state = UserRole.donor;
        break;
      case 'user':
      case 'recipient':
        state = UserRole.recipient;
        break;
      case 'hospitalAdmin':
        state = UserRole.hospitalAdmin;
        break;
      case 'superAdmin':
        state = UserRole.superAdmin;
        break;
      case 'sponsorOrg':
        state = UserRole.sponsorOrg;
        break;
      default:
        state = null;
    }
  }

  void clearRole() => state = null;
}
