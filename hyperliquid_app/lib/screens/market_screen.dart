import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../providers/market_provider.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coin_tag.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/skeleton_loader.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketProvider>(
      builder: (context, mp, _) {
        if (mp.loading) {
          return const SkeletonLoader(count: 8);
        }

        if (mp.error != null && mp.allCoins.isEmpty) {
          return EmptyState(
            message: mp.error!,
            icon: Icons.error_outline,
            actionLabel: 'Retry',
            onAction: () => mp.load(),
          );
        }

        final coins = mp.coins;

        return RefreshIndicator(
          onRefresh: () => mp.load(),
          color: AppColors.accent,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  onChanged: mp.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Search assets...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    suffixIcon: mp.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => mp.setSearchQuery(''),
                          )
                        : null,
                  ),
                ),
              ),
              AppCard(
                title: 'All Markets (${coins.length})',
                child: Column(
                  children: [
                    // Header row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              '#',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textDim,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Asset',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textDim,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Mid Price',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textDim,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              'SzDec',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textDim,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Rows
                    ...List.generate(coins.length, (i) {
                      final coin = coins[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: i < coins.length - 1
                              ? const Border(
                                  bottom: BorderSide(
                                    color: AppColors.borderSubtle,
                                    width: 0.5,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDim,
                                ),
                              ),
                            ),
                            Expanded(flex: 3, child: CoinTag(coin: coin.name)),
                            Expanded(
                              flex: 3,
                              child: Text(
                                coin.mid != null
                                    ? fmtPrice(
                                        coin.mid!,
                                        autoPriceDecimals(coin.mid!),
                                      )
                                    : '\u2014',
                                style: AppTheme.mono,
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                '${coin.szDecimals}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
