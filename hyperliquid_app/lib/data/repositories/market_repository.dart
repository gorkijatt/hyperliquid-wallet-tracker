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
      _api.fetchInfo('allMids'),
      _api.fetchInfo('meta'),
    ]);
    final mids = results[0] as Map<String, dynamic>;
    final meta = results[1] as Map<String, dynamic>;
    final universe = (meta['universe'] as List<dynamic>?) ?? [];

    final coins = universe.map((coin) {
      final name = coin['name'] as String;
      final mid = mids[name] != null
          ? double.tryParse(mids[name].toString())
          : null;
      return MarketCoin(
        name: name,
        mid: mid,
        szDecimals: (coin['szDecimals'] as int?) ?? 0,
      );
    }).toList();

    _cache.set(_cacheKey, coins, marketCacheTtl);
    return coins;
  }
}
