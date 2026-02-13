import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../providers/funding_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coin_tag.dart';
import '../widgets/common/empty_state.dart';
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

    return Consumer<FundingProvider>(
      builder: (context, fp, _) {
        if (fp.loading) return const SkeletonLoader(count: 6);

        if (fp.error != null && fp.entries.isEmpty) {
          return EmptyState(
            message: fp.error!,
            icon: Icons.error_outline,
            actionLabel: 'Retry',
            onAction: fp.refresh,
          );
        }

        if (fp.entries.isEmpty) {
          return const EmptyState(
            message: 'No funding payments in the last 7 days',
            icon: Icons.attach_money,
          );
        }

        return RefreshIndicator(
          onRefresh: fp.refresh,
          color: AppColors.accent,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              // 7-day summary
              AppCard(
                title: '7-Day Funding Summary',
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    StatChip(
                      label: 'Total Funding',
                      value: fmtUsd(fp.totalFunding, 4),
                      valueColor: pnlColor(fp.totalFunding),
                    ),
                    const SizedBox(width: 8),
                    StatChip(label: 'Payments', value: '${fp.entries.length}'),
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
                    headingTextStyle: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                    ),
                    columns: const [
                      DataColumn(label: Text('Coin')),
                      DataColumn(label: Text('Payment'), numeric: true),
                      DataColumn(label: Text('Rate'), numeric: true),
                      DataColumn(label: Text('Time')),
                    ],
                    rows: fp.entries.map((f) {
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
            ],
          ),
        );
      },
    );
  }
}
