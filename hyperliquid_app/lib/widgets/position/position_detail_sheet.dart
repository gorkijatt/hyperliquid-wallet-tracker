import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/open_order.dart';
import '../../data/models/position.dart';
import '../common/pnl_text.dart';
import '../common/side_badge.dart';

class PositionDetailSheet extends StatelessWidget {
  final Position position;
  final List<OpenOrder> linkedOrders;

  const PositionDetailSheet({
    super.key,
    required this.position,
    this.linkedOrders = const [],
  });

  @override
  Widget build(BuildContext context) {
    final p = position;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.textDim,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Row(
            children: [
              Text(
                p.coin,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              SideBadge(label: p.side, isBuy: p.isLong),
              const Spacer(),
              Text(
                '${p.leverageValue ?? '\u2014'}x',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // PnL section
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unrealized PnL',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PnlText(
                    value: p.unrealizedPnl,
                    showSign: true,
                    showDollar: true,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (p.roe != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: p.roe! >= 0 ? AppColors.greenDim : AppColors.redDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ROE ${p.roe! >= 0 ? '+' : ''}${p.roe!.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.roe! >= 0 ? AppColors.green : AppColors.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          // Detail rows
          _row('Size', fmtPrice(p.absSize, 4)),
          _row('Notional Value', fmtUsd(p.notionalValue)),
          _row(
            'Entry Price',
            fmtPrice(p.entryPx, autoPriceDecimals(p.entryPx)),
          ),
          _row(
            'Mark Price',
            p.markPx != null
                ? fmtPrice(p.markPx!, autoPriceDecimals(p.markPx!))
                : '\u2014',
          ),
          _row(
            'Liquidation Price',
            p.liquidationPx != null
                ? fmtPrice(
                    p.liquidationPx!,
                    autoPriceDecimals(p.liquidationPx!),
                  )
                : '\u2014',
            color: AppColors.red,
          ),
          _pnlRow('Cumulative Funding', p.cumFunding),
          // Linked orders
          if (linkedOrders.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.border),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Linked TP/SL Orders',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...linkedOrders.map((o) {
              final trigPx =
                  double.tryParse(o.triggerPx ?? '') ??
                  double.tryParse(o.limitPx) ??
                  0;
              double? estPnl;
              if (trigPx != 0 && p.entryPx != 0 && p.absSize != 0) {
                estPnl = p.isLong
                    ? (trigPx - p.entryPx) * p.absSize
                    : (p.entryPx - trigPx) * p.absSize;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SideBadge(label: o.isBuy ? 'BUY' : 'SELL', isBuy: o.isBuy),
                    const SizedBox(width: 8),
                    Text(
                      '@ ${o.displayPrice}',
                      style: AppTheme.mono.copyWith(fontSize: 12),
                    ),
                    const Spacer(),
                    if (estPnl != null)
                      PnlText(value: estPnl, showSign: true, decimals: 2),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          // Trade link
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openTrade(p.coin),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text('Trade ${p.coin} on Hyperliquid'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTheme.mono.copyWith(
              fontSize: 13,
              color: color ?? AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pnlRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          PnlText(value: value, decimals: 4, showSign: true),
        ],
      ),
    );
  }

  void _openTrade(String coin) {
    launchUrl(
      Uri.parse('https://app.hyperliquid.xyz/trade/$coin'),
      mode: LaunchMode.externalApplication,
    );
  }
}
