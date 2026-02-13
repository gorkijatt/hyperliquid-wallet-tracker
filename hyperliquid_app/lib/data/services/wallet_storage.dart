import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wallet.dart';

class WalletStorage {
  static const _walletsKey = 'hl_wallets';
  static const _activeWalletKey = 'hl_active_wallet';

  Future<List<Wallet>> getWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_walletsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Wallet.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveWallets(List<Wallet> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _walletsKey,
      jsonEncode(wallets.map((w) => w.toJson()).toList()),
    );
  }

  Future<String?> getActiveWalletAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeWalletKey);
  }

  Future<void> setActiveWalletAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeWalletKey, address);
  }
}
