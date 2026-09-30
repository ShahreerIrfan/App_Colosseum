/// Immutable model representing the user's live indoor coordinates on a floor plan.
class UserLocationModel {
  final String floorId;
  final double normalizedX;
  final double normalizedY;
  final double? headingDegrees;
  final double accuracyMeters;

  const UserLocationModel({
    required this.floorId,
    required this.normalizedX,
    required this.normalizedY,
    this.headingDegrees,
    this.accuracyMeters = 3.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLocationModel &&
          runtimeType == other.runtimeType &&
          floorId == other.floorId &&
          normalizedX == other.normalizedX &&
          normalizedY == other.normalizedY;

  @override
  int get hashCode => Object.hash(floorId, normalizedX, normalizedY);
}
