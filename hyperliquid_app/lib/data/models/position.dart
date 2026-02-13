class Position {
  final String coin;
  final double szi;
  final double entryPx;
  final double? markPx;
  final double? liquidationPx;
  final double unrealizedPnl;
  final double cumFunding;
  final String? leverageValue;
  final String? leverageType;

  const Position({
    required this.coin,
    required this.szi,
    required this.entryPx,
    this.markPx,
    this.liquidationPx,
    required this.unrealizedPnl,
    required this.cumFunding,
    this.leverageValue,
    this.leverageType,
  });

  bool get isLong => szi > 0;
  String get side => isLong ? 'LONG' : 'SHORT';
  double get absSize => szi.abs();

  factory Position.fromJson(
    Map<String, dynamic> ap,
    Map<String, dynamic>? mids,
  ) {
    final pos = ap['position'] as Map<String, dynamic>;
    final coin = pos['coin'] as String;
    final markPx = mids != null && mids[coin] != null
        ? double.tryParse(mids[coin].toString())
        : null;
    final liq = pos['liquidationPx'] != null
        ? double.tryParse(pos['liquidationPx'].toString())
        : null;
    final cumFunding =
        pos['cumFunding'] != null && pos['cumFunding']['sinceOpen'] != null
        ? double.tryParse(pos['cumFunding']['sinceOpen'].toString()) ?? 0.0
        : 0.0;
    final leverage = pos['leverage'] as Map<String, dynamic>?;

    return Position(
      coin: coin,
      szi: double.tryParse(pos['szi'].toString()) ?? 0,
      entryPx: double.tryParse(pos['entryPx'].toString()) ?? 0,
      markPx: markPx,
      liquidationPx: liq,
      unrealizedPnl:
          double.tryParse(pos['unrealizedPnl']?.toString() ?? '0') ?? 0,
      cumFunding: cumFunding,
      leverageValue: leverage?['value']?.toString(),
      leverageType: leverage?['type']?.toString(),
    );
  }
}
