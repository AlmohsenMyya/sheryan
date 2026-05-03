import 'package:sheryan/core/utils/qr_dialog.dart';
import 'package:sheryan/events/app_event.dart';
import 'package:sheryan/events/notification_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/request_service.dart';
import 'package:intl/intl.dart';

class RequestsListScreen extends StatefulWidget {
  const RequestsListScreen({super.key});

  @override
  State<RequestsListScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsListScreen> {
  late final Stream<List<Map<String, dynamic>>> _requestsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _requestsStream = RequestService().watchByUser(user.uid);
    } else {
      _requestsStream = const Stream.empty();
    }
  }

  /// Marks the request as done via [RequestService], then notifies the matched
  /// donor (if a donation record exists) that the request has been closed.
  Future<void> _markAsDone(String docId, Map<String, dynamic> data) async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.markAsDone),
        content: Text(l10n.confirmRequestFulfilled),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.yesDone),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await RequestService().markDone(docId);

    NotificationEngine().dispatch(BloodRequestClosedEvent(requestId: docId));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.statusDone)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myBloodRequests)),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _requestsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Text(
                      l10n.genericError(snapshot.error.toString())));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(l10n.noBloodRequestsFound,
                    style: theme.textTheme.bodyMedium),
              );
            }

            final requests = snapshot.data!;

            return ListView.builder(
              padding: AppDesignConstants.edgeInsetsMedium,
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final data = requests[index];
                final docId = data['id'] as String;
                final isDone = data['status'] == 'done';
                final isVerified = data['isVerified'] ?? false;

                final createdAt = data['createdAt'] != null
                    ? (data['createdAt'] as Timestamp).toDate()
                    : DateTime.now();
                final formattedDate =
                    DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: AppDesignConstants.edgeInsetsMedium,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryRed,
                              child: Text(
                                data['bloodGroup'] ?? '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                data['patientName'] ?? l10n.unknownPatient,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            _buildStatusBadge(isDone, isVerified, l10n),
                          ],
                        ),
                        const Divider(height: 24),

                        // Request details
                        _buildInfoRow(Icons.local_hospital,
                            l10n.hospitalName, data['hospital']),
                        _buildInfoRow(
                            Icons.location_on, l10n.city, data['city']),
                        _buildInfoRow(
                            Icons.phone, l10n.phoneNumber, data['phone']),
                        _buildInfoRow(
                            Icons.invert_colors, l10n.units, data['units']),
                        _buildInfoRow(Icons.access_time, l10n.units,
                            data['neededAt']),

                        const SizedBox(height: 8),
                        Text(
                          l10n.requestedOnLabel(formattedDate),
                          style: theme.textTheme.labelSmall,
                        ),

                        // Actions (only when not done)
                        if (!isDone) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => QrDialog.show(
                                  context,
                                  data: docId,
                                  label: data['patientName'] ??
                                      l10n.unknownPatient,
                                  idLabel: l10n.requestId,
                                ),
                                icon: const Icon(Icons.qr_code,
                                    color: AppColors.textSecondary),
                                label: Text(l10n.showQrCode,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _markAsDone(docId, data),
                                icon: const Icon(Icons.check),
                                label: Text(l10n.markAsDone),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
      bool isDone, bool isVerified, AppLocalizations l10n) {
    final IconData icon;
    final Color color;
    final String label;

    if (isDone) {
      icon = Icons.check_circle;
      color = AppColors.success;
      label = l10n.statusCompleted;
    } else if (isVerified) {
      icon = Icons.verified;
      color = Colors.blue;
      label = l10n.statusVerified;
    } else {
      icon = Icons.pending;
      color = Colors.orange;
      label = l10n.statusUnverified;
    }

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, dynamic value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Text("$label: ", style: theme.textTheme.labelSmall),
          Expanded(
            child: Text(
              value?.toString() ?? "-",
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
