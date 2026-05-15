import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/core/utils/whatsapp_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'donor_detail_screen.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class DonorListScreen extends StatefulWidget {
  const DonorListScreen({super.key});

  @override
  State<DonorListScreen> createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  List<Map<String, dynamic>> donors = [];
  List<Map<String, dynamic>> filteredDonors = [];
  bool loading = true;
  
  String? currentUserCity;
  String? currentUserBlood;

  // Use 'all' as a programmatic constant for internal logic
  String selectedCity = 'all';
  String selectedBlood = 'all';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCurrentUserProfile();
    await _loadDonors();
  }

  Future<void> _loadCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _fs.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          currentUserCity = doc.data()?['city'];
          currentUserBlood = doc.data()?['bloodGroup'];
        });
      }
    }
  }

  Future<void> _loadDonors() async {
    try {
      final snapshot =
          await _fs.collection('users').where('role', isEqualTo: 'donor').get();

      donors = snapshot.docs
          .map((d) => {
                'id': d.id,
                ...d.data(),
              })
          .toList();

      filteredDonors = List.from(donors);
    } catch (e) {
      debugPrint('Error loading donors: $e');
      donors = [];
      filteredDonors = [];
    }
    setState(() => loading = false);
  }

  void _filterDonors() {
    setState(() {
      filteredDonors = donors.where((donor) {
        final donorCity = (donor['city'] ?? '').toString();
        final donorBlood = (donor['bloodGroup'] ?? '').toString();
        final matchesCity = selectedCity == 'all' || donorCity == selectedCity;
        final matchesBlood =
            selectedBlood == 'all' || donorBlood == selectedBlood;
        return matchesCity && matchesBlood;
      }).toList();
    });
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

    // Build explicit List<String> for cities (unique)
    final citySet = <String>{};
    for (final d in donors) {
      final c = (d['city'] ?? '').toString();
      if (c.isNotEmpty) citySet.add(c);
    }

    final List<String> bloodGroups = [
      'all',
      'A+',
      'A-',
      'B+',
      'B-',
      'O+',
      'O-',
      'AB+',
      'AB-'
    ];

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Row
                Padding(
                  padding: AppDesignConstants.edgeInsetsSmall,
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCity,
                          dropdownColor: colorScheme.surface,
                          decoration: InputDecoration(
                            labelText: l10n.city,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text(l10n.all),
                            ),
                            ...citySet.map((city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city),
                                )),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedCity = value;
                              _filterDonors();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedBlood,
                          dropdownColor: colorScheme.surface,
                          decoration: InputDecoration(
                            labelText: l10n.bloodGroup,
                          ),
                          items: bloodGroups
                              .map((bg) => DropdownMenuItem<String>(
                                    value: bg,
                                    child: Text(bg == 'all' ? l10n.all : bg),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedBlood = value;
                              _filterDonors();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Donor List
                Expanded(
                  child: filteredDonors.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noDonorsFound,
                            style: theme.textTheme.bodyMedium,
                          )
                        )
                      : ListView.builder(
                          itemCount: filteredDonors.length,
                          itemBuilder: (ctx, i) {
                            final donor = filteredDonors[i];
                            final blood = (donor['bloodGroup'] ?? l10n.notAvailable).toString();
                            final city = (donor['city'] ?? l10n.notAvailable).toString();
                            return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DonorDetailScreen(donorId: donor['id']),
                                      ),
                                    );
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryRed,
                                    child: Text(
                                      blood,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    donor['name'] ?? l10n.unknown,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  subtitle: Text(
                                    '$city • $blood',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.chat, color: Colors.green),
                                        onPressed: () {
                                          WhatsAppHelper.openWhatsApp(
                                            context: context,
                                            phone: donor['phone'] ?? '',
                                            message: l10n.whatsappRecipientMessage(
                                              donor['name'] ?? l10n.unknown,
                                              currentUserBlood ?? '?',
                                              currentUserCity ?? '?',
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.call, color: AppColors.primaryRed),
                                        onPressed: () => _makePhoneCall(
                                            (donor['phone'] ?? '').toString()),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
