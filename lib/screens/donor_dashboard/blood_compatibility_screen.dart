import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/utils/blood_logic.dart';
import 'package:sheryan/l10n/app_localizations.dart';

class BloodCompatibilityScreen extends StatefulWidget {
  final String donorBloodGroup;
  const BloodCompatibilityScreen({super.key, required this.donorBloodGroup});

  @override
  State<BloodCompatibilityScreen> createState() =>
      _BloodCompatibilityScreenState();
}

class _BloodCompatibilityScreenState extends State<BloodCompatibilityScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = widget.donorBloodGroup;
    final canDonateTo = BloodLogic.getCompatibleRecipients(bg);
    final canReceiveFrom = BloodLogic.getCompatibleDonors(bg);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.bloodCompatibilityTitle),
        bottom: TabBar(
          indicatorColor: AppColors.primaryRed,
          labelColor: AppColors.primaryRed,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          tabs: [
            Tab(text: l10n.compatCanDonateTo),
            Tab(text: l10n.compatCanReceiveFrom),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDonorBadge(bg, l10n),
          Expanded(
            child: TabBarView(
              children: [
                _buildCompatGrid(
                  context: context,
                  compatible: canDonateTo,
                  label: l10n.compatCanDonateTo,
                  icon: Icons.volunteer_activism,
                  color: AppColors.primaryRed,
                  emptyMsg: l10n.compatNone,
                  l10n: l10n,
                ),
                _buildCompatGrid(
                  context: context,
                  compatible: canReceiveFrom,
                  label: l10n.compatCanReceiveFrom,
                  icon: Icons.favorite,
                  color: Colors.deepPurple,
                  emptyMsg: l10n.compatNone,
                  l10n: l10n,
                ),
              ],
            ),
          ),
          _buildCompatibilityTable(bg, canDonateTo, canReceiveFrom, l10n),
        ],
      ),
    ),
    );
  }

  Widget _buildDonorBadge(String bg, AppLocalizations l10n) {
    final isUniversalDonor = bg == 'O-';
    final isUniversalRecipient = bg == 'AB+';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryRed, AppColors.accentRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                bg,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourBloodGroup,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  bg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isUniversalDonor || isUniversalRecipient)
                  const SizedBox(height: 4),
                if (isUniversalDonor)
                  _specialBadge(l10n.universalDonor, Icons.star),
                if (isUniversalRecipient)
                  _specialBadge(l10n.universalRecipient, Icons.star),
              ],
            ),
          ),
          Column(
            children: [
              _statChip(
                  BloodLogic.getCompatibleRecipients(bg).length.toString(),
                  l10n.canDonateTo),
              const SizedBox(height: 6),
              _statChip(
                  BloodLogic.getCompatibleDonors(bg).length.toString(),
                  l10n.canReceiveFrom),
            ],
          ),
        ],
      ),
    );
  }

  Widget _specialBadge(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.amber, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statChip(String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(count,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildCompatGrid({
    required BuildContext context,
    required List<String> compatible,
    required String label,
    required IconData icon,
    required Color color,
    required String emptyMsg,
    required AppLocalizations l10n,
  }) {
    final allTypes = BloodLogic.allTypes;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: allTypes.length,
      itemBuilder: (context, i) {
        final type = allTypes[i];
        final isMatch = compatible.contains(type);
        final isSelf = type == widget.donorBloodGroup;

        return Container(
          decoration: BoxDecoration(
            color: isMatch
                ? color.withOpacity(0.15)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMatch
                  ? color.withOpacity(0.6)
                  : Theme.of(context).colorScheme.outline,
              width: isMatch ? 1.8 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isMatch ? Icons.check_circle : Icons.cancel_outlined,
                    color: isMatch ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(
                      color: isMatch
                          ? color
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isSelf)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompatibilityTable(
    String bg,
    List<String> canDonateTo,
    List<String> canReceiveFrom,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.compatSummary,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          _tableRow(
            icon: Icons.volunteer_activism,
            color: AppColors.primaryRed,
            label: l10n.compatCanDonateTo,
            types: canDonateTo,
          ),
          const SizedBox(height: 8),
          _tableRow(
            icon: Icons.favorite,
            color: Colors.deepPurple,
            label: l10n.compatCanReceiveFrom,
            types: canReceiveFrom,
          ),
        ],
      ),
    );
  }

  Widget _tableRow({
    required IconData icon,
    required Color color,
    required String label,
    required List<String> types,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: types
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: color.withOpacity(0.3)),
                        ),
                        child: Text(t,
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
