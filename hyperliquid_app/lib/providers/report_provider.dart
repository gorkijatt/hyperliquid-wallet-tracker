import 'package:flutter/foundation.dart';
import '../data/models/open_order.dart';
import '../data/models/position.dart';
import '../data/models/wallet.dart';
import '../data/services/api_service.dart';

class ReportPosition {
  final String walletLabel;
  final String walletAddress;
  final Position position;

  const ReportPosition({
    required this.walletLabel,
    required this.walletAddress,
    required this.position,
  });
}

class ReportOrder {
  final String walletLabel;
  final String walletAddress;
  final OpenOrder order;

  const ReportOrder({
    required this.walletLabel,
    required this.walletAddress,
    required this.order,
  });
}

class ReportProvider extends ChangeNotifier {
  final ApiService _api;

  List<ReportPosition> _positions = [];
  List<ReportOrder> _orders = [];
  double _totalUpnl = 0;
  double? _btcPrice;
  bool _loading = false;
  String? _error;
  bool _showCards = false;

  ReportProvider(this._api);

  List<ReportPosition> get positions => _positions;
  List<ReportOrder> get orders => _orders;
  double get totalUpnl => _totalUpnl;
  double? get btcPrice => _btcPrice;
  bool get loading => _loading;
  String? get error => _error;
  bool get showCards => _showCards;

  void toggleView() {
    _showCards = !_showCards;
    notifyListeners();
  }

  double? estimatedPnl(ReportOrder ro) {
    final pos = _positions
        .where(
          (p) =>
              p.position.coin == ro.order.coin &&
              p.walletAddress == ro.walletAddress,
        )
        .toList();
    if (pos.isEmpty) return null;
    final p = pos.first.position;
    if (!(ro.order.isTrigger || ro.order.reduceOnly || ro.order.isPositionTpsl)) {
      return null;
    }

    final trigPx =
        double.tryParse(ro.order.triggerPx ?? '') ??
        double.tryParse(ro.order.limitPx) ??
        0;
    final size = p.absSize;
    if (p.entryPx == 0 || trigPx == 0 || size == 0) return null;

    return p.isLong ? (trigPx - p.entryPx) * size : (p.entryPx - trigPx) * size;
  }

  Future<void> load(List<Wallet> wallets) async {
    if (wallets.isEmpty) {
      _error = 'No wallets found';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final allMids = await _api.fetchInfo('allMids') as Map<String, dynamic>;
      _btcPrice = double.tryParse(allMids['BTC']?.toString() ?? '');

      final results = await Future.wait(
        wallets.map((w) async {
          final responses = await Future.wait([
            _api.fetchInfo('clearinghouseState', {'user': w.address}),
            _api.fetchInfo('frontendOpenOrders', {'user': w.address}),
          ]);
          return {
            'wallet': w,
            'clearing': responses[0],
            'orders': responses[1],
          };
        }),
      );

      _positions = [];
      _orders = [];
      _totalUpnl = 0;

      for (final result in results) {
        final w = result['wallet'] as Wallet;
        final clearing = result['clearing'] as Map<String, dynamic>;
        final ordersList = result['orders'] as List<dynamic>;
        final label = w.displayName;

        final assetPositions =
            (clearing['assetPositions'] as List<dynamic>?) ?? [];
        for (final ap in assetPositions) {
          final pos = Position.fromJson(ap as Map<String, dynamic>, allMids);
          if (pos.szi == 0) continue;
          _totalUpnl += pos.unrealizedPnl;
          _positions.add(
            ReportPosition(
              walletLabel: label,
              walletAddress: w.address,
              position: pos,
            ),
          );
        }

        for (final o in ordersList) {
          _orders.add(
            ReportOrder(
              walletLabel: label,
              walletAddress: w.address,
              order: OpenOrder.fromJson(o as Map<String, dynamic>),
            ),
          );
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
