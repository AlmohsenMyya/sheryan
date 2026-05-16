import 'package:flutter_riverpod/legacy.dart';

/// Global state holder for the most recent emergency blood request ID received via notification.
/// This allows the UI (specifically the Donor Emergency tab) to reactively show the request.
final lastEmergencyRequestIdProvider = StateProvider<String?>((ref) => null);
