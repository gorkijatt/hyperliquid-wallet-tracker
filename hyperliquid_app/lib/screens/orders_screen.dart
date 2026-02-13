import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../data/models/open_order.dart';
import '../data/models/position.dart';
import '../providers/orders_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coin_tag.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/last_updated.dart';
import '../widgets/common/pnl_text.dart';
import '../widgets/common/side_badge.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/wallet/wallet_modal.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sort state
  int _openSortCol = -1;
  bool _openSortAsc = true;
  int _fillSortCol = -1;
  bool _fillSortAsc = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double? _estimatedPnl(OpenOrder openOrder, List<Position> positions) {
    final pos = positions.where((p) => p.coin == openOrder.coin).toList();
    if (pos.isEmpty) return null;
    final p = pos.first;
    if (!(openOrder.isTrigger ||
        openOrder.reduceOnly ||
        openOrder.isPositionTpsl)) {
      return null;
    }

    final trigPx =
        double.tryParse(openOrder.triggerPx ?? '') ??
        double.tryParse(openOrder.limitPx) ??
        0;
    final size = p.absSize;
    if (p.entryPx == 0 || trigPx == 0 || size == 0) return null;

    return p.isLong ? (trigPx - p.entryPx) * size : (p.entryPx - trigPx) * size;
  }

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

  Widget _buildFilterChips(OrdersProvider op) {
    if (op.coins.length <= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: op.coins.map((coin) {
          final isActive = coin == op.coinFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                coin,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
              selected: isActive,
              onSelected: (_) => op.setCoinFilter(coin),
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

    return Consumer<OrdersProvider>(
      builder: (context, op, _) {
        if (op.loading) return const SkeletonLoader(count: 4);

        if (op.error != null && op.allData == null) {
          return EmptyState(
            message: op.error!,
            icon: Icons.error_outline,
            actionLabel: 'Retry',
            onAction: op.refresh,
          );
        }

        final data = op.data;
        if (data == null) return const SkeletonLoader(count: 4);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: RefreshIndicator(
            key: ValueKey(data.openOrders.length + data.fills.length),
            onRefresh: op.refresh,
            color: AppColors.accent,
            child: Column(
              children: [
                // Filter chips
                _buildFilterChips(op),
                // Tab bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.accentDim,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.accent,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(text: 'Open (${data.openOrders.length})'),
                      Tab(text: 'History (${data.fills.length})'),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Open orders
                      data.openOrders.isEmpty
                          ? const EmptyState(
                              message: 'No open orders',
                              icon: Icons.inbox_outlined,
                            )
                          : ListView(
                              children: [
                                AppCard(
                                  trailing: LastUpdated(time: op.lastUpdated),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 16,
                                      horizontalMargin: 16,
                                      headingRowHeight: 36,
                                      dataRowMinHeight: 44,
                                      dataRowMaxHeight: 56,
                                      sortColumnIndex: _openSortCol >= 0
                                          ? _openSortCol
                                          : null,
                                      sortAscending: _openSortAsc,
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
                                              _openSortCol = i;
                                              _openSortAsc = asc;
                                            });
                                          },
                                        ),
                                        const DataColumn(label: Text('Side')),
                                        DataColumn(
                                          label: const Text('Price'),
                                          numeric: true,
                                          onSort: (i, asc) {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              _openSortCol = i;
                                              _openSortAsc = asc;
                                            });
                                          },
                                        ),
                                        DataColumn(
                                          label: const Text('Size'),
                                          numeric: true,
                                          onSort: (i, asc) {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              _openSortCol = i;
                                              _openSortAsc = asc;
                                            });
                                          },
                                        ),
                                        const DataColumn(
                                          label: Text('Est. PnL'),
                                          numeric: true,
                                        ),
                                        const DataColumn(label: Text('Type')),
                                      ],
                                      rows: _sortOpenOrders(
                                        data.openOrders,
                                        data.positions,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      // Fills history
                      data.fills.isEmpty
                          ? const EmptyState(
                              message: 'No recent fills',
                              icon: Icons.inbox_outlined,
                            )
                          : ListView(
                              children: [
                                AppCard(
                                  trailing: LastUpdated(time: op.lastUpdated),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 16,
                                      horizontalMargin: 16,
                                      headingRowHeight: 36,
                                      dataRowMinHeight: 40,
                                      dataRowMaxHeight: 40,
                                      sortColumnIndex: _fillSortCol >= 0
                                          ? _fillSortCol
                                          : null,
                                      sortAscending: _fillSortAsc,
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
                                              _fillSortCol = i;
                                              _fillSortAsc = asc;
                                            });
                                          },
                                        ),
                                        const DataColumn(label: Text('Side')),
                                        const DataColumn(
                                          label: Text('Price'),
                                          numeric: true,
                                        ),
                                        const DataColumn(
                                          label: Text('Size'),
                                          numeric: true,
                                        ),
                                        const DataColumn(
                                          label: Text('Fee'),
                                          numeric: true,
                                        ),
                                        DataColumn(
                                          label: const Text('Time'),
                                          onSort: (i, asc) {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              _fillSortCol = i;
                                              _fillSortAsc = asc;
                                            });
                                          },
                                        ),
                                      ],
                                      rows: _sortFills(data.fills),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<DataRow> _sortOpenOrders(
    List<OpenOrder> orders,
    List<Position> positions,
  ) {
    final sorted = List<OpenOrder>.from(orders);
    if (_openSortCol >= 0) {
      sorted.sort((a, b) {
        int cmp;
        switch (_openSortCol) {
          case 0:
            cmp = a.coin.compareTo(b.coin);
          case 2:
            cmp = (double.tryParse(a.limitPx) ?? 0).compareTo(
              double.tryParse(b.limitPx) ?? 0,
            );
          case 3:
            cmp = (double.tryParse(a.sz) ?? 0).compareTo(
              double.tryParse(b.sz) ?? 0,
            );
          default:
            cmp = 0;
        }
        return _openSortAsc ? cmp : -cmp;
      });
    }
    return sorted.map((o) {
      final estPnl = _estimatedPnl(o, positions);
      return DataRow(
        cells: [
          DataCell(CoinTag(coin: o.coin)),
          DataCell(SideBadge(label: o.sideLabel, isBuy: o.sideClass == 'buy')),
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
          DataCell(Text(o.displaySize, style: AppTheme.mono)),
          DataCell(
            estPnl != null
                ? PnlText(value: estPnl)
                : const Text(
                    '\u2014',
                    style: TextStyle(color: AppColors.textDim),
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
    }).toList();
  }

  List<DataRow> _sortFills(List<dynamic> fills) {
    final sorted = List.from(fills);
    if (_fillSortCol >= 0) {
      sorted.sort((a, b) {
        int cmp;
        switch (_fillSortCol) {
          case 0:
            cmp = a.coin.compareTo(b.coin);
          case 5:
            cmp = a.time.compareTo(b.time);
          default:
            cmp = 0;
        }
        return _fillSortAsc ? cmp : -cmp;
      });
    }
    return sorted.map<DataRow>((f) {
      return DataRow(
        cells: [
          DataCell(CoinTag(coin: f.coin)),
          DataCell(SideBadge(label: f.isBuy ? 'Buy' : 'Sell', isBuy: f.isBuy)),
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
    }).toList();
  }
}
