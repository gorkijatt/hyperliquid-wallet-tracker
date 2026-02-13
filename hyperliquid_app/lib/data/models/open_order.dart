class OpenOrder {
  final String coin;
  final String side;
  final String limitPx;
  final String sz;
  final String origSz;
  final String? orderType;
  final bool isTrigger;
  final String? triggerPx;
  final bool isPositionTpsl;
  final bool reduceOnly;

  const OpenOrder({
    required this.coin,
    required this.side,
    required this.limitPx,
    required this.sz,
    required this.origSz,
    this.orderType,
    required this.isTrigger,
    this.triggerPx,
    required this.isPositionTpsl,
    required this.reduceOnly,
  });

  bool get isBuy => side == 'B';

  String get sideLabel {
    if (isPositionTpsl || reduceOnly) {
      return isBuy ? 'Close Short' : 'Close Long';
    }
    return isBuy ? 'Long' : 'Short';
  }

  String get sideClass {
    if (isPositionTpsl || reduceOnly) {
      return isBuy ? 'buy' : 'sell';
    }
    return isBuy ? 'buy' : 'sell';
  }

  String get displayPrice {
    final isMarketType = (orderType ?? '').contains('Market');
    if (isTrigger) {
      return isMarketType ? 'Market' : limitPx;
    }
    return limitPx;
  }

  String get displaySize {
    final szVal = double.tryParse(sz) ?? 0;
    final origVal = double.tryParse(origSz) ?? 0;
    if (szVal == 0 && origVal == 0) return '\u2014';
    return szVal == 0 ? origSz : sz;
  }

  String? get triggerInfo {
    if (isTrigger && triggerPx != null && triggerPx != '0') return triggerPx;
    return null;
  }

  factory OpenOrder.fromJson(Map<String, dynamic> json) {
    return OpenOrder(
      coin: json['coin'] as String,
      side: json['side'] as String,
      limitPx: json['limitPx']?.toString() ?? '0',
      sz: json['sz']?.toString() ?? '0',
      origSz: json['origSz']?.toString() ?? '0',
      orderType: json['orderType'] as String?,
      isTrigger: json['isTrigger'] as bool? ?? false,
      triggerPx: json['triggerPx']?.toString(),
      isPositionTpsl: json['isPositionTpsl'] as bool? ?? false,
      reduceOnly: json['reduceOnly'] as bool? ?? false,
    );
  }
}
