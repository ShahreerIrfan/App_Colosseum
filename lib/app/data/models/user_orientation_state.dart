/// Immutable model representing the user's live device orientation and compass sensor state.
class UserOrientationState {
  /// Compass heading in degrees relative to North [0, 360).
  /// 0° = North, 90° = East, 180° = South, 270° = West.
  /// Null if device orientation sensor is unavailable or uncalibrated.
  final double? headingDegrees;

  /// Sensor accuracy in degrees or standard deviation (if reported by device).
  final double? sensorAccuracy;

  /// True if the device hardware supports compass / orientation sensors.
  final bool isAvailable;

  /// True if compass accuracy is low and may need calibration (e.g. figure-8 motion).
  final bool isCalibrating;

  /// Timestamp of the latest sensor reading.
  final DateTime? timestamp;

  const UserOrientationState({
    this.headingDegrees,
    this.sensorAccuracy,
    this.isAvailable = true,
    this.isCalibrating = false,
    this.timestamp,
  });

  bool get hasValidHeading => headingDegrees != null && !headingDegrees!.isNaN;

  UserOrientationState copyWith({
    double? Function()? headingDegrees,
    double? Function()? sensorAccuracy,
    bool? isAvailable,
    bool? isCalibrating,
    DateTime? timestamp,
  }) {
    return UserOrientationState(
      headingDegrees:
          headingDegrees != null ? headingDegrees() : this.headingDegrees,
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
          headingDegrees == other.headingDegrees &&
          sensorAccuracy == other.sensorAccuracy &&
          isAvailable == other.isAvailable &&
          isCalibrating == other.isCalibrating;

  @override
  int get hashCode => Object.hash(
        headingDegrees,
        sensorAccuracy,
        isAvailable,
        isCalibrating,
      );
}
