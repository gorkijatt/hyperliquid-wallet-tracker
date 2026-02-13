import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../data/models/market_coin.dart';
import '../data/repositories/market_repository.dart';

class MarketProvider extends ChangeNotifier {
  final MarketRepository _repo;

  List<MarketCoin> _coins = [];
  String _searchQuery = '';
  bool _loading = false;
  String? _error;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;

  // Sort state
  String _sortColumn = '';
  bool _sortAscending = true;

  MarketProvider(this._repo);

  List<MarketCoin> get coins {
    var list = _searchQuery.isEmpty
        ? List<MarketCoin>.from(_coins)
        : _coins
              .where(
                (c) =>
                    c.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
    if (_sortColumn.isNotEmpty) {
      list.sort((a, b) {
        int cmp;
        switch (_sortColumn) {
          case 'name':
            cmp = a.name.compareTo(b.name);
          case 'price':
            cmp = (a.mid ?? 0).compareTo(b.mid ?? 0);
          case 'change':
            cmp = (a.change24h ?? -999).compareTo(b.change24h ?? -999);
          case 'volume':
            cmp = (a.dayNtlVlm ?? 0).compareTo(b.dayNtlVlm ?? 0);
          case 'funding':
            cmp = (double.tryParse(a.fundingRate ?? '') ?? 0).compareTo(
              double.tryParse(b.fundingRate ?? '') ?? 0,
            );
          default:
            cmp = 0;
        }
        return _sortAscending ? cmp : -cmp;
      });
    }
    return list;
  }

  List<MarketCoin> get allCoins => _coins;
  bool get loading => _loading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  DateTime? get lastUpdated => _lastUpdated;
  String get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSort(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    notifyListeners();
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(marketRefreshInterval, (_) => load());
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> load() async {
    final cached = _repo.getCached();
    if (cached != null && _coins.isEmpty) {
      _coins = cached;
      notifyListeners();
    }

    _loading = _coins.isEmpty;
    _error = null;
    if (_loading) notifyListeners();

    try {
      _coins = await _repo.fetchMarket();
      _error = null;
      _lastUpdated = DateTime.now();
    } catch (e) {
      if (_coins.isEmpty) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
