import 'package:flutter/material.dart';
import '../../core/theme.dart';

class CoinTag extends StatelessWidget {
  final String coin;

  const CoinTag({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          coin,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}
