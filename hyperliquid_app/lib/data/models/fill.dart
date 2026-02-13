class Fill {
  final String coin;
  final String side;
  final String px;
  final String sz;
  final String fee;
  final dynamic time;

  const Fill({
    required this.coin,
    required this.side,
    required this.px,
    required this.sz,
    required this.fee,
    required this.time,
  });

  bool get isBuy => side == 'B';

  factory Fill.fromJson(Map<String, dynamic> json) {
    return Fill(
      coin: json['coin'] as String,
      side: json['side'] as String,
      px: json['px']?.toString() ?? '0',
      sz: json['sz']?.toString() ?? '0',
      fee: json['fee']?.toString() ?? '0',
      time: json['time'],
    );
  }
}
