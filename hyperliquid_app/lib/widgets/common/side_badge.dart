import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SideBadge extends StatelessWidget {
  final String label;
  final bool isBuy;

  const SideBadge({super.key, required this.label, required this.isBuy});

  @override
  Widget build(BuildContext context) {
    final color = isBuy ? AppColors.green : AppColors.red;
    final bgColor = isBuy ? AppColors.greenDim : AppColors.redDim;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
