import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../core/utils/geodesic_utils.dart';

/// Represents a distinct walking path segment connecting consecutive stops or entry/exit in a tour itinerary.
class ItinerarySegmentModel {
  final String fromId;
  final String toId;
  final List<Offset> points;
  final bool isCompleted;
  final bool isActive;

  /// Gets geographic [LatLng] points along this walking path segment.
  List<LatLng> get latLngPoints {
    return points.map((p) => GeodesicUtils.canvasOffsetToLatLng(p)).toList();
  }

  const ItinerarySegmentModel({
    required this.fromId,
    required this.toId,
    required this.points,
    this.isCompleted = false,
    this.isActive = false,
  });

  factory ItinerarySegmentModel.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final points = rawPoints.map<Offset>((p) {
      if (p is Map) {
        final x = (p['x'] ?? p['dx'] ?? 0.0) as num;
        final y = (p['y'] ?? p['dy'] ?? 0.0) as num;
        return Offset(x.toDouble(), y.toDouble());
      } else if (p is List && p.length >= 2) {
        return Offset((p[0] as num).toDouble(), (p[1] as num).toDouble());
      }
      return Offset.zero;
    }).toList();

    return ItinerarySegmentModel(
      fromId: json['fromId'] as String? ?? '',
      toId: json['toId'] as String? ?? '',
      points: points,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'fromId': fromId,
        'toId': toId,
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'isCompleted': isCompleted,
        'isActive': isActive,
      };

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
