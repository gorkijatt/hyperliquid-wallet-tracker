import '../../core/constants.dart';
import '../models/clearinghouse_state.dart';
import '../models/position.dart';
import '../models/spot_balance.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class AccountData {
  final ClearinghouseState clearinghouse;
  final List<Position> positions;
  final List<SpotBalance> spotBalances;
  final double spotUsdValue;
  final double totalPnl;
  final double totalBalance;
  final Map<String, dynamic> mids;

  const AccountData({
    required this.clearinghouse,
    required this.positions,
    required this.spotBalances,
    required this.spotUsdValue,
    required this.totalPnl,
    required this.totalBalance,
    required this.mids,
  });
}

class AccountRepository {
  final ApiService _api;
  final CacheService _cache;

  AccountRepository(this._api, this._cache);

  String _cacheKey(String addr) => 'account_${addr.substring(0, 10)}';

  AccountData? getCached(String address) =>
      _cache.get<AccountData>(_cacheKey(address));

  Future<AccountData> fetchAccount(String address) async {
    final results = await Future.wait([
      _api.fetchInfo('clearinghouseState', {'user': address}),
      _api.fetchInfo('spotClearinghouseState', {'user': address}),
      _api.fetchInfo('allMids'),
    ]);

    final perps = results[0] as Map<String, dynamic>;
    final spot = results[1] as Map<String, dynamic>;
    final mids = results[2] as Map<String, dynamic>;

    final clearinghouse = ClearinghouseState.fromJson(perps);
    final positions = clearinghouse.rawPositions
        .map((p) => Position.fromJson(p, mids))
        .toList();

    final spotBalances = ((spot['balances'] as List<dynamic>?) ?? [])
        .where(
          (b) =>
              (double.tryParse(
                    (b as Map<String, dynamic>)['total'].toString(),
                  ) ??
                  0) >
              0,
        )
        .map((b) => SpotBalance.fromJson(b as Map<String, dynamic>, mids))
        .toList();

    final spotUsdValue = spotBalances.fold(0.0, (sum, b) => sum + b.usdValue);
    final totalPnl = positions.fold(0.0, (sum, p) => sum + p.unrealizedPnl);
    final totalBalance = spotUsdValue + totalPnl;

    final data = AccountData(
      clearinghouse: clearinghouse,
      positions: positions,
      spotBalances: spotBalances,
      spotUsdValue: spotUsdValue,
      totalPnl: totalPnl,
      totalBalance: totalBalance,
      mids: mids,
    );

    _cache.set(_cacheKey(address), data, walletCacheTtl);
    return data;
  }

  void clearCache(String address) {
    _cache.remove(_cacheKey(address));
  }
}
