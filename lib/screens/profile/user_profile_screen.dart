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
        // 🌟 أفضل مكان في العالم لزر التعديل: شريط الإجراءات العلوي
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square), // تغيير الأيقونة لتكون معبرة أكثر
            onPressed: () {
              profileAsync.whenData((profile) {
                if (profile != null) {
                  _showEditSheet(context, profile);
                }
              });
            },
          ),
          const SizedBox(width: 8), // مسافة صغيرة للترتيب
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

                  const SizedBox(height: 32), // مساحة تنفس نظيفة بعد حذف الزر القديم

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

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        QrDialog.show(
                          context,
                          data: uid,
                          label: profile['name'] as String? ?? '',
                          idLabel: l10n.donorId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.secondary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppDesignConstants.borderRadiusMedium,
                          side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.qr_code_scanner, color: theme.colorScheme.secondary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l10n.donorCard,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
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