import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class DonorDetails extends StatefulWidget {
  final String donorId;

  const DonorDetails({super.key, required this.donorId});

  @override
  State<DonorDetails> createState() => _DonorDetailsState();
}

class _DonorDetailsState extends State<DonorDetails> {
  Map<String, dynamic>? donor;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDonor();
  }

  Future<void> _fetchDonor() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.donorId)
          .get();
      if (snapshot.exists) {
        donor = snapshot.data();
      }
    } catch (e) {
      debugPrint('Error fetching donor: $e');
    }
    setState(() => loading = false);
  }

  bool get isAvailable {
    try {
      final lastDonated = donor?['lastDonated'];
      if (lastDonated == null || lastDonated == '') return true;

      final donatedDate = DateTime.parse(lastDonated);
      final diff = DateTime.now().difference(donatedDate).inDays;
      return diff >= 30;
    } catch (_) {
      return true;
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final l10n = AppLocalizations.of(context)!;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.noPhoneNumber)));
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.cannotMakeCall)));
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.donorDetails),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : donor == null
              ? Center(
                  child: Text(
                    l10n.donorNotFound,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : SingleChildScrollView(
                    padding: AppDesignConstants.edgeInsetsMedium,
                    child: Column(
                      children: [
                        // 🔴 Profile Header
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accentRed, AppColors.primaryRed],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: AppDesignConstants.borderRadiusExtraLarge,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryRed.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 30, horizontal: 16),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person,
                                    size: 55, color: AppColors.primaryRed),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                donor!['name'] ?? l10n.unknownDonor,
                                style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                donor!['bloodGroup'] != null
                                    ? l10n.bloodGroupLabel(donor!['bloodGroup'].toString())
                                    : '',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 25),

                        // 🔴 Info Card Section
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: AppDesignConstants.borderRadiusLarge,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          padding: AppDesignConstants.edgeInsetsMedium,
                          child: Column(
                            children: [
                              _infoRow(Icons.phone, l10n.phone, donor!['phone']),
                              _infoRow(Icons.email, l10n.email, donor!['email']),
                              _infoRow(Icons.location_on, l10n.city, donor!['city']),
                              _infoRow(Icons.calendar_today, l10n.lastDonated,
                                  donor!['lastDonated'] ?? l10n.notAvailable),
                              _infoRow(
                                Icons.favorite,
                                l10n.availableToDonate,
                                isAvailable ? '${l10n.yes} ✅' : '${l10n.no} ❌',
                                color:
                                    isAvailable ? Colors.green : Colors.orange,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 🔴 Call Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppDesignConstants.borderRadiusCircular,
                            ),
                          ),
                          onPressed: () =>
                              _makePhoneCall(donor!['phone'] ?? ''),
                          icon: const Icon(Icons.phone),
                          label: Text(l10n.callDonor),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

Widget _infoRow(IconData icon, String label, String? value, {Color? color}) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final display = (value == null || value.trim().isEmpty) ? l10n.notAvailable : value;

  return Padding(
    padding:  EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Icon(icon, color: AppColors.primaryRed),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 1),
              SelectableText(
                display,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color ?? colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}
