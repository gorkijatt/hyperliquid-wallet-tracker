import 'package:flutter/material.dart';
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

    return Consumer<OrdersProvider>(
      builder: (context, op, _) {
        if (op.loading) return const SkeletonLoader(count: 4);

        if (op.error != null && op.data == null) {
          return EmptyState(
            message: op.error!,
            icon: Icons.error_outline,
            actionLabel: 'Retry',
            onAction: op.refresh,
          );
        }

        final data = op.data;
        if (data == null) return const SkeletonLoader(count: 4);

        return RefreshIndicator(
          onRefresh: op.refresh,
          color: AppColors.accent,
          child: Column(
            children: [
              // Tab bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 16,
                                    horizontalMargin: 16,
                                    headingRowHeight: 36,
                                    dataRowMinHeight: 44,
                                    dataRowMaxHeight: 56,
                                    headingTextStyle: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textDim,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('Coin')),
                                      DataColumn(label: Text('Side')),
                                      DataColumn(
                                        label: Text('Price'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('Size'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('Est. PnL'),
                                        numeric: true,
                                      ),
                                      DataColumn(label: Text('Type')),
                                    ],
                                    rows: data.openOrders.map((o) {
                                      final estPnl = _estimatedPnl(
                                        o,
                                        data.positions,
                                      );
                                      return DataRow(
                                        cells: [
                                          DataCell(CoinTag(coin: o.coin)),
                                          DataCell(
                                            SideBadge(
                                              label: o.sideLabel,
                                              isBuy: o.sideClass == 'buy',
                                            ),
                                          ),
                                          DataCell(
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  o.displayPrice,
                                                  style: AppTheme.mono,
                                                ),
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
                                            Text(
                                              o.displaySize,
                                              style: AppTheme.mono,
                                            ),
                                          ),
                                          DataCell(
                                            estPnl != null
                                                ? PnlText(value: estPnl)
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
                    // Fills history
                    data.fills.isEmpty
                        ? const EmptyState(
                            message: 'No recent fills',
                            icon: Icons.inbox_outlined,
                          )
                        : ListView(
                            children: [
                              AppCard(
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
                                      DataColumn(
                                        label: Text('Price'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('Size'),
                                        numeric: true,
                                      ),
                                      DataColumn(
                                        label: Text('Fee'),
                                        numeric: true,
                                      ),
                                      DataColumn(label: Text('Time')),
                                    ],
                                    rows: data.fills.map((f) {
                                      return DataRow(
                                        cells: [
                                          DataCell(CoinTag(coin: f.coin)),
                                          DataCell(
                                            SideBadge(
                                              label: f.isBuy ? 'Buy' : 'Sell',
                                              isBuy: f.isBuy,
                                            ),
                                          ),
                                          DataCell(
                                            Text(f.px, style: AppTheme.mono),
                                          ),
                                          DataCell(
                                            Text(f.sz, style: AppTheme.mono),
                                          ),
                                          DataCell(
                                            Text(f.fee, style: AppTheme.mono),
                                          ),
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
