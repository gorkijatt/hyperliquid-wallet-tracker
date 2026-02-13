import 'package:flutter/foundation.dart';
import '../data/models/funding_entry.dart';
import '../data/repositories/funding_repository.dart';

class FundingProvider extends ChangeNotifier {
  final FundingRepository _repo;

  List<FundingEntry> _entries = [];
  bool _loading = false;
  String? _error;
  String? _currentAddress;

  FundingProvider(this._repo);

  List<FundingEntry> get entries => _entries;
  bool get loading => _loading;
  String? get error => _error;

  double get totalFunding => _entries.fold(0.0, (sum, e) => sum + e.usdcValue);

  void onWalletChanged(String? address) {
    if (address == _currentAddress) return;
    _currentAddress = address;
    _entries = [];
    _error = null;
    if (address != null && address.isNotEmpty) {
      load(address);
    } else {
      notifyListeners();
    }
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
    } catch (e) {
      if (_entries.isEmpty) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_currentAddress != null && _currentAddress!.isNotEmpty) {
      _repo.clearCache(_currentAddress!);
      _entries = [];
      await load(_currentAddress!);
    }
  }
}
