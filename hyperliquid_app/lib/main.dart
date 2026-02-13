import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/funding_repository.dart';
import 'data/repositories/market_repository.dart';
import 'data/repositories/orders_repository.dart';
import 'data/repositories/trades_repository.dart';
import 'data/services/api_service.dart';
import 'data/services/cache_service.dart';
import 'providers/account_provider.dart';
import 'providers/funding_provider.dart';
import 'providers/market_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/report_provider.dart';
import 'providers/trades_provider.dart';
import 'providers/wallet_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final cacheService = CacheService();

  final marketRepo = MarketRepository(apiService, cacheService);
  final accountRepo = AccountRepository(apiService, cacheService);
  final ordersRepo = OrdersRepository(apiService, cacheService);
  final tradesRepo = TradesRepository(apiService, cacheService);
  final fundingRepo = FundingRepository(apiService, cacheService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()..init()),
        ChangeNotifierProvider(create: (_) => MarketProvider(marketRepo)),
        ChangeNotifierProxyProvider<WalletProvider, AccountProvider>(
          create: (_) => AccountProvider(accountRepo),
          update: (_, wp, ap) => ap!..onWalletChanged(wp.activeAddress),
        ),
        ChangeNotifierProxyProvider<WalletProvider, OrdersProvider>(
          create: (_) => OrdersProvider(ordersRepo),
          update: (_, wp, op) => op!..onWalletChanged(wp.activeAddress),
        ),
        ChangeNotifierProxyProvider<WalletProvider, TradesProvider>(
          create: (_) => TradesProvider(tradesRepo),
          update: (_, wp, tp) => tp!..onWalletChanged(wp.activeAddress),
        ),
        ChangeNotifierProxyProvider<WalletProvider, FundingProvider>(
          create: (_) => FundingProvider(fundingRepo),
          update: (_, wp, fp) => fp!..onWalletChanged(wp.activeAddress),
        ),
        ChangeNotifierProvider(create: (_) => ReportProvider(apiService)),
      ],
      child: const HyperliquidApp(),
    ),
  );
}
