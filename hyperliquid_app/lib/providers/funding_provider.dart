import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../data/models/funding_entry.dart';
import '../data/repositories/funding_repository.dart';

class FundingProvider extends ChangeNotifier {
  final FundingRepository _repo;

  List<FundingEntry> _entries = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _currentAddress;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;
  bool _stale = false;
  String _coinFilter = 'All';

  FundingProvider(this._repo);

  List<FundingEntry> get entries {
    if (_coinFilter == 'All') return _entries;
    return _entries.where((e) => e.coin == _coinFilter).toList();
  }

  List<FundingEntry> get allEntries => _entries;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isStale => _stale;
  String get coinFilter => _coinFilter;

  List<String> get coins => ['All', ..._entries.map((e) => e.coin).toSet()];

  double get totalFunding => entries.fold(0.0, (sum, e) => sum + e.usdcValue);

  void setCoinFilter(String coin) {
    _coinFilter = coin;
    notifyListeners();
  }

  void onWalletChanged(String? address) {
    if (address == _currentAddress) return;
    _currentAddress = address;
    _entries = [];
    _error = null;
    _lastUpdated = null;
    _coinFilter = 'All';
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
    _refreshTimer = Timer.periodic(fundingRefreshInterval, (_) {
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
    if (cached != null && _entries.isEmpty) {
      _entries = cached;
      notifyListeners();
    }

    _loading = _entries.isEmpty;
    _error = null;
    if (_loading) notifyListeners();

    try {
      _entries = await _repo.fetchFunding(address);
      _error = null;
      _lastUpdated = DateTime.now();
    } catch (e) {
      if (_entries.isEmpty) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _currentAddress == null) return;
    if (_entries.isEmpty) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final lastTime = _entries.last.time;
      final endTime = lastTime is int ? lastTime : (lastTime as num).toInt();
      final older = await _repo.fetchFunding(
        _currentAddress!,
        endTime: endTime,
      );
      final existingTimes = _entries.map((e) => '${e.coin}_${e.time}').toSet();
      final newEntries = older
          .where((e) => !existingTimes.contains('${e.coin}_${e.time}'))
          .toList();
      if (newEntries.isEmpty || older.length < maxFunding) {
        _hasMore = false;
      }
      _entries = [..._entries, ...newEntries];
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
      _entries = [];
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
