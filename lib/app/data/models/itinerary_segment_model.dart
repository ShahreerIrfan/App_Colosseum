import 'package:flutter/material.dart';

/// Represents a distinct walking path segment connecting consecutive stops or entry/exit in a tour itinerary.
class ItinerarySegmentModel {
  final String fromId;
  final String toId;
  final List<Offset> points;
  final bool isCompleted;
  final bool isActive;

  const ItinerarySegmentModel({
    required this.fromId,
    required this.toId,
    required this.points,
    this.isCompleted = false,
    this.isActive = false,
  });

  ItinerarySegmentModel copyWith({
    String? fromId,
    String? toId,
    List<Offset>? points,
    bool? isCompleted,
    bool? isActive,
  }) {
    return ItinerarySegmentModel(
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      points: points ?? this.points,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItinerarySegmentModel &&
          runtimeType == other.runtimeType &&
          fromId == other.fromId &&
          toId == other.toId &&
          isCompleted == other.isCompleted &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      fromId.hashCode ^ toId.hashCode ^ isCompleted.hashCode ^ isActive.hashCode;
}
