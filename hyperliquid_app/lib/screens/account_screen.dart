import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../providers/account_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coin_tag.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/pnl_text.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/common/stat_chip.dart';
import '../widgets/wallet/wallet_modal.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
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

    return Consumer<AccountProvider>(
      builder: (context, ap, _) {
        if (ap.loading) return const SkeletonLoader(count: 6);

        if (ap.error != null && ap.data == null) {
          return EmptyState(
            message: ap.error!,
            icon: Icons.error_outline,
            actionLabel: 'Retry',
            onAction: ap.refresh,
          );
        }

        final data = ap.data;
        if (data == null) return const SkeletonLoader(count: 6);

        final ms = data.clearinghouse.marginSummary;

        return RefreshIndicator(
          onRefresh: ap.refresh,
          color: AppColors.accent,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              // Total Balance
              AppCard(
                title: 'Total Balance',
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fmtUsd(data.totalBalance),
                      style: AppTheme.mono.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    PnlText(
                      value: data.totalPnl,
                      showSign: true,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Perps ${fmtUsd(ms.accountValue)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Spot ${fmtUsd(data.spotUsdValue)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Perps Summary
              AppCard(
                title: 'Perps Account',
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      children: [
                        StatChip(
                          label: 'Account Value',
                          value: fmtUsd(ms.accountValue),
                        ),
                        const SizedBox(width: 8),
                        StatChip(
                          label: 'Unrealized PnL',
                          value: fmtUsd(data.totalPnl),
                          valueColor: pnlColor(data.totalPnl),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        StatChip(
                          label: 'Margin Used',
                          value: fmtUsd(ms.totalMarginUsed),
                        ),
                        const SizedBox(width: 8),
                        StatChip(
                          label: 'Withdrawable',
                          value: fmtUsd(data.clearinghouse.withdrawable),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Positions
              if (data.positions.isNotEmpty)
                AppCard(
                  title: 'Positions (${data.positions.length})',
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
                        DataColumn(label: Text('Size'), numeric: true),
                        DataColumn(label: Text('Entry'), numeric: true),
                        DataColumn(label: Text('Mark'), numeric: true),
                        DataColumn(label: Text('Liq'), numeric: true),
                        DataColumn(label: Text('uPnL'), numeric: true),
                        DataColumn(label: Text('Funding'), numeric: true),
                        DataColumn(label: Text('Lev'), numeric: true),
                      ],
                      rows: data.positions.map((p) {
                        return DataRow(
                          cells: [
                            DataCell(CoinTag(coin: p.coin)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: p.isLong
                                      ? AppColors.greenDim
                                      : AppColors.redDim,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.side,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: p.isLong
                                        ? AppColors.green
                                        : AppColors.red,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                fmtPrice(p.absSize, 4),
                                style: AppTheme.monoColored(pnlColor(p.szi)),
                              ),
                            ),
                            DataCell(
                              Text(
                                fmtPrice(p.entryPx, 2),
                                style: AppTheme.mono,
                              ),
                            ),
                            DataCell(
                              Text(
                                p.markPx != null
                                    ? fmtPrice(
                                        p.markPx!,
                                        autoPriceDecimals(p.markPx!),
                                      )
                                    : '\u2014',
                                style: AppTheme.mono,
                              ),
                            ),
                            DataCell(
                              Text(
                                p.liquidationPx != null
                                    ? fmtPrice(
                                        p.liquidationPx!,
                                        autoPriceDecimals(p.liquidationPx!),
                                      )
                                    : '\u2014',
                                style: AppTheme.monoColored(AppColors.red),
                              ),
                            ),
                            DataCell(PnlText(value: p.unrealizedPnl)),
                            DataCell(PnlText(value: p.cumFunding, decimals: 4)),
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
              // Spot Balances
              if (data.spotBalances.isNotEmpty)
                AppCard(
                  title: 'Spot Balances (${fmtUsd(data.spotUsdValue)})',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
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
                        DataColumn(label: Text('Total'), numeric: true),
                        DataColumn(label: Text('USD Value'), numeric: true),
                        DataColumn(label: Text('In Use'), numeric: true),
                      ],
                      rows: data.spotBalances.map((b) {
                        return DataRow(
                          cells: [
                            DataCell(CoinTag(coin: b.coin)),
                            DataCell(
                              Text(fmtPrice(b.total, 4), style: AppTheme.mono),
                            ),
                            DataCell(
                              Text(fmtUsd(b.usdValue), style: AppTheme.mono),
                            ),
                            DataCell(
                              Text(fmtPrice(b.hold, 4), style: AppTheme.mono),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (data.positions.isEmpty && data.spotBalances.isEmpty)
                const EmptyState(
                  message: 'No positions or balances',
                  icon: Icons.inbox_outlined,
                ),
            ],
          ),
        );
      },
    );
  }
}
