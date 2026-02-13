import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textDim,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.mono.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
