import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/services/hospital_service.dart';
import 'package:sheryan/services/user_service.dart';

/// Provider for the currently selected city filter.
/// Defaults to the user's city if available.
final selectedCityProvider = StateProvider<String?>((ref) {
  // We use listen instead of watch for the initial value to avoid
  // resets if the user profile changes but they manually changed the city.
  final userProfile = ref.read(userProfileProvider).asData?.value;
  return userProfile?['city'] as String?;
});

/// Stream provider for all available cities.
final citiesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return HospitalService().watchCities();
});

/// Stream provider for hospitals in the selected city.
final nearbyHospitalsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final city = ref.watch(selectedCityProvider);
  if (city == null || city.isEmpty) {
    return Stream.value([]);
  }

  // 🌟 هنا تم الإصلاح فقط: استخدمنا HospitalService بدلاً من UserService
  return HospitalService().watchHospitalsByCity(city);
});