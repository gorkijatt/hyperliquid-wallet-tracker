import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils/formatters.dart';
import '../providers/market_provider.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/coin_tag.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/last_updated.dart';
import '../widgets/common/skeleton_loader.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  bool _showExtra = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().load();
    });
  }

  Widget _sortIcon(String column, MarketProvider mp) {
    if (mp.sortColumn != column) {
      return const Icon(Icons.unfold_more, size: 14, color: AppColors.textDim);
    }
    return Icon(
      mp.sortAscending ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
      size: 14,
      color: AppColors.accent,
    );
  }

  Widget _sortableHeader(
    String label,
    String column,
    MarketProvider mp, {
    TextAlign textAlign = TextAlign.left,
    int flex = 3,
  }) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          mp.setSort(column);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: textAlign == TextAlign.right
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: mp.sortColumn == column
                    ? AppColors.accent
                    : AppColors.textDim,
                fontWeight: FontWeight.w600,
              ),
            ),
            _sortIcon(column, mp),
          ],
        ),
      ),
    );
  }

  String _fmtVolume(double vol) {
    if (vol >= 1e9) return '\$${(vol / 1e9).toStringAsFixed(1)}B';
    if (vol >= 1e6) return '\$${(vol / 1e6).toStringAsFixed(1)}M';
    if (vol >= 1e3) return '\$${(vol / 1e3).toStringAsFixed(0)}K';
    return '\$${vol.toStringAsFixed(0)}';
  }

  String _fmtFundingRate(String rate) {
    final val = double.tryParse(rate);
    if (val == null) return rate;
    final pct = val * 100;
    return '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(4)}%';
  }

  Color _fundingColor(String? rate) {
    if (rate == null) return AppColors.textDim;
    final val = double.tryParse(rate);
    if (val == null) return AppColors.textDim;
    if (val > 0) return AppColors.green;
    if (val < 0) return AppColors.red;
    return AppColors.textSecondary;
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

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: RefreshIndicator(
            key: ValueKey(coins.length),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _showExtra = !_showExtra);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _showExtra
                                ? AppColors.accentDim
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _showExtra
                                  ? AppColors.accent.withValues(alpha: 0.3)
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune,
                                size: 12,
                                color: _showExtra
                                    ? AppColors.accent
                                    : AppColors.textDim,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Vol/FR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _showExtra
                                      ? AppColors.accent
                                      : AppColors.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      LastUpdated(time: mp.lastUpdated),
                    ],
                  ),
                  child: _showExtra
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: _buildMarketTable(coins, mp),
                        )
                      : _buildMarketTable(coins, mp),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarketTable(List coins, MarketProvider mp) {
    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const SizedBox(
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
              _sortableHeader('Asset', 'name', mp),
              _sortableHeader(
                'Mid Price',
                'price',
                mp,
                textAlign: TextAlign.right,
              ),
              _sortableHeader(
                '24h %',
                'change',
                mp,
                textAlign: TextAlign.right,
                flex: 2,
              ),
              if (_showExtra) ...[
                _sortableHeader(
                  'Volume',
                  'volume',
                  mp,
                  textAlign: TextAlign.right,
                  flex: 3,
                ),
                _sortableHeader(
                  'Fund Rate',
                  'funding',
                  mp,
                  textAlign: TextAlign.right,
                  flex: 2,
                ),
              ],
            ],
          ),
        ),
        // Rows
        ...List.generate(coins.length, (i) {
          final coin = coins[i];
          final change = coin.change24h;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        ? fmtPrice(coin.mid!, autoPriceDecimals(coin.mid!))
                        : '\u2014',
                    style: AppTheme.mono,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    change != null
                        ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%'
                        : '\u2014',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: change != null
                          ? (change >= 0 ? AppColors.green : AppColors.red)
                          : AppColors.textDim,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                if (_showExtra) ...[
                  Expanded(
                    flex: 3,
                    child: Text(
                      coin.dayNtlVlm != null
                          ? _fmtVolume(coin.dayNtlVlm!)
                          : '\u2014',
                      style: AppTheme.mono.copyWith(fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      coin.fundingRate != null
                          ? _fmtFundingRate(coin.fundingRate!)
                          : '\u2014',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _fundingColor(coin.fundingRate),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
