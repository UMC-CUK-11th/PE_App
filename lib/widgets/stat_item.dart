import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatItem extends StatelessWidget {
  const StatItem({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statBackground,
        border: Border.all(color: AppColors.softViolet),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 16 / 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              height: 28 / 22,
            ),
          ),
        ],
      ),
    );
  }
}
