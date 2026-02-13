class MarginSummary {
  final double accountValue;
  final double totalMarginUsed;
  final double totalNtlPos;
  final double totalRawUsd;

  const MarginSummary({
    required this.accountValue,
    required this.totalMarginUsed,
    required this.totalNtlPos,
    required this.totalRawUsd,
  });

  factory MarginSummary.fromJson(Map<String, dynamic> json) {
    return MarginSummary(
      accountValue:
          double.tryParse(json['accountValue']?.toString() ?? '0') ?? 0,
      totalMarginUsed:
          double.tryParse(json['totalMarginUsed']?.toString() ?? '0') ?? 0,
      totalNtlPos: double.tryParse(json['totalNtlPos']?.toString() ?? '0') ?? 0,
      totalRawUsd: double.tryParse(json['totalRawUsd']?.toString() ?? '0') ?? 0,
    );
  }
}
