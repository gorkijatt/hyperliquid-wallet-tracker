import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../providers/report_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coin_tag.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/pnl_text.dart';
import '../widgets/common/side_badge.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/common/stat_chip.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallets = context.read<WalletProvider>().wallets;
      context.read<ReportProvider>().load(wallets);
    });
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied: $address')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyperliquid Report'),
        actions: [
          Consumer<ReportProvider>(
            builder: (_, rp, _) {
              if (rp.btcPrice != null) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '\u20BF',
                        style: TextStyle(
                          color: Color(0xFFF7931A),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fmtUsd(rp.btcPrice!),
                        style: AppTheme.mono.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, rp, _) {
          if (rp.loading) return const SkeletonLoader(count: 6);

          if (rp.error != null) {
            return EmptyState(
              message: rp.error!,
              icon: Icons.error_outline,
              actionLabel: 'Retry',
              onAction: () {
                final wallets = context.read<WalletProvider>().wallets;
                rp.load(wallets);
              },
            );
          }

          final wallets = context.read<WalletProvider>().wallets;

          return RefreshIndicator(
            onRefresh: () => rp.load(wallets),
            color: AppColors.accent,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // Summary cards
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        children: [
                          StatChip(
                            label: 'Wallets',
                            value: '${wallets.length}',
                          ),
                          const SizedBox(width: 8),
                          StatChip(
                            label: 'Positions',
                            value: '${rp.positions.length}',
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          StatChip(
                            label: 'Orders',
                            value: '${rp.orders.length}',
                          ),
                          const SizedBox(width: 8),
                          StatChip(
                            label: 'Total uPnL',
                            value: fmtPnl(rp.totalUpnl),
                            valueColor: pnlColor(rp.totalUpnl),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Positions section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      const Text(
                        'Open Positions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: rp.toggleView,
                        child: Text(rp.showCards ? 'Table' : 'Cards'),
                      ),
                    ],
                  ),
                ),
                if (rp.positions.isEmpty)
                  const EmptyState(
                    message: 'No open positions',
                    icon: Icons.inbox_outlined,
                  ),
                if (rp.positions.isNotEmpty && !rp.showCards)
                  AppCard(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 14,
                        horizontalMargin: 14,
                        headingRowHeight: 36,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 40,
                        headingTextStyle: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDim,
                          fontWeight: FontWeight.w600,
                        ),
                        columns: const [
                          DataColumn(label: Text('Wallet')),
                          DataColumn(label: Text('Coin')),
                          DataColumn(label: Text('Side')),
                          DataColumn(label: Text('Size'), numeric: true),
                          DataColumn(label: Text('Entry'), numeric: true),
                          DataColumn(label: Text('Mark'), numeric: true),
                          DataColumn(label: Text('Liq'), numeric: true),
                          DataColumn(label: Text('uPnL'), numeric: true),
                          DataColumn(label: Text('Target'), numeric: true),
                          DataColumn(label: Text('Est. PnL'), numeric: true),
                          DataColumn(label: Text('Funding'), numeric: true),
                          DataColumn(label: Text('Lev'), numeric: true),
                        ],
                        rows: rp.positions.map((rp2) {
                          final p = rp2.position;
                          // Find target/estPnl from linked orders
                          final linkedOrders = rp.orders
                              .where(
                                (o) =>
                                    o.order.coin == p.coin &&
                                    o.walletAddress == rp2.walletAddress &&
                                    (o.order.isTrigger ||
                                        o.order.reduceOnly ||
                                        o.order.isPositionTpsl),
                              )
                              .toList();
                          final targets = linkedOrders
                              .map(
                                (o) =>
                                    double.tryParse(o.order.triggerPx ?? '') ??
                                    double.tryParse(o.order.limitPx) ??
                                    0,
                              )
                              .where((t) => t != 0)
                              .toList();
                          double? estPnl;
                          if (targets.isNotEmpty &&
                              p.entryPx != 0 &&
                              p.absSize != 0) {
                            estPnl = p.isLong
                                ? (targets.first - p.entryPx) * p.absSize
                                : (p.entryPx - targets.first) * p.absSize;
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                InkWell(
                                  onTap: () => _copyAddress(rp2.walletAddress),
                                  child: Text(
                                    rp2.walletLabel,
                                    style: const TextStyle(
                                      color: Color(0xFF58A6FF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(CoinTag(coin: p.coin)),
                              DataCell(
                                SideBadge(label: p.side, isBuy: p.isLong),
                              ),
                              DataCell(
                                Text(
                                  fmtPrice(p.absSize, 4),
                                  style: AppTheme.mono,
                                ),
                              ),
                              DataCell(
                                Text(
                                  fmtPrice(p.entryPx, 4),
                                  style: AppTheme.mono,
                                ),
                              ),
                              DataCell(
                                Text(
                                  p.markPx != null
                                      ? fmtPrice(p.markPx!, 4)
                                      : '\u2014',
                                  style: AppTheme.mono,
                                ),
                              ),
                              DataCell(
                                Text(
                                  p.liquidationPx != null
                                      ? fmtPrice(p.liquidationPx!, 2)
                                      : '\u2014',
                                  style: AppTheme.mono,
                                ),
                              ),
                              DataCell(
                                PnlText(value: p.unrealizedPnl, showSign: true),
                              ),
                              DataCell(
                                Text(
                                  targets.isNotEmpty
                                      ? targets
                                            .map((t) => fmtPrice(t, 2))
                                            .join(', ')
                                      : '\u2014',
                                  style: AppTheme.mono,
                                ),
                              ),
                              DataCell(
                                estPnl != null
                                    ? PnlText(value: estPnl, showSign: true)
                                    : const Text(
                                        '\u2014',
                                        style: TextStyle(
                                          color: AppColors.textDim,
                                        ),
                                      ),
                              ),
                              DataCell(
                                PnlText(value: p.cumFunding, decimals: 2),
                              ),
                              DataCell(
                                Text(
                                  '${p.leverageValue ?? '\u2014'}x',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                if (rp.positions.isNotEmpty && rp.showCards)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: rp.positions.map((rp2) {
                        final p = rp2.position;
                        // Find target/estPnl from linked orders
                        final linkedOrders = rp.orders
                            .where(
                              (o) =>
                                  o.order.coin == p.coin &&
                                  o.walletAddress == rp2.walletAddress &&
                                  (o.order.isTrigger ||
                                      o.order.reduceOnly ||
                                      o.order.isPositionTpsl),
                            )
                            .toList();
                        final targets = linkedOrders
                            .map(
                              (o) =>
                                  double.tryParse(o.order.triggerPx ?? '') ??
                                  double.tryParse(o.order.limitPx) ??
                                  0,
                            )
                            .where((t) => t != 0)
                            .toList();
                        double? estPnl;
                        if (targets.isNotEmpty &&
                            p.entryPx != 0 &&
                            p.absSize != 0) {
                          estPnl = p.isLong
                              ? (targets.first - p.entryPx) * p.absSize
                              : (p.entryPx - targets.first) * p.absSize;
                        }

                        return SizedBox(
                          width: 280,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () => _copyAddress(rp2.walletAddress),
                                  child: Text(
                                    rp2.walletLabel,
                                    style: const TextStyle(
                                      color: Color(0xFF58A6FF),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      p.coin,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SideBadge(label: p.side, isBuy: p.isLong),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _cardRow('Size', fmtPrice(p.absSize, 4)),
                                _cardRow(
                                  'uPnL',
                                  fmtPnl(p.unrealizedPnl),
                                  color: pnlColor(p.unrealizedPnl),
                                ),
                                _cardRow('Entry', fmtPrice(p.entryPx, 4)),
                                _cardRow(
                                  'Liq',
                                  p.liquidationPx != null
                                      ? fmtPrice(p.liquidationPx!, 2)
                                      : '\u2014',
                                ),
                                if (targets.isNotEmpty)
                                  _cardRow(
                                    'Target',
                                    targets
                                        .map((t) => fmtPrice(t, 2))
                                        .join(', '),
                                  ),
                                if (estPnl != null)
                                  _cardRow(
                                    'Est. PnL',
                                    fmtPnl(estPnl),
                                    color: pnlColor(estPnl),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Orders section
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 4),
                  child: Text(
                    'Open Orders',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                if (rp.orders.isEmpty)
                  const EmptyState(
                    message: 'No open orders',
                    icon: Icons.inbox_outlined,
                  ),
                if (rp.orders.isNotEmpty)
                  AppCard(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 14,
                        horizontalMargin: 14,
                        headingRowHeight: 36,
                        dataRowMinHeight: 44,
                        dataRowMaxHeight: 56,
                        headingTextStyle: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDim,
                          fontWeight: FontWeight.w600,
                        ),
                        columns: const [
                          DataColumn(label: Text('Wallet')),
                          DataColumn(label: Text('Coin')),
                          DataColumn(label: Text('Side')),
                          DataColumn(label: Text('Price'), numeric: true),
                          DataColumn(label: Text('Size'), numeric: true),
                          DataColumn(label: Text('Est. PnL'), numeric: true),
                          DataColumn(label: Text('Type')),
                        ],
                        rows: rp.orders.map((ro) {
                          final o = ro.order;
                          final estPnl = rp.estimatedPnl(ro);
                          return DataRow(
                            cells: [
                              DataCell(
                                InkWell(
                                  onTap: () => _copyAddress(ro.walletAddress),
                                  child: Text(
                                    ro.walletLabel,
                                    style: const TextStyle(
                                      color: Color(0xFF58A6FF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(CoinTag(coin: o.coin)),
                              DataCell(
                                SideBadge(
                                  label: o.isBuy ? 'BUY' : 'SELL',
                                  isBuy: o.isBuy,
                                ),
                              ),
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(o.displayPrice, style: AppTheme.mono),
                                    if (o.triggerInfo != null)
                                      Text(
                                        'trigger: ${o.triggerInfo}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textDim,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(o.displaySize, style: AppTheme.mono),
                              ),
                              DataCell(
                                estPnl != null
                                    ? PnlText(value: estPnl, showSign: true)
                                    : const Text(
                                        '\u2014',
                                        style: TextStyle(
                                          color: AppColors.textDim,
                                        ),
                                      ),
                              ),
                              DataCell(
                                Text(
                                  o.orderType ?? 'Limit',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cardRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
            style: TextStyle(fontSize: 13, color: color ?? AppColors.text),
          ),
        ],
      ),
    );
  }
}
