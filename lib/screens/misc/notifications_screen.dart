import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheryan/core/models/app_notification.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/notification_service.dart';
import 'package:sheryan/screens/donors/request_response_screen.dart';

// ─── Tab filter definition ────────────────────────────────────────────────────

enum _NotifTab { all, emergency, verification, donation, system }

extension _NotifTabFilter on _NotifTab {
  bool matches(NotificationType type) {
    switch (this) {
      case _NotifTab.all:
        return true;
      case _NotifTab.emergency:
        return type == NotificationType.emergency;
      case _NotifTab.verification:
        return type == NotificationType.verification ||
            type == NotificationType.newRequest;
      case _NotifTab.donation:
        return type == NotificationType.gratitude ||
            type == NotificationType.requestClosed;
      case _NotifTab.system:
        return type == NotificationType.general;
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  void _markAllRead() {
    if (_userId != null) {
      NotificationService().markAllAsRead(_userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    if (_userId == null) return const Scaffold();

    final tabs = [
      _TabDef(label: l10n.all, filter: _NotifTab.all),
      _TabDef(label: l10n.notifTabEmergency, filter: _NotifTab.emergency),
      _TabDef(
          label: l10n.notifTabVerification, filter: _NotifTab.verification),
      _TabDef(label: l10n.notifTabDonation, filter: _NotifTab.donation),
      _TabDef(label: l10n.notifTabSystem, filter: _NotifTab.system),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(l10n.notifications,
            style: TextStyle(
                color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _markAllRead,
            icon: Icon(Icons.done_all,
                size: 18, color: colorScheme.primary),
            label: Text(l10n.markAllRead,
                style: TextStyle(
                    color: colorScheme.primary, fontSize: 12)),
          ),
        ],
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryRed));
          }

          final allItems = (snapshot.data?.docs ?? [])
              .map((doc) => AppNotification.fromMap(
                  doc.id, doc.data() as Map<String, dynamic>))
              .toList();

          return TabBarView(
            children: tabs
                .map((t) => _NotifList(
                      all: allItems,
                      filter: t.filter,
                      userId: _userId!,
                      l10n: l10n,
                    ))
                .toList(),
          );
        },
      ),
    ),
    );
  }
}

// ─── Filtered list per tab ────────────────────────────────────────────────────

class _NotifList extends StatelessWidget {
  final List<AppNotification> all;
  final _NotifTab filter;
  final String userId;
  final AppLocalizations l10n;

  const _NotifList({
    required this.all,
    required this.filter,
    required this.userId,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final items = all.where((n) => filter.matches(n.type)).toList();

    if (items.isEmpty) {
      return _EmptyState(
        isAllTab: filter == _NotifTab.all,
        l10n: l10n,
      );
    }

    // Group by date bucket
    final groups = _groupByDate(items, l10n);

    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final group = groups[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date separator
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(
                children: [
                  Text(
                    group.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface.withOpacity(0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                        color: colorScheme.outline, height: 1),
                  ),
                ],
              ),
            ),
            // Notification cards
            ...group.items.map((n) => _NotifCard(
                  notification: n,
                  userId: userId,
                )),
          ],
        );
      },
    );
  }

  List<_DateGroup> _groupByDate(
      List<AppNotification> items, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AppNotification>> buckets = {
      l10n.notifToday: [],
      l10n.notifYesterday: [],
      l10n.notifEarlier: [],
    };

    for (final item in items) {
      final d = DateTime(
          item.timestamp.year, item.timestamp.month, item.timestamp.day);
      if (d == today) {
        buckets[l10n.notifToday]!.add(item);
      } else if (d == yesterday) {
        buckets[l10n.notifYesterday]!.add(item);
      } else {
        buckets[l10n.notifEarlier]!.add(item);
      }
    }

    return buckets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => _DateGroup(label: e.key, items: e.value))
        .toList();
  }
}

// ─── Notification card ────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final AppNotification notification;
  final String userId;

  const _NotifCard({required this.notification, required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';
    final title =
        isAr ? notification.titleAr : notification.titleEn;
    final body = isAr ? notification.bodyAr : notification.bodyEn;
    final timeStr =
        DateFormat('hh:mm a').format(notification.timestamp);
    final l10n = AppLocalizations.of(context)!;
    final typeColor = _typeColor(notification.type);
    final typeIcon = _typeIcon(notification.type);
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: () => NotificationService().markAsRead(userId, notification.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Colored left bar
                Container(width: 4, color: typeColor),
                // Card content
                Expanded(
                  child: Container(
                    color: isUnread
                        ? colorScheme.surface
                        : colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(typeIcon, color: typeColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isUnread
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isUnread
                                            ? colorScheme.onSurface
                                            : colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                  if (isUnread) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: typeColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              if (notification.type == NotificationType.emergency) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.tonalIcon(
                                    onPressed: (notification.requestId == null || notification.requestId!.isEmpty)
                                        ? () => ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(l10n.genericError("Invalid Request ID"))),
                                            )
                                        : () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => RequestResponseScreen(requestId: notification.requestId!),
                                              ),
                                            ),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.visibility_outlined, size: 18),
                                    label: Text(l10n.viewDetailsButton, style: const TextStyle(fontSize: 13)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.emergency:
        return Icons.warning_amber_rounded;
      case NotificationType.verification:
        return Icons.verified_user_rounded;
      case NotificationType.newRequest:
        return Icons.inbox_rounded;
      case NotificationType.gratitude:
        return Icons.favorite_rounded;
      case NotificationType.requestClosed:
        return Icons.check_circle_rounded;
      case NotificationType.general:
        return Icons.info_rounded;
    }
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.emergency:
        return AppColors.error;
      case NotificationType.verification:
        return AppColors.hospitalPrimary;
      case NotificationType.newRequest:
        return Colors.orange;
      case NotificationType.gratitude:
        return AppColors.success;
      case NotificationType.requestClosed:
        return Colors.teal;
      case NotificationType.general:
        return AppColors.primaryRed;
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isAllTab;
  final AppLocalizations l10n;

  const _EmptyState({required this.isAllTab, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAllTab
                ? Icons.notifications_none_rounded
                : Icons.filter_list_off_rounded,
            size: 72,
            color: colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            isAllTab
                ? l10n.noNotificationsFound
                : l10n.noNotificationsInTab,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _TabDef {
  final String label;
  final _NotifTab filter;
  const _TabDef({required this.label, required this.filter});
}

class _DateGroup {
  final String label;
  final List<AppNotification> items;
  const _DateGroup({required this.label, required this.items});
}
