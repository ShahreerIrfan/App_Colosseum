/// Immutable data model representing a floor or level within a landmark.
class FloorModel {
  final String id;
  final String floorName;
  final int viewpointCount;
  final int completedCount;
  final bool _isExplicitCompleted;

  /// Returns true if either explicitly marked completed or all viewpoints are visited.
  bool get isCompleted =>
      _isExplicitCompleted ||
      (viewpointCount > 0 && completedCount >= viewpointCount);

  /// Normalized completion progress between 0.0 and 1.0.
  double get progress => viewpointCount > 0
      ? (completedCount / viewpointCount).clamp(0.0, 1.0)
      : 0.0;

  const FloorModel({
    required this.id,
    required this.floorName,
    required this.viewpointCount,
    this.completedCount = 0,
    bool? isCompleted,
  }) : _isExplicitCompleted = isCompleted ?? false;

  FloorModel copyWith({
    String? id,
    String? floorName,
    int? viewpointCount,
    int? completedCount,
    bool? isCompleted,
  }) {
    return FloorModel(
      id: id ?? this.id,
      floorName: floorName ?? this.floorName,
      viewpointCount: viewpointCount ?? this.viewpointCount,
      completedCount: completedCount ?? this.completedCount,
      isCompleted: isCompleted ?? _isExplicitCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FloorModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          floorName == other.floorName &&
          viewpointCount == other.viewpointCount &&
          completedCount == other.completedCount &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode =>
      Object.hash(id, floorName, viewpointCount, completedCount, isCompleted);
}
