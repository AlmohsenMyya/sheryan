import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/l10n/app_localizations.dart';
import 'package:sheryan/services/auth_service.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<String> labels;
  final List<IconData> icons;
  final List<Color> colors;
  final bool isWide;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.labels,
    required this.icons,
    required this.colors,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final sideWidth = isWide ? 210.0 : 68.0;

    return Container(
      width: sideWidth,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 26),
                ),
                if (isWide) ...[
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)!.superAdminLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.shade100),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: icons.length,
              itemBuilder: (ctx, i) {
                final isSelected = i == selectedIndex;
                final itemColor = isSelected ? colors[i] : Colors.grey[600]!;
                return GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 12 : 0,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? colors[i].withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected ? Border.all(color: colors[i].withOpacity(0.25)) : null,
                    ),
                    child: isWide
                        ? Row(
                            children: [
                              const SizedBox(width: 4),
                              Icon(icons[i], color: itemColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  labels[i],
                                  style: TextStyle(
                                    color: itemColor,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Center(child: Icon(icons[i], color: itemColor, size: 22)),
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: Colors.grey.shade100),
          GestureDetector(
            onTap: () async => await AuthService().logoutUser(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: isWide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.grey[500], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.logout,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    )
                  : Icon(Icons.logout_rounded, color: Colors.grey[500], size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
