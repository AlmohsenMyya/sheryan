import 'package:sheryan/repositories/firebase/firebase_city_repository.dart';
import 'package:sheryan/repositories/firebase/firebase_hospital_repository.dart';
import 'package:sheryan/repositories/interfaces/city_repository.dart';
import 'package:sheryan/repositories/interfaces/hospital_repository.dart';

/// Mediates all hospital and city business logic.
/// Calls repositories for every data operation — never touches Firebase directly.
class HospitalService {
  static final HospitalService _instance = HospitalService._internal();
  factory HospitalService() => _instance;
  HospitalService._internal();

  // ── Swap these two lines to migrate backend ────────────────────────────────
  final HospitalRepository _hospitalRepo = FirebaseHospitalRepository();
  final CityRepository _cityRepo = FirebaseCityRepository();
  // ──────────────────────────────────────────────────────────────────────────

  // ── Hospitals ──────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchHospitals() =>
      _hospitalRepo.watchAll();

  Stream<List<Map<String, dynamic>>> watchHospitalsByCity(String city) =>
      _hospitalRepo.watchByCity(city);

  Stream<int> watchHospitalCount() => _hospitalRepo.watchCount();

  Future<Map<String, dynamic>?> getHospitalById(String id) =>
      _hospitalRepo.getById(id);

  Future<void> addHospital({required String name, required String city}) =>
      _hospitalRepo.add(name: name, city: city);

  Future<void> updateHospital(
    String id, {
    required String name,
    required String city,
    String? phone,
    String? address,
  }) =>
      _hospitalRepo.update(id, name: name, city: city, phone: phone, address: address);

  Future<void> deleteHospital(String id) => _hospitalRepo.delete(id);

  // ── Cities ─────────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchCities() => _cityRepo.watchAll();

  Future<void> addCity(String name) => _cityRepo.add(name);

  Future<void> updateCity(String id, String name) => _cityRepo.update(id, name);

  Future<void> deleteCity(String id) => _cityRepo.delete(id);
}
