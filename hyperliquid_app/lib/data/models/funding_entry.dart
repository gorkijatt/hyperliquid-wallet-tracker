class FundingEntry {
  final String coin;
  final String usdc;
  final String fundingRate;
  final dynamic time;

  const FundingEntry({
    required this.coin,
    required this.usdc,
    required this.fundingRate,
    required this.time,
  });

  double get usdcValue => double.tryParse(usdc) ?? 0;

  factory FundingEntry.fromJson(Map<String, dynamic> json) {
    return FundingEntry(
      coin: json['coin'] as String? ?? '',
      usdc: json['usdc']?.toString() ?? '0',
      fundingRate: json['fundingRate']?.toString() ?? '0',
      time: json['time'],
    );
  }
}
