import 'package:flutter/foundation.dart';
import '../data/models/wallet.dart';
import '../data/services/wallet_storage.dart';

class WalletProvider extends ChangeNotifier {
  final WalletStorage _storage = WalletStorage();
  List<Wallet> _wallets = [];
  String? _activeAddress;
  bool _initialized = false;

  List<Wallet> get wallets => _wallets;
  String? get activeAddress => _activeAddress;
  bool get initialized => _initialized;

  Wallet? get activeWallet {
    if (_activeAddress == null) return null;
    try {
      return _wallets.firstWhere((w) => w.address == _activeAddress);
    } catch (_) {
      return null;
    }
  }

  bool get hasWallet => _activeAddress != null && _activeAddress!.isNotEmpty;

  Future<void> init() async {
    _wallets = await _storage.getWallets();
    _activeAddress = await _storage.getActiveWalletAddress();
    if (_activeAddress != null &&
        !_wallets.any((w) => w.address == _activeAddress)) {
      _activeAddress = _wallets.isNotEmpty ? _wallets.first.address : null;
      if (_activeAddress != null) {
        await _storage.setActiveWalletAddress(_activeAddress!);
      }
    }
    if (_activeAddress == null && _wallets.isNotEmpty) {
      _activeAddress = _wallets.first.address;
      await _storage.setActiveWalletAddress(_activeAddress!);
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> addWallet(String address, String label) async {
    if (_wallets.any((w) => w.address.toLowerCase() == address.toLowerCase())) {
      throw Exception('Wallet already exists');
    }
    _wallets.add(Wallet(address: address, label: label));
    await _storage.saveWallets(_wallets);
    _activeAddress = address;
    await _storage.setActiveWalletAddress(address);
    notifyListeners();
  }

  Future<void> removeWallet(String address) async {
    _wallets.removeWhere((w) => w.address == address);
    if (_wallets.isEmpty) return;
    await _storage.saveWallets(_wallets);
    if (_activeAddress == address) {
      _activeAddress = _wallets.first.address;
      await _storage.setActiveWalletAddress(_activeAddress!);
    }
    notifyListeners();
  }

  Future<void> renameWallet(String address, String newLabel) async {
    final wallet = _wallets.firstWhere((w) => w.address == address);
    wallet.label = newLabel;
    await _storage.saveWallets(_wallets);
    notifyListeners();
  }

  Future<void> setActiveWallet(String address) async {
    _activeAddress = address;
    await _storage.setActiveWalletAddress(address);
    notifyListeners();
  }

  List<Wallet> search(String query) {
    if (query.isEmpty) return _wallets;
    final q = query.toLowerCase();
    return _wallets
        .where(
          (w) =>
              w.label.toLowerCase().contains(q) ||
              w.address.toLowerCase().contains(q),
        )
        .toList();
  }
}
