import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/utils/whatsapp_helper.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/request_service.dart';
import 'package:sheryan/services/staged_notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestResponseScreen extends StatefulWidget {
  final String requestId;

  const RequestResponseScreen({super.key, required this.requestId});

  @override
  State<RequestResponseScreen> createState() => _RequestResponseScreenState();
}

class _RequestResponseScreenState extends State<RequestResponseScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _requestData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRequest();
  }

  Future<void> _fetchRequest() async {
    try {
      final data = await RequestService().getById(widget.requestId);
      if (data == null) {
        setState(() {
          _error = "Request not found";
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _requestData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDecline() async {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeclineTitle),
        content: Text(l10n.confirmDeclineBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.declineButton),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await StagedNotificationService().declineRequestSlot(widget.requestId, user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.declineSuccessMessage)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleAccept() {
    if (_requestData == null) return;
    final l10n = AppLocalizations.of(context)!;
    
    // Existing logic for contacting recipient
    final String phone = _requestData!['phone'] ?? '';
    final String patient = _requestData!['patientName'] ?? l10n.unknownPatient;
    final String bloodGroup = _requestData!['bloodGroup'] ?? '?';

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: Text(l10n.call),
            onTap: () {
              Navigator.pop(ctx);
              launchUrl(Uri.parse("tel:$phone"));
            },
          ),
          ListTile(
            leading: const Icon(Icons.message, color: Colors.blue),
            title: Text(l10n.whatsapp),
            onTap: () {
              Navigator.pop(ctx);
              WhatsAppHelper.openWhatsApp(
                phone: phone,
                message: l10n.whatsappDonorMessage(patient, bloodGroup),
                context: context,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _requestData == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.requestDetails)),
        body: Center(child: Text(_error ?? l10n.genericError("Data null"))),
      );
    }

    final isUrgent = _requestData!['isUrgent'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emergencyRequest),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isUrgent)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 10),
                    Text(
                      l10n.urgentLabel,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            
            // Header Info
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryRed,
                    child: Text(
                      _requestData!['bloodGroup'] ?? '?',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _requestData!['patientName'] ?? l10n.unknownPatient,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _buildDetailTile(Icons.local_hospital, l10n.hospitalName, _requestData!['hospital'] ?? '—'),
            _buildDetailTile(Icons.location_on, l10n.city, _requestData!['city'] ?? '—'),
            _buildDetailTile(Icons.invert_colors, l10n.units, _requestData!['units']?.toString() ?? '1'),
            _buildDetailTile(Icons.access_time, l10n.neededAtLabel(""), _requestData!['neededAt'] ?? '—'),

            const SizedBox(height: 40),

            _buildActionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionArea() {
    final l10n = AppLocalizations.of(context)!;
    final currentUser = FirebaseAuth.instance.currentUser;
    final String status = _requestData?['status'] ?? 'pending';
    final List<dynamic> declinedIds = _requestData?['declinedDonorIds'] as List<dynamic>? ?? [];

    // Scenario B: Completed Lock
    if (status == 'done' || status == 'completed') {
      return _buildLockedBanner(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        text: l10n.requestAlreadyFulfilled,
      );
    }

    // Scenario A: Declined Lock
    if (currentUser != null && declinedIds.contains(currentUser.uid)) {
      return _buildLockedBanner(
        icon: Icons.info_outline,
        color: Colors.orange,
        text: l10n.requestAlreadyDeclined,
      );
    }

    // Standard Actions
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _handleDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.error),
            ),
            child: Text(l10n.declineButton),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            onPressed: _handleAccept,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.acceptButton),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedBanner({required IconData icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
