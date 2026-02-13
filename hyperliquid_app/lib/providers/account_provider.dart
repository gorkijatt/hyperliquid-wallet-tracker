import 'package:flutter/foundation.dart';
import '../data/repositories/account_repository.dart';

class AccountProvider extends ChangeNotifier {
  final AccountRepository _repo;

  AccountData? _data;
  bool _loading = false;
  String? _error;
  String? _currentAddress;

  AccountProvider(this._repo);

  AccountData? get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  void onWalletChanged(String? address) {
    if (address == _currentAddress) return;
    _currentAddress = address;
    _data = null;
    _error = null;
    if (address != null && address.isNotEmpty) {
      load(address);
    } else {
      notifyListeners();
    }
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
}
