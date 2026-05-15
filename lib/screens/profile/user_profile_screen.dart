import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/providers/auth/auth_provider.dart';
import 'package:sheryan/services/request_service.dart';
import 'package:sheryan/core/utils/qr_dialog.dart';

import 'widgets/profile_header.dart';
import 'widgets/profile_stats.dart';
import 'widgets/profile_info_section.dart';
import 'widgets/edit_profile_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfile),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              profileAsync.whenData((profile) {
                if (profile != null) {
                  _showEditSheet(context, profile);
                }
              });
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userProfileProvider),
            color: AppColors.medicalBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeader(
                    name: profile['name'] as String? ?? l10n.unknown,
                    bloodGroup: profile['bloodGroup'] as String? ?? '-',
                    email: profile['email'] as String? ?? '',
                  ),
                  const SizedBox(height: 24),
                  
                  _buildStatsSection(uid),
                  
                  const SizedBox(height: 24),
                  
                  ProfileInfoSection(
                    title: l10n.basicInfoTitle,
                    children: [
                      ProfileInfoTile(
                        icon: Icons.phone_outlined,
                        label: l10n.phone,
                        value: profile['phone'] as String? ?? '-',
                      ),
                      ProfileInfoTile(
                        icon: Icons.location_city_outlined,
                        label: l10n.city,
                        value: profile['city'] as String? ?? '-',
                      ),
                      ProfileInfoTile(
                        icon: Icons.badge_outlined,
                        label: l10n.accountType,
                        value: profile['role'] == 'donor' ? l10n.roleDonor : l10n.roleUser,
                        showDivider: false,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  ElevatedButton.icon(
                    onPressed: () {
                      QrDialog.show(
                        context,
                        data: uid,
                        label: profile['name'] as String? ?? '',
                        idLabel: l10n.donorId,
                      );
                    },
                    icon: const Icon(Icons.qr_code),
                    label: Text(l10n.donorCard),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showEditSheet(context, profile),
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.saveChanges),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection(String uid) {
    return StreamBuilder<int>(
      stream: RequestService().watchUserTotal(uid),
      builder: (context, totalSnap) {
        return StreamBuilder<int>(
          stream: RequestService().watchUserFulfilled(uid),
          builder: (context, fulfilledSnap) {
            return ProfileStats(
              totalRequests: totalSnap.data ?? 0,
              fulfilledRequests: fulfilledSnap.data ?? 0,
            );
          },
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, Map<String, dynamic> userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditProfileSheet(userData: userData),
    );
  }
}
