import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../providers/funding_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coin_tag.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/last_updated.dart';
import '../widgets/common/pnl_text.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/common/stat_chip.dart';
import '../widgets/wallet/wallet_modal.dart';

class FundingScreen extends StatefulWidget {
  const FundingScreen({super.key});

  @override
  State<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends State<FundingScreen> {
  int _sortCol = -1;
  bool _sortAsc = true;

  void _openWalletModal() {
    HapticFeedback.mediumImpact();
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

    return Consumer<FundingProvider>(
      builder: (context, fp, _) {
        if (fp.loading) return const SkeletonLoader(count: 6);

        if (fp.error != null && fp.allEntries.isEmpty) {
          return EmptyState(
            message: fp.error!,
            icon: Icons.error_outline,
            actionLabel: 'Retry',
            onAction: fp.refresh,
          );
        }

        if (fp.allEntries.isEmpty) {
          return const EmptyState(
            message: 'No funding payments in the last 7 days',
            icon: Icons.attach_money,
          );
        }

        final entries = fp.entries;
        final sorted = List.from(entries);
        if (_sortCol >= 0) {
          sorted.sort((a, b) {
            int cmp;
            switch (_sortCol) {
              case 0:
                cmp = a.coin.compareTo(b.coin);
              case 1:
                cmp = a.usdcValue.compareTo(b.usdcValue);
              case 3:
                cmp = a.time.compareTo(b.time);
              default:
                cmp = 0;
            }
            return _sortAsc ? cmp : -cmp;
          });
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: RefreshIndicator(
            key: ValueKey(entries.length),
            onRefresh: fp.refresh,
            color: AppColors.accent,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Coin filter chips
                if (fp.coins.length > 1)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      children: fp.coins.map((coin) {
                        final isActive = coin == fp.coinFilter;
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
                            onSelected: (_) => fp.setCoinFilter(coin),
                            selectedColor: AppColors.accentDim,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: isActive
                                  ? AppColors.accent.withValues(alpha: 0.3)
                                  : AppColors.border,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                // 7-day summary
                AppCard(
                  title: '7-Day Funding Summary',
                  trailing: LastUpdated(time: fp.lastUpdated),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      StatChip(
                        label: 'Total Funding',
                        value: fmtUsd(fp.totalFunding, 4),
                        valueColor: pnlColor(fp.totalFunding),
                      ),
                      const SizedBox(width: 8),
                      StatChip(label: 'Payments', value: '${entries.length}'),
                    ],
                  ),
                ),
                // Funding history
                AppCard(
                  title: 'Funding History',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      horizontalMargin: 16,
                      headingRowHeight: 36,
                      dataRowMinHeight: 40,
                      dataRowMaxHeight: 40,
                      sortColumnIndex: _sortCol >= 0 ? _sortCol : null,
                      sortAscending: _sortAsc,
                      headingTextStyle: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w600,
                      ),
                      columns: [
                        DataColumn(
                          label: const Text('Coin'),
                          onSort: (i, asc) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _sortCol = i;
                              _sortAsc = asc;
                            });
                          },
                        ),
                        DataColumn(
                          label: const Text('Payment'),
                          numeric: true,
                          onSort: (i, asc) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _sortCol = i;
                              _sortAsc = asc;
                            });
                          },
                        ),
                        const DataColumn(label: Text('Rate'), numeric: true),
                        DataColumn(
                          label: const Text('Time'),
                          onSort: (i, asc) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _sortCol = i;
                              _sortAsc = asc;
                            });
                          },
                        ),
                      ],
                      rows: sorted.map<DataRow>((f) {
                        return DataRow(
                          cells: [
                            DataCell(CoinTag(coin: f.coin)),
                            DataCell(PnlText(value: f.usdcValue, decimals: 4)),
                            DataCell(Text(f.fundingRate, style: AppTheme.mono)),
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
                // Load More
                if (fp.hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: fp.loadingMore ? null : fp.loadMore,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: BorderSide(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: fp.loadingMore
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accent,
                                ),
                              )
                            : const Text('Load More'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
