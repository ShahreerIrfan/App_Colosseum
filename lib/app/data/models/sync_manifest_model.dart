class TourSyncManifestModel {
  final String version;
  final String dataHash;
  final int totalFloors;
  final int totalViewpoints;
  final int totalLandmarks;
  final List<String> languages;
  final String? lastUpdatedAt;

  const TourSyncManifestModel({
    required this.version,
    required this.dataHash,
    required this.totalFloors,
    required this.totalViewpoints,
    required this.totalLandmarks,
    required this.languages,
    this.lastUpdatedAt,
  });

  factory TourSyncManifestModel.fromJson(Map<String, dynamic> json) {
    return TourSyncManifestModel(
      version: json['packageVersion'] as String? ??
          json['version'] as String? ??
          '1.0.0',
      dataHash: json['contentHash'] as String? ??
          json['dataHash'] as String? ??
          '',
      totalFloors: (json['totalFloors'] as num?)?.toInt() ?? 4,
      totalViewpoints: (json['totalViewpoints'] as num?)?.toInt() ?? 28,
      totalLandmarks: (json['totalLandmarks'] as num?)?.toInt() ?? 5,
      languages: (json['supportedLanguages'] as List<dynamic>? ??
              json['languages'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          const ['en'],
      lastUpdatedAt: json['publishedAt']?.toString() ??
          json['lastUpdatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'dataHash': dataHash,
        'totalFloors': totalFloors,
        'totalViewpoints': totalViewpoints,
        'totalLandmarks': totalLandmarks,
        'languages': languages,
        'lastUpdatedAt': lastUpdatedAt,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TourSyncManifestModel &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          dataHash == other.dataHash;

  @override
  int get hashCode => version.hashCode ^ dataHash.hashCode;
}
