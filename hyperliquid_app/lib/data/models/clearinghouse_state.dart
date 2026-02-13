import 'margin_summary.dart';

class ClearinghouseState {
  final MarginSummary marginSummary;
  final double withdrawable;
  final List<Map<String, dynamic>> rawPositions;

  const ClearinghouseState({
    required this.marginSummary,
    required this.withdrawable,
    required this.rawPositions,
  });

  factory ClearinghouseState.fromJson(Map<String, dynamic> json) {
    final ms = json['marginSummary'] as Map<String, dynamic>? ?? {};
    final positions =
        (json['assetPositions'] as List<dynamic>?)
            ?.where((p) {
              final szi =
                  double.tryParse(
                    (p as Map<String, dynamic>)['position']['szi']
                            ?.toString() ??
                        '0',
                  ) ??
                  0;
              return szi != 0;
            })
            .map((p) => p as Map<String, dynamic>)
            .toList() ??
        [];

    return ClearinghouseState(
      marginSummary: MarginSummary.fromJson(ms),
      withdrawable:
          double.tryParse(json['withdrawable']?.toString() ?? '0') ?? 0,
      rawPositions: positions,
    );
  }
}
