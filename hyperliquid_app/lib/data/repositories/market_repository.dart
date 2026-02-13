import '../../core/constants.dart';
import '../models/market_coin.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class MarketRepository {
  final ApiService _api;
  final CacheService _cache;
  static const _cacheKey = 'market';

  MarketRepository(this._api, this._cache);

  List<MarketCoin>? getCached() => _cache.get<List<MarketCoin>>(_cacheKey);

  Future<List<MarketCoin>> fetchMarket() async {
    final results = await Future.wait([
      _api.fetchInfo('metaAndAssetCtxs'),
      _api.fetchInfo('allMids'),
    ]);

    final metaAndCtxs = results[0] as List<dynamic>;
    final mids = results[1] as Map<String, dynamic>;

    final meta = metaAndCtxs[0] as Map<String, dynamic>;
    final assetCtxs = metaAndCtxs[1] as List<dynamic>;
    final universe = (meta['universe'] as List<dynamic>?) ?? [];

    final coins = <MarketCoin>[];
    for (var i = 0; i < universe.length; i++) {
      final coin = universe[i] as Map<String, dynamic>;
      final name = coin['name'] as String;
      final mid = mids[name] != null
          ? double.tryParse(mids[name].toString())
          : null;

      double? prevDayPx;
      double? dayNtlVlm;
      String? fundingRate;
      if (i < assetCtxs.length) {
        final ctx = assetCtxs[i] as Map<String, dynamic>;
        prevDayPx = double.tryParse(ctx['prevDayPx']?.toString() ?? '');
        dayNtlVlm = double.tryParse(ctx['dayNtlVlm']?.toString() ?? '');
        fundingRate = ctx['funding']?.toString();
      }

      coins.add(
        MarketCoin(
          name: name,
          mid: mid,
          szDecimals: (coin['szDecimals'] as int?) ?? 0,
          prevDayPx: prevDayPx,
          dayNtlVlm: dayNtlVlm,
          fundingRate: fundingRate,
        ),
      );
    }

    _cache.set(_cacheKey, coins, marketCacheTtl);
    return coins;
  }
}
