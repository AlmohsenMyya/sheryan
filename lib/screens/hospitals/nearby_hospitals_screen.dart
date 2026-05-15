import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'providers/nearby_hospitals_provider.dart';
import 'widgets/hospital_card.dart';

class NearbyHospitalsScreen extends ConsumerWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    final selectedCity = ref.watch(selectedCityProvider);
    final citiesAsync = ref.watch(citiesProvider);
    final hospitalsAsync = ref.watch(nearbyHospitalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearbyHospitals),
      ),
      body: Column(
        children: [
          // City Selector Header
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: citiesAsync.when(
                    data: (cities) => DropdownButtonFormField<String>(
                      value: selectedCity,
                      decoration: InputDecoration(
                        labelText: l10n.selectCity,
                        prefixIcon: const Icon(Icons.location_city),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: AppDesignConstants.borderRadiusMedium,
                        ),
                      ),
                      items: cities.map((c) {
                        final cityName = c['name'] as String;
                        return DropdownMenuItem(
                          value: cityName,
                          child: Text(cityName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(selectedCityProvider.notifier).state = val;
                        }
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => Text(l10n.errorLoadingData),
                  ),
                ),
              ],
            ),
          ),

          // Hospitals List
          Expanded(
            child: hospitalsAsync.when(
              data: (hospitals) {
                if (hospitals.isEmpty) {
                  return _buildEmptyState(context, selectedCity ?? '');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: hospitals.length,
                  itemBuilder: (context, index) {
                    return HospitalCard(hospital: hospitals[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(l10n.genericError(err.toString()))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String city) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              city.isEmpty ? l10n.unableToDetectCity : l10n.noHospitalsFoundInCity(city),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
