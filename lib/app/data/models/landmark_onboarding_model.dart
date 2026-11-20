import '../datasources/local/landmark_onboarding_data.dart';

/// Rich onboarding content model for a landmark upon proximity approach or manual pin selection.
class LandmarkOnboardingModel {
  final String landmarkId;
  final String title;
  final String subtitle;
  final String era; // e.g. "70 – 80 AD (Flavian Dynasty)"
  final String builders; // e.g. "Emperor Vespasian, completed by Titus"
  final String historicalSummary; // Concise narrative for visitor comprehension
  final List<String> securityGuidelines; // Mandatory security & baggage rules
  final List<String> levelHighlights; // Accessible floor tiers
  final String audioIntroText; // Script spoken automatically via TTS
  final String? audioAssetPath; // Optional high-fidelity studio recording fallback
  final double outerRadiusMeters; // Physical outer radius of monument

  const LandmarkOnboardingModel({
    required this.landmarkId,
    required this.title,
    required this.subtitle,
    required this.era,
    required this.builders,
    required this.historicalSummary,
    required this.securityGuidelines,
    required this.levelHighlights,
    required this.audioIntroText,
    this.audioAssetPath,
    required this.outerRadiusMeters,
  });

  /// Factory constructor to retrieve calibrated onboarding content for a specific landmark ID.
  factory LandmarkOnboardingModel.forLandmark(
    String id, {
    String language = 'en',
  }) {
    return LandmarkOnboardingData.getForLandmark(id, language: language);
  }

  factory LandmarkOnboardingModel.fromJson(Map<String, dynamic> json) {
    return LandmarkOnboardingModel(
      landmarkId: json['landmarkId'] as String? ?? json['code'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      era: json['era'] as String? ?? '',
      builders: json['builders'] as String? ?? '',
      historicalSummary: json['historicalSummary'] as String? ?? json['description'] as String? ?? '',
      securityGuidelines: (json['securityGuidelines'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      levelHighlights: (json['levelHighlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      audioIntroText: json['audioIntroText'] as String? ?? '',
      audioAssetPath: json['audioAssetPath'] as String?,
      outerRadiusMeters: (json['outerRadiusMeters'] as num?)?.toDouble() ?? 40.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'landmarkId': landmarkId,
        'title': title,
        'subtitle': subtitle,
        'era': era,
        'builders': builders,
        'historicalSummary': historicalSummary,
        'securityGuidelines': securityGuidelines,
        'levelHighlights': levelHighlights,
        'audioIntroText': audioIntroText,
        'audioAssetPath': audioAssetPath,
        'outerRadiusMeters': outerRadiusMeters,
      };
}
