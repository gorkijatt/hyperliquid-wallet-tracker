import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../providers/trades_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coin_tag.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/side_badge.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/wallet/wallet_modal.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  void _openWalletModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const WalletModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WalletProvider>();
    if (!wp.hasWallet) {
      return EmptyState(
        message: 'No wallet added',
        icon: Icons.account_balance_wallet_outlined,
        actionLabel: 'Add Wallet',
        onAction: _openWalletModal,
      );
    }

    return Consumer<TradesProvider>(
      builder: (context, tp, _) {
        if (tp.loading) return const SkeletonLoader(count: 6);

        if (tp.error != null && tp.allFills.isEmpty) {
          return EmptyState(
            message: tp.error!,
            icon: Icons.error_outline,
            actionLabel: 'Retry',
            onAction: tp.refresh,
          );
        }

        if (tp.allFills.isEmpty) {
          return const EmptyState(
            message: 'No recent trades',
            icon: Icons.swap_horiz,
          );
        }

        final filtered = tp.fills;

        return RefreshIndicator(
          onRefresh: tp.refresh,
          color: AppColors.accent,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              // Filter chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  children: tp.coins.map((coin) {
                    final isActive = coin == tp.coinFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          coin,
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                        selected: isActive,
                        onSelected: (_) => tp.setCoinFilter(coin),
                        selectedColor: AppColors.accentDim,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: isActive
                              ? AppColors.accent.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    );
                  }).toList(),
                ),
              ),
              AppCard(
                title: 'Trades (${filtered.length})',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    headingRowHeight: 36,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 40,
                    headingTextStyle: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                    ),
                    columns: const [
                      DataColumn(label: Text('Coin')),
                      DataColumn(label: Text('Side')),
                      DataColumn(label: Text('Price'), numeric: true),
                      DataColumn(label: Text('Size'), numeric: true),
                      DataColumn(label: Text('Fee'), numeric: true),
                      DataColumn(label: Text('Time')),
                    ],
                    rows: filtered.map((f) {
                      return DataRow(
                        cells: [
                          DataCell(CoinTag(coin: f.coin)),
                          DataCell(
                            SideBadge(
                              label: f.isBuy ? 'Buy' : 'Sell',
                              isBuy: f.isBuy,
                            ),
                          ),
                          DataCell(Text(f.px, style: AppTheme.mono)),
                          DataCell(Text(f.sz, style: AppTheme.mono)),
                          DataCell(Text(f.fee, style: AppTheme.mono)),
                          DataCell(
                            Text(
                              fmtTime(f.time),
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
    );
  }
}
