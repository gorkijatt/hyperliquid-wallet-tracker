import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/utils/formatters.dart';

class PnlText extends StatelessWidget {
  final double value;
  final int decimals;
  final bool showSign;
  final bool showDollar;
  final TextStyle? style;
  final bool mono;

  const PnlText({
    super.key,
    required this.value,
    this.decimals = 2,
    this.showSign = false,
    this.showDollar = true,
    this.style,
    this.mono = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = pnlColor(value);
    final text = showSign
        ? fmtPnl(value, decimals)
        : (showDollar ? fmtUsd(value, decimals) : fmtPrice(value, decimals));
    final baseStyle = mono
        ? AppTheme.monoColored(color)
        : TextStyle(color: color);

    return Text(text, style: (style ?? const TextStyle()).merge(baseStyle));
  }
}
