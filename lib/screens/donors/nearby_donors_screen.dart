import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/core/utils/blood_logic.dart';
import 'package:sheryan/core/utils/whatsapp_helper.dart';
import 'package:sheryan/screens/donors/donor_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class NearbyDonorsScreen extends StatefulWidget {
  const NearbyDonorsScreen({super.key});

  @override
  State<NearbyDonorsScreen> createState() => _NearbyDonorsScreenState();
}

class _NearbyDonorsScreenState extends State<NearbyDonorsScreen> {
  String? city;
  String? userBloodGroup;
  bool isLoading = true;
  List<Map<String, dynamic>> donors = [];

  @override
  void initState() {
    super.initState();
    fetchNearbyDonors();
  }

  Future<void> _makePhoneCall(String phone) async {
    final l10n = AppLocalizations.of(context)!;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.noPhoneNumber)));
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cannotMakeCall)));
    }
  }

  Future<void> fetchNearbyDonors() async {
    debugPrint('=====================================================');
    debugPrint('🔍 [TRACKING] fetchNearbyDonors STARTED');

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      debugPrint('🔍 [TRACKING] Current User UID: $uid');

      if (uid == null) {
        debugPrint('❌ [ERROR] UID is null. User is not logged in.');
        setState(() => isLoading = false);
        return;
      }

      // 1️⃣ Get user data from Firestore
      debugPrint('🔍 [TRACKING] Fetching current user document...');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        debugPrint('🔍 [TRACKING] User Doc Exists. Data: $userData');

        city = userData?['city'];
        userBloodGroup = userData?['bloodGroup'];

        debugPrint('🔍 [TRACKING] Extracted City: "$city"');
        debugPrint('🔍 [TRACKING] Extracted Blood Group: "$userBloodGroup"');

        if (city != null && city!.isNotEmpty && userBloodGroup != null) {
          // 2️⃣ Get Compatible Blood Types
          final compatibleTypes = BloodLogic.getCompatibleDonors(userBloodGroup!);
          debugPrint('🔍 [TRACKING] Compatible Blood Types for $userBloodGroup: $compatibleTypes');

          if (compatibleTypes.isEmpty) {
            debugPrint('⚠️ [WARNING] Compatible types list is EMPTY!');
          }

          // 3️⃣ Fetch Compatible Donors in the same city
          debugPrint('🔍 [TRACKING] Querying donors...');
          debugPrint('   -> Condition 1: role == "donor"');
          debugPrint('   -> Condition 2: city == "$city"');
          debugPrint('   -> Condition 3: bloodGroup IN $compatibleTypes');

          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'donor')
              .where('city', isEqualTo: city)
              .where('bloodGroup', whereIn: compatibleTypes)
              .get();

          debugPrint('🔍 [TRACKING] Query finished. Found ${querySnapshot.docs.length} documents.');

          donors = querySnapshot.docs
              .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            debugPrint('   👉 Found Donor: ${data['name']} | Blood: ${data['bloodGroup']} | City: ${data['city']}');
            return data;
          })
              .toList();

          // Sort: Perfect matches first
          donors.sort((a, b) {
            bool aMatch = a['bloodGroup'] == userBloodGroup;
            bool bMatch = b['bloodGroup'] == userBloodGroup;
            if (aMatch && !bMatch) return -1;
            if (!aMatch && bMatch) return 1;
            return 0;
          });

          debugPrint('🔍 [TRACKING] Donors list sorted.');

        } else {
          debugPrint('⚠️ [WARNING] Missing User Data! City or BloodGroup is null/empty.');
        }
      } else {
        debugPrint('❌ [ERROR] Current user document does not exist in "users" collection.');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [CRITICAL ERROR] Failed to fetch donors!');
      debugPrint('Exception details: $e');
      debugPrint('Stack trace: $stackTrace');

      // اذا كان الخطأ بسبب Missing Index (السبب الأكثر شيوعاً)، سيظهر الرابط هنا!
      if (e.toString().contains('failed-precondition') || e.toString().contains('index')) {
        debugPrint('🚨 [INDEX REQUIRED] You need to create a Firestore Index. Check the console error above for the exact Firebase link to generate it automatically.');
      }
    }

    debugPrint('🔍 [TRACKING] fetchNearbyDonors FINISHED');
    debugPrint('=====================================================');

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.nearbyDonors),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : donors.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            city == null || city!.isEmpty
                ? l10n.unableToDetectCity
                : l10n.noDonorsFoundInCity(city!),
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      )
          : ListView.builder(
        padding: AppDesignConstants.edgeInsetsSmall,
        itemCount: donors.length,
        itemBuilder: (context, index) {
          final donor = donors[index];
          final bool isPerfect = donor['bloodGroup'] == userBloodGroup;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DonorDetailScreen(donorId: donor['id']),
                  ),
                );
              },
              leading: CircleAvatar(
                backgroundColor: isPerfect ? AppColors.primaryRed : theme.colorScheme.secondary,
                child: Icon(
                    isPerfect ? Icons.check_circle : Icons.person,
                    color: Colors.white
                ),
              ),
              title: Row(
                children: [
                  Text(
                    donor['name'] ?? l10n.unknown,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (isPerfect) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "MATCH",
                        style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.bloodGroupLabel(donor['bloodGroup'] ?? l10n.notAvailable),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isPerfect ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    l10n.cityLabel(donor['city'] ?? ''),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
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
                          userBloodGroup ?? '?',
                          city ?? '?',
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone, color: AppColors.primaryRed),
                    onPressed: () {
                      final phone = donor['phone'];
                      if (phone != null && phone.toString().isNotEmpty) {
                        _makePhoneCall(phone.toString());
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}