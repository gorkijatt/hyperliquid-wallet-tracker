import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/account_provider.dart';
import '../providers/funding_provider.dart';
import '../providers/market_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/trades_provider.dart';
import '../widgets/common/account_peek.dart';
import '../widgets/wallet/wallet_chip.dart';
import 'account_screen.dart';
import 'funding_screen.dart';
import 'market_screen.dart';
import 'orders_screen.dart';
import 'report_screen.dart';
import 'trades_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.show_chart),
      selectedIcon: Icon(Icons.show_chart),
      label: 'Market',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Account',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Orders',
    ),
    NavigationDestination(
      icon: Icon(Icons.swap_horiz),
      selectedIcon: Icon(Icons.swap_horiz),
      label: 'Trades',
    ),
    NavigationDestination(
      icon: Icon(Icons.attach_money),
      selectedIcon: Icon(Icons.attach_money),
      label: 'Funding',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.show_chart),
      selectedIcon: Icon(Icons.show_chart),
      label: Text('Market'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: Text('Account'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: Text('Orders'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.swap_horiz),
      selectedIcon: Icon(Icons.swap_horiz),
      label: Text('Trades'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.attach_money),
      selectedIcon: Icon(Icons.attach_money),
      label: Text('Funding'),
    ),
  ];

  final _pages = const [
    MarketScreen(),
    AccountScreen(),
    OrdersScreen(),
    TradesScreen(),
    FundingScreen(),
  ];

  void _openReport() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ReportScreen()));
  }

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    _stopTimersForTab(_currentIndex);
    setState(() => _currentIndex = index);
    _startTimersForTab(index);
    _triggerLazyLoad(index);
  }

  void _stopTimersForTab(int index) {
    switch (index) {
      case 0:
        context.read<MarketProvider>().stopAutoRefresh();
      case 1:
        context.read<AccountProvider>().stopAutoRefresh();
      case 2:
        context.read<OrdersProvider>().stopAutoRefresh();
      case 3:
        context.read<TradesProvider>().stopAutoRefresh();
      case 4:
        context.read<FundingProvider>().stopAutoRefresh();
    }
  }

  void _startTimersForTab(int index) {
    switch (index) {
      case 0:
        context.read<MarketProvider>().startAutoRefresh();
      case 1:
        context.read<AccountProvider>().startAutoRefresh();
      case 2:
        context.read<OrdersProvider>().startAutoRefresh();
      case 3:
        context.read<TradesProvider>().startAutoRefresh();
      case 4:
        context.read<FundingProvider>().startAutoRefresh();
    }
  }

  void _triggerLazyLoad(int index) {
    switch (index) {
      case 1:
        context.read<AccountProvider>().checkAndLoad();
      case 2:
        context.read<OrdersProvider>().checkAndLoad();
      case 3:
        context.read<TradesProvider>().checkAndLoad();
      case 4:
        context.read<FundingProvider>().checkAndLoad();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimersForTab(0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimersForTab(_currentIndex);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopTimersForTab(_currentIndex);
    } else if (state == AppLifecycleState.resumed) {
      _startTimersForTab(_currentIndex);
      _triggerLazyLoad(_currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 800;

        final appBar = AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view_rounded, size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              const Flexible(
                child: Text('Hyperliquid', overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentDim,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'EXPLORER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.description_outlined, size: 20),
              tooltip: 'Report',
              onPressed: _openReport,
            ),
            const WalletChip(),
            const SizedBox(width: 8),
          ],
        );

        final showPeek = _currentIndex >= 2; // Orders, Trades, Funding
        final body = Column(
          children: [
            if (showPeek) AccountPeek(onTap: () => _onTabChanged(1)),
            Expanded(
              child: IndexedStack(index: _currentIndex, children: _pages),
            ),
          ],
        );

        if (useRail) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabChanged,
                  labelType: NavigationRailLabelType.all,
                  destinations: _railDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: appBar,
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabChanged,
            height: 65,
            destinations: _destinations,
          ),
        );
      },
    );
  }
}
