import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../data/repositories/orders_repository.dart';

class OrdersProvider extends ChangeNotifier {
  final OrdersRepository _repo;

  OrdersData? _data;
  bool _loading = false;
  String? _error;
  String? _currentAddress;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;
  bool _stale = false;
  String _coinFilter = 'All';

  OrdersProvider(this._repo);

  OrdersData? get data {
    if (_coinFilter == 'All' || _data == null) return _data;
    return OrdersData(
      openOrders: _data!.openOrders
          .where((o) => o.coin == _coinFilter)
          .toList(),
      fills: _data!.fills.where((f) => f.coin == _coinFilter).toList(),
      positions: _data!.positions,
    );
  }

  OrdersData? get allData => _data;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isStale => _stale;
  String get coinFilter => _coinFilter;

  List<String> get coins {
    if (_data == null) return ['All'];
    final orderCoins = _data!.openOrders.map((o) => o.coin);
    final fillCoins = _data!.fills.map((f) => f.coin);
    return [
      'All',
      ...{...orderCoins, ...fillCoins},
    ];
  }

  void setCoinFilter(String coin) {
    _coinFilter = coin;
    notifyListeners();
  }

  void onWalletChanged(String? address) {
    if (address == _currentAddress) return;
    _currentAddress = address;
    _data = null;
    _error = null;
    _lastUpdated = null;
    _coinFilter = 'All';
    _stale = true;
    notifyListeners();
  }

  void checkAndLoad() {
    if (_stale && _currentAddress != null && _currentAddress!.isNotEmpty) {
      _stale = false;
      load(_currentAddress!);
    }
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(ordersRefreshInterval, (_) {
      if (_currentAddress != null && _currentAddress!.isNotEmpty) {
        load(_currentAddress!);
      }
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> load(String address) async {
    final cached = _repo.getCached(address);
    if (cached != null && _data == null) {
      _data = cached;
      notifyListeners();
    }

    _loading = _data == null;
    _error = null;
    if (_loading) notifyListeners();

    try {
      _data = await _repo.fetchOrders(address);
      _error = null;
      _lastUpdated = DateTime.now();
    } catch (e) {
      if (_data == null) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_currentAddress != null && _currentAddress!.isNotEmpty) {
      _repo.clearCache(_currentAddress!);
      _data = null;
      _coinFilter = 'All';
      await load(_currentAddress!);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
