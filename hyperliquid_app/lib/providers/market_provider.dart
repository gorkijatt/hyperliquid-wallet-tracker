import 'package:flutter/foundation.dart';
import '../data/models/market_coin.dart';
import '../data/repositories/market_repository.dart';

class MarketProvider extends ChangeNotifier {
  final MarketRepository _repo;

  List<MarketCoin> _coins = [];
  String _searchQuery = '';
  bool _loading = false;
  String? _error;

  MarketProvider(this._repo);

  List<MarketCoin> get coins {
    if (_searchQuery.isEmpty) return _coins;
    final q = _searchQuery.toLowerCase();
    return _coins.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  List<MarketCoin> get allCoins => _coins;
  bool get loading => _loading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
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
    } catch (e) {
      if (_coins.isEmpty) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
