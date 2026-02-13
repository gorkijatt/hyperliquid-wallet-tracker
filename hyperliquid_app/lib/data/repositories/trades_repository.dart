import '../../core/constants.dart';
import '../models/fill.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class TradesRepository {
  final ApiService _api;
  final CacheService _cache;

  TradesRepository(this._api, this._cache);

  String _cacheKey(String addr) => 'trades_${addr.substring(0, 10)}';

  List<Fill>? getCached(String address) =>
      _cache.get<List<Fill>>(_cacheKey(address));

  Future<List<Fill>> fetchTrades(String address) async {
    final data = await _api.fetchInfo('userFills', {'user': address});
    final fills = (data as List<dynamic>)
        .take(maxTrades)
        .map((f) => Fill.fromJson(f as Map<String, dynamic>))
        .toList();

    _cache.set(_cacheKey(address), fills, walletCacheTtl);
    return fills;
  }

  void clearCache(String address) {
    _cache.remove(_cacheKey(address));
  }
}
