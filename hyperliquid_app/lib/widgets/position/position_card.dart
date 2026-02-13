import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/position.dart';
import '../common/pnl_text.dart';
import '../common/side_badge.dart';

class PositionCard extends StatelessWidget {
  final Position position;
  final VoidCallback? onTap;

  const PositionCard({super.key, required this.position, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = position;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Coin + Side
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      p.coin,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SideBadge(label: p.side, isBuy: p.isLong),
                  ],
                ),
                Text(
                  '${p.leverageValue ?? '\u2014'}x',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // uPnL prominently
            Row(
              children: [
                PnlText(
                  value: p.unrealizedPnl,
                  showSign: true,
                  showDollar: true,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (p.roe != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.roe! >= 0
                          ? AppColors.greenDim
                          : AppColors.redDim,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${p.roe! >= 0 ? '+' : ''}${p.roe!.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.roe! >= 0 ? AppColors.green : AppColors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Price row
            Row(
              children: [
                _infoCol(
                  'Entry',
                  fmtPrice(p.entryPx, autoPriceDecimals(p.entryPx)),
                ),
                _infoCol(
                  'Mark',
                  p.markPx != null
                      ? fmtPrice(p.markPx!, autoPriceDecimals(p.markPx!))
                      : '\u2014',
                ),
                _infoCol(
                  'Liq',
                  p.liquidationPx != null
                      ? fmtPrice(
                          p.liquidationPx!,
                          autoPriceDecimals(p.liquidationPx!),
                        )
                      : '\u2014',
                  color: AppColors.red,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Size row
            Row(
              children: [
                _infoCol('Size', fmtPrice(p.absSize, 4)),
                _infoCol('Notional', fmtUsd(p.notionalValue)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCol(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textDim),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTheme.mono.copyWith(
              fontSize: 12,
              color: color ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
