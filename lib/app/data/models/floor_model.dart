/// Immutable data model representing a floor or level within a landmark.
class FloorModel {
  final String id;
  final String floorName;
  final int viewpointCount;
  final bool isCompleted;

  const FloorModel({
    required this.id,
    required this.floorName,
    required this.viewpointCount,
    this.isCompleted = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FloorModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
