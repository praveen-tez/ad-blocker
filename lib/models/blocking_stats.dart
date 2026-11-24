/// Blocking statistics with explicit tracking of placeholder/real status.
class BlockingStats {
  final int blockedAds;
  final int blockedTrackers;
  final int totalQueries;
  final double dataSavedMb;
  final int averageLatencyMs;
  final bool isPlaceholder;

  const BlockingStats({
    required this.blockedAds,
    required this.blockedTrackers,
    required this.totalQueries,
    required this.dataSavedMb,
    required this.averageLatencyMs,
    required this.isPlaceholder,
  });

  /// Clearly labelled baseline for Stage 1 UI validation.
  factory BlockingStats.placeholder() {
    return const BlockingStats(
      blockedAds: 1482,
      blockedTrackers: 864,
      totalQueries: 14210,
      dataSavedMb: 42.6,
      averageLatencyMs: 8,
      isPlaceholder: true,
    );
  }

  factory BlockingStats.zero() {
    return const BlockingStats(
      blockedAds: 0,
      blockedTrackers: 0,
      totalQueries: 0,
      dataSavedMb: 0.0,
      averageLatencyMs: 0,
      isPlaceholder: true,
    );
  }

  BlockingStats copyWith({
    int? blockedAds,
    int? blockedTrackers,
    int? totalQueries,
    double? dataSavedMb,
    int? averageLatencyMs,
    bool? isPlaceholder,
  }) {
    return BlockingStats(
      blockedAds: blockedAds ?? this.blockedAds,
      blockedTrackers: blockedTrackers ?? this.blockedTrackers,
      totalQueries: totalQueries ?? this.totalQueries,
      dataSavedMb: dataSavedMb ?? this.dataSavedMb,
      averageLatencyMs: averageLatencyMs ?? this.averageLatencyMs,
      isPlaceholder: isPlaceholder ?? this.isPlaceholder,
    );
  }
}

