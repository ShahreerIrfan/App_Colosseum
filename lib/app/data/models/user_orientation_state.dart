/// Immutable model representing the user's live device orientation and compass sensor state.
class UserOrientationState {
  /// Raw unfiltered compass heading in degrees directly from device hardware sensor [0, 360).
  final double? rawHeadingDegrees;

  /// Filtered real-world compass heading in degrees relative to True/Magnetic North [0, 360).
  /// 0° = North, 90° = East, 180° = South, 270° = West.
  /// Null if device orientation sensor is unavailable or uncalibrated.
  final double? headingDegrees;

  /// Map-aligned heading in degrees [0, 360), adjusted for the architectural floor plan's orientation.
  /// displayHeading = (headingDegrees - mapNorthOffsetDegrees + 360) % 360.
  final double? mapHeadingDegrees;

  /// Sensor accuracy in degrees or standard deviation (if reported by device).
  final double? sensorAccuracy;

  /// True if the device hardware supports compass / orientation sensors.
  final bool isAvailable;

  /// True if compass accuracy is low and may need calibration (e.g. figure-8 motion).
  final bool isCalibrating;

  /// Timestamp of the latest sensor reading.
  final DateTime? timestamp;

  const UserOrientationState({
    this.rawHeadingDegrees,
    this.headingDegrees,
    this.mapHeadingDegrees,
    this.sensorAccuracy,
    this.isAvailable = true,
    this.isCalibrating = false,
    this.timestamp,
  });

  bool get hasValidHeading => headingDegrees != null && !headingDegrees!.isNaN;

  UserOrientationState copyWith({
    double? Function()? rawHeadingDegrees,
    double? Function()? headingDegrees,
    double? Function()? mapHeadingDegrees,
    double? Function()? sensorAccuracy,
    bool? isAvailable,
    bool? isCalibrating,
    DateTime? timestamp,
  }) {
    return UserOrientationState(
      rawHeadingDegrees: rawHeadingDegrees != null
          ? rawHeadingDegrees()
          : this.rawHeadingDegrees,
      headingDegrees:
          headingDegrees != null ? headingDegrees() : this.headingDegrees,
      mapHeadingDegrees: mapHeadingDegrees != null
          ? mapHeadingDegrees()
          : this.mapHeadingDegrees,
      sensorAccuracy:
          sensorAccuracy != null ? sensorAccuracy() : this.sensorAccuracy,
      isAvailable: isAvailable ?? this.isAvailable,
      isCalibrating: isCalibrating ?? this.isCalibrating,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserOrientationState &&
          runtimeType == other.runtimeType &&
          rawHeadingDegrees == other.rawHeadingDegrees &&
          headingDegrees == other.headingDegrees &&
          mapHeadingDegrees == other.mapHeadingDegrees &&
          sensorAccuracy == other.sensorAccuracy &&
          isAvailable == other.isAvailable &&
          isCalibrating == other.isCalibrating;

  @override
  int get hashCode => Object.hash(
        rawHeadingDegrees,
        headingDegrees,
        mapHeadingDegrees,
        sensorAccuracy,
        isAvailable,
        isCalibrating,
      );
}
