import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../data/models/position.dart';
import '../providers/account_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coin_tag.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/last_updated.dart';
import '../widgets/common/pnl_text.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/common/stat_chip.dart';
import '../widgets/position/position_card.dart';
import '../widgets/position/position_detail_sheet.dart';
import '../widgets/wallet/wallet_modal.dart';
import 'report_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Sort state for positions table
  int _sortColumnIndex = -1;
  bool _sortAscending = true;

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

  void _openPositionDetail(Position p) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PositionDetailSheet(position: p),
    );
  }

  void _openReport() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReportScreen()));
  }

  List<Position> _sortPositions(List<Position> positions) {
    if (_sortColumnIndex < 0) return positions;
    final sorted = List<Position>.from(positions);
    sorted.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0: // Coin
          cmp = a.coin.compareTo(b.coin);
        case 2: // Size
          cmp = a.absSize.compareTo(b.absSize);
        case 3: // Entry
          cmp = a.entryPx.compareTo(b.entryPx);
        case 4: // Mark
          cmp = (a.markPx ?? 0).compareTo(b.markPx ?? 0);
        case 5: // uPnL
          cmp = a.unrealizedPnl.compareTo(b.unrealizedPnl);
        case 6: // ROE
          cmp = (a.roe ?? -999).compareTo(b.roe ?? -999);
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  void _onSort(int columnIndex, bool ascending) {
    HapticFeedback.lightImpact();
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
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
        final isMobile = MediaQuery.of(context).size.width < 600;
        final positions = _sortPositions(data.positions);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: RefreshIndicator(
            key: ValueKey(data.totalBalance),
            onRefresh: ap.refresh,
            color: AppColors.accent,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Total Balance
                AppCard(
                  title: 'Total Balance',
                  trailing: LastUpdated(time: ap.lastUpdated),
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
                // View Report banner
                GestureDetector(
                  onTap: _openReport,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'View Multi-Wallet Report',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
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
                if (positions.isNotEmpty && isMobile) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text(
                      'Positions (${positions.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  ...positions.map(
                    (p) => PositionCard(
                      position: p,
                      onTap: () => _openPositionDetail(p),
                    ),
                  ),
                ],
                if (positions.isNotEmpty && !isMobile)
                  AppCard(
                    title: 'Positions (${positions.length})',
                    trailing: LastUpdated(time: ap.lastUpdated),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 16,
                        horizontalMargin: 16,
                        headingRowHeight: 36,
                        dataRowMinHeight: 40,
                        dataRowMaxHeight: 40,
                        sortColumnIndex: _sortColumnIndex >= 0
                            ? _sortColumnIndex
                            : null,
                        sortAscending: _sortAscending,
                        headingTextStyle: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDim,
                          fontWeight: FontWeight.w600,
                        ),
                        columns: [
                          DataColumn(
                            label: const Text('Coin'),
                            onSort: _onSort,
                          ),
                          const DataColumn(label: Text('Side')),
                          DataColumn(
                            label: const Text('Size'),
                            numeric: true,
                            onSort: _onSort,
                          ),
                          DataColumn(
                            label: const Text('Entry'),
                            numeric: true,
                            onSort: _onSort,
                          ),
                          DataColumn(
                            label: const Text('Mark'),
                            numeric: true,
                            onSort: _onSort,
                          ),
                          DataColumn(
                            label: const Text('uPnL'),
                            numeric: true,
                            onSort: _onSort,
                          ),
                          DataColumn(
                            label: const Text('ROE'),
                            numeric: true,
                            onSort: _onSort,
                          ),
                          const DataColumn(label: Text('Lev'), numeric: true),
                        ],
                        rows: positions.map((p) {
                          return DataRow(
                            onSelectChanged: (_) => _openPositionDetail(p),
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
                                PnlText(value: p.unrealizedPnl, showSign: true),
                              ),
                              DataCell(
                                p.roe != null
                                    ? Text(
                                        '${p.roe! >= 0 ? '+' : ''}${p.roe!.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: pnlColor(p.roe!),
                                        ),
                                      )
                                    : const Text(
                                        '\u2014',
                                        style: TextStyle(
                                          color: AppColors.textDim,
                                        ),
                                      ),
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
                                Text(
                                  fmtPrice(b.total, 4),
                                  style: AppTheme.mono,
                                ),
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
          ),
        );
      },
    );
  }
}
