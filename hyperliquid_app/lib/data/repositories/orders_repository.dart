import '../../core/constants.dart';
import '../models/fill.dart';
import '../models/open_order.dart';
import '../models/position.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class OrdersData {
  final List<OpenOrder> openOrders;
  final List<Fill> fills;
  final List<Position> positions;

  const OrdersData({
    required this.openOrders,
    required this.fills,
    required this.positions,
  });
}

class OrdersRepository {
  final ApiService _api;
  final CacheService _cache;

  OrdersRepository(this._api, this._cache);

  String _cacheKey(String addr) => 'orders_${addr.substring(0, 10)}';

  OrdersData? getCached(String address) =>
      _cache.get<OrdersData>(_cacheKey(address));

  Future<OrdersData> fetchOrders(String address) async {
    final results = await Future.wait([
      _api.fetchInfo('frontendOpenOrders', {'user': address}),
      _api.fetchInfo('userFills', {'user': address}),
      _api.fetchInfo('clearinghouseState', {'user': address}),
    ]);

    final openOrders = (results[0] as List<dynamic>)
        .map((o) => OpenOrder.fromJson(o as Map<String, dynamic>))
        .toList();

    final fills = (results[1] as List<dynamic>)
        .take(maxFills)
        .map((f) => Fill.fromJson(f as Map<String, dynamic>))
        .toList();

    final perps = results[2] as Map<String, dynamic>;
    final positions = ((perps['assetPositions'] as List<dynamic>?) ?? [])
        .where(
          (p) =>
              (double.tryParse(
                    (p as Map<String, dynamic>)['position']['szi']
                            ?.toString() ??
                        '0',
                  ) ??
                  0) !=
              0,
        )
        .map((p) => Position.fromJson(p as Map<String, dynamic>, null))
        .toList();

    final data = OrdersData(
      openOrders: openOrders,
      fills: fills,
      positions: positions,
    );

    _cache.set(_cacheKey(address), data, walletCacheTtl);
    return data;
  }

  void clearCache(String address) {
    _cache.remove(_cacheKey(address));
  }
}
