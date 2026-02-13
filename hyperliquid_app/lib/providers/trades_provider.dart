import 'package:flutter/foundation.dart';
import '../data/models/fill.dart';
import '../data/repositories/trades_repository.dart';

class TradesProvider extends ChangeNotifier {
  final TradesRepository _repo;

  List<Fill> _fills = [];
  String _coinFilter = 'All';
  bool _loading = false;
  String? _error;
  String? _currentAddress;

  TradesProvider(this._repo);

  List<Fill> get fills {
    if (_coinFilter == 'All') return _fills;
    return _fills.where((f) => f.coin == _coinFilter).toList();
  }

  List<Fill> get allFills => _fills;
  List<String> get coins => ['All', ..._fills.map((f) => f.coin).toSet()];
  String get coinFilter => _coinFilter;
  bool get loading => _loading;
  String? get error => _error;

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
    if (address != null && address.isNotEmpty) {
      load(address);
    } else {
      notifyListeners();
    }
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
    } catch (e) {
      if (_fills.isEmpty) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_currentAddress != null && _currentAddress!.isNotEmpty) {
      _repo.clearCache(_currentAddress!);
      _fills = [];
      _coinFilter = 'All';
      await load(_currentAddress!);
    }
  }
}
