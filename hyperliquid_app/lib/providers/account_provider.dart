import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../data/repositories/account_repository.dart';

class AccountProvider extends ChangeNotifier {
  final AccountRepository _repo;

  AccountData? _data;
  bool _loading = false;
  String? _error;
  String? _currentAddress;
  DateTime? _lastUpdated;
  Timer? _refreshTimer;
  bool _stale = false;

  AccountProvider(this._repo);

  AccountData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isStale => _stale;

  void onWalletChanged(String? address) {
    if (address == _currentAddress) return;
    _currentAddress = address;
    _data = null;
    _error = null;
    _lastUpdated = null;
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
    _refreshTimer = Timer.periodic(accountRefreshInterval, (_) {
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
      _data = await _repo.fetchAccount(address);
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
      await load(_currentAddress!);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
