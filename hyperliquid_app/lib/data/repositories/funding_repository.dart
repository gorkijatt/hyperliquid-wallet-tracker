import '../../core/constants.dart';
import '../models/funding_entry.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class FundingRepository {
  final ApiService _api;
  final CacheService _cache;

  FundingRepository(this._api, this._cache);

  String _cacheKey(String addr) => 'funding_${addr.substring(0, 10)}';

  List<FundingEntry>? getCached(String address) =>
      _cache.get<List<FundingEntry>>(_cacheKey(address));

  Future<List<FundingEntry>> fetchFunding(String address) async {
    final startTime = DateTime.now()
        .subtract(Duration(days: fundingDays))
        .millisecondsSinceEpoch;
    final data = await _api.fetchInfo('userFunding', {
      'user': address,
      'startTime': startTime,
    });
    final entries = (data as List<dynamic>)
        .take(maxFunding)
        .map((f) => FundingEntry.fromJson(f as Map<String, dynamic>))
        .toList();

    _cache.set(_cacheKey(address), entries, walletCacheTtl);
    return entries;
  }

  void clearCache(String address) {
    _cache.remove(_cacheKey(address));
  }
}
