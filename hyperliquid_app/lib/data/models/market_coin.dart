class MarketCoin {
  final String name;
  final double? mid;
  final int szDecimals;
  final double? prevDayPx;
  final double? dayNtlVlm;
  final String? fundingRate;

  const MarketCoin({
    required this.name,
    this.mid,
    required this.szDecimals,
    this.prevDayPx,
    this.dayNtlVlm,
    this.fundingRate,
  });

  double? get change24h {
    if (mid == null || prevDayPx == null || prevDayPx == 0) return null;
    return ((mid! - prevDayPx!) / prevDayPx!) * 100;
  }
}
