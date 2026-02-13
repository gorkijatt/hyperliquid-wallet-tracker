import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../data/models/fill.dart';
import '../data/repositories/trades_repository.dart';

class TradesProvider extends ChangeNotifier {
  final TradesRepository _repo;

  List<Fill> _fills = [];
  String _coinFilter = 'All';
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _currentAddress;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;
  bool _stale = false;

  TradesProvider(this._repo);

  List<Fill> get fills {
    if (_coinFilter == 'All') return _fills;
    return _fills.where((f) => f.coin == _coinFilter).toList();
  }

  List<Fill> get allFills => _fills;
  List<String> get coins => ['All', ..._fills.map((f) => f.coin).toSet()];
  String get coinFilter => _coinFilter;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isStale => _stale;

  void setCoinFilter(String coin) {
    _coinFilter = coin;
    notifyListeners();
  }

  void onWalletChanged(String? address) {
    if (address == _currentAddress) return;
    _currentAddress = address;
    _fills = [];
    _coinFilter = 'All';
    _error = null;
    _lastUpdated = null;
    _stale = true;
    _hasMore = true;
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
    _refreshTimer = Timer.periodic(tradesRefreshInterval, (_) {
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
    if (cached != null && _fills.isEmpty) {
      _fills = cached;
      notifyListeners();
    }

    _loading = _fills.isEmpty;
    _error = null;
    if (_loading) notifyListeners();

    try {
      _fills = await _repo.fetchTrades(address);
      _error = null;
      _lastUpdated = DateTime.now();
    } catch (e) {
      if (_fills.isEmpty) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _currentAddress == null) return;
    if (_fills.isEmpty) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final lastTime = _fills.last.time;
      final startTime = lastTime is int ? lastTime : (lastTime as num).toInt();
      final older = await _repo.fetchTrades(
        _currentAddress!,
        startTime: startTime - (msPerDay * paginationDaysBack),
      );
      // Filter out duplicates by checking time + coin
      final existingTimes = _fills.map((f) => '${f.coin}_${f.time}').toSet();
      final newFills = older
          .where((f) => !existingTimes.contains('${f.coin}_${f.time}'))
          .toList();
      if (newFills.isEmpty || older.length < maxTrades) {
        _hasMore = false;
      }
      _fills = [..._fills, ...newFills];
    } catch (e) {
      // silently fail on load more
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_currentAddress != null && _currentAddress!.isNotEmpty) {
      _repo.clearCache(_currentAddress!);
      _fills = [];
      _coinFilter = 'All';
      _hasMore = true;
      await load(_currentAddress!);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
