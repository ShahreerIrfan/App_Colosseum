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
        return 'General View';
      case MapViewType.satellite:
        return 'Satellite View';
    }
  }

  /// Compact short label for constrained bottom action buttons.
  String get shortName {
    switch (this) {
      case MapViewType.general:
        return 'General';
      case MapViewType.satellite:
        return 'Satellite';
    }
  }

  /// Accessibility semantic description.
  String get semanticLabel {
    switch (this) {
      case MapViewType.general:
        return 'General map view';
      case MapViewType.satellite:
        return 'Satellite map view';
    }
  }

  /// Subtitle description explaining the map layer context.
  String get description {
    switch (this) {
      case MapViewType.general:
        return 'Standard map view';
      case MapViewType.satellite:
        return 'High-resolution satellite view';
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
