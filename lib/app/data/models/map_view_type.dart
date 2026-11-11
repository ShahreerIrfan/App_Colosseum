import '../../core/localization/tour_localizations.dart';

/// Defines the supported base map view presentations for the Colosseum map.
enum MapViewType {
  /// Standard Google Maps roadmap / vector architectural presentation.
  general,

  /// High-resolution Google Maps satellite imagery presentation.
  satellite;

  /// User-facing display title for the map view mode.
  String get displayName {
    switch (this) {
      case MapViewType.general:
        return 'General View'.tourText;
      case MapViewType.satellite:
        return 'Satellite View'.tourText;
    }
  }

  /// Compact short label for constrained bottom action buttons.
  String get shortName {
    switch (this) {
      case MapViewType.general:
        return 'General'.tourText;
      case MapViewType.satellite:
        return 'Satellite'.tourText;
    }
  }

  /// Accessibility semantic description.
  String get semanticLabel {
    switch (this) {
      case MapViewType.general:
        return 'General map view'.tourText;
      case MapViewType.satellite:
        return 'Satellite map view'.tourText;
    }
  }

  /// Subtitle description explaining the map layer context.
  String get description {
    switch (this) {
      case MapViewType.general:
        return 'Standard map view'.tourText;
      case MapViewType.satellite:
        return 'High-resolution satellite view'.tourText;
    }
  }

  /// Corresponding Google Maps tile layer identifier.
  String get tileLyrsCode {
    switch (this) {
      case MapViewType.general:
        return 'm'; // Standard roadmap
      case MapViewType.satellite:
        return 's'; // Pure satellite imagery
    }
  }
}
