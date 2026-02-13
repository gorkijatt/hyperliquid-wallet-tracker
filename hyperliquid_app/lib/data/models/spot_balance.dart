class SpotBalance {
  final String coin;
  final int? token;
  final double total;
  final double hold;
  final double usdValue;

  const SpotBalance({
    required this.coin,
    this.token,
    required this.total,
    required this.hold,
    required this.usdValue,
  });

  factory SpotBalance.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic>? mids,
  ) {
    final coin = json['coin'] as String;
    final token = json['token'] as int?;
    final total = double.tryParse(json['total'].toString()) ?? 0;
    final hold = double.tryParse(json['hold'].toString()) ?? 0;

    double price = 0;
    if (coin == 'USDC' || coin == 'USDT') {
      price = 1;
    } else if (mids != null) {
      price = double.tryParse(mids[coin]?.toString() ?? '') ?? 0;
      if (price == 0 && token != null) {
        price = double.tryParse(mids['@$token']?.toString() ?? '') ?? 0;
      }
    }

    return SpotBalance(
      coin: coin,
      token: token,
      total: total,
      hold: hold,
      usdValue: total * price,
    );
  }
}
