import 'dart:math';
import 'package:collection/collection.dart';
import '../models/sos_packet.dart';

class GeoCoord {
  final String id;
  final String name;
  final double lat;
  final double lng;

  const GeoCoord({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  double distanceTo(GeoCoord other) {
    // Haversine distance in meters
    const R = 6371000.0;
    final dLat = (other.lat - lat) * pi / 180.0;
    final dLng = (other.lng - lng) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat * pi / 180.0) * cos(other.lat * pi / 180.0) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
}

class GraphEdge {
  final GeoCoord from;
  final GeoCoord to;
  final double baseDistanceMeters;
  final double baseDurationSeconds;

  GraphEdge({
    required this.from,
    required this.to,
    required this.baseDistanceMeters,
    double? baseDurationSeconds,
  }) : baseDurationSeconds = baseDurationSeconds ?? (baseDistanceMeters / 11.1); // ~40km/h default
}

enum HazardType {
  COLLAPSED_BRIDGE,
  FLOOD_ZONE,
  GAS_LEAK,
  STRUCTURAL_DEBRIS,
  FIRE_LINE,
}

class HazardZone {
  final String id;
  final String title;
  final HazardType type;
  final double centerLat;
  final double centerLng;
  final double radiusMeters;
  final double penaltyMultiplier; // e.g. 50.0x or 999.0x
  final bool isImpassable;

  HazardZone({
    required this.id,
    required this.title,
    required this.type,
    required this.centerLat,
    required this.centerLng,
    this.radiusMeters = 250.0,
    this.penaltyMultiplier = 50.0,
    this.isImpassable = false,
  });

  bool intersectsEdge(GeoCoord a, GeoCoord b) {
    // Point-to-segment distance check
    final pLat = centerLat;
    final pLng = centerLng;

    // Approximate planar projection in local region
    final dx = (b.lng - a.lng) * cos(a.lat * pi / 180.0);
    final dy = b.lat - a.lat;
    final px = (pLng - a.lng) * cos(a.lat * pi / 180.0);
    final py = pLat - a.lat;

    final lengthSq = dx * dx + dy * dy;
    if (lengthSq == 0) {
      return a.distanceTo(GeoCoord(id: 'hz', name: '', lat: centerLat, lng: centerLng)) <= radiusMeters;
    }

    final t = max(0.0, min(1.0, (px * dx + py * dy) / lengthSq));
    final projLat = a.lat + t * (b.lat - a.lat);
    final projLng = a.lng + t * (b.lng - a.lng);

    final dist = GeoCoord(id: 'p', name: '', lat: projLat, lng: projLng)
        .distanceTo(GeoCoord(id: 'hz', name: '', lat: centerLat, lng: centerLng));
    return dist <= radiusMeters;
  }
}

class CalculatedRoute {
  final List<GeoCoord> path;
  final double totalDistanceMeters;
  final double estimatedDurationSeconds;
  final double riskScore;
  final bool crossedHazards;
  final List<String> hazardWarnings;

  CalculatedRoute({
    required this.path,
    required this.totalDistanceMeters,
    required this.estimatedDurationSeconds,
    required this.riskScore,
    required this.crossedHazards,
    required this.hazardWarnings,
  });
}

class DijkstraRoutingService {
  final List<GeoCoord> waypoints = [];
  final List<GraphEdge> edges = [];
  final List<HazardZone> hazards = [];

  DijkstraRoutingService() {
    _initDefaultDisasterGraph();
  }

  void _initDefaultDisasterGraph() {
    // Standard hackathon disaster demo zone (San Francisco Market / Mission sector or central city)
    final w1 = const GeoCoord(id: 'HQ_STATION', name: 'Rescue Base Station Alpha', lat: 37.7749, lng: -122.4194);
    final w2 = const GeoCoord(id: 'WAYPOINT_1', name: 'Market & 8th St Bridge', lat: 37.7770, lng: -122.4150);
    final w3 = const GeoCoord(id: 'WAYPOINT_2', name: 'Mission Arterial Blvd', lat: 37.7720, lng: -122.4140);
    final w4 = const GeoCoord(id: 'WAYPOINT_3', name: '7th St Overpass', lat: 37.7790, lng: -122.4100);
    final w5 = const GeoCoord(id: 'WAYPOINT_4', name: 'Folsom Bypass Route', lat: 37.7700, lng: -122.4080);
    final w6 = const GeoCoord(id: 'WAYPOINT_5', name: 'Civic Center Accessway', lat: 37.7810, lng: -122.4160);
    final w7 = const GeoCoord(id: 'VICTIM_GROUND_ZERO', name: 'Victim Collapse Site', lat: 37.7825, lng: -122.4075);

    waypoints.addAll([w1, w2, w3, w4, w5, w6, w7]);

    void addBiEdge(GeoCoord a, GeoCoord b) {
      final dist = a.distanceTo(b);
      edges.add(GraphEdge(from: a, to: b, baseDistanceMeters: dist));
      edges.add(GraphEdge(from: b, to: a, baseDistanceMeters: dist));
    }

    // Direct Naive Path (traverses bridge area)
    addBiEdge(w1, w2);
    addBiEdge(w2, w4);
    addBiEdge(w4, w7);

    // Hazard-Avoidance Bypass Routes
    addBiEdge(w1, w6);
    addBiEdge(w6, w4);
    addBiEdge(w1, w3);
    addBiEdge(w3, w5);
    addBiEdge(w5, w7);
    addBiEdge(w2, w3);

    // Default Hazard Zone: Collapsed Bridge / Blocked Overpass directly over WAYPOINT_2 <-> WAYPOINT_4
    hazards.add(HazardZone(
      id: 'HAZ_01',
      title: 'Collapsed 8th St Bridge & Gas Leak',
      type: HazardType.COLLAPSED_BRIDGE,
      centerLat: 37.7780,
      centerLng: -122.4125,
      radiusMeters: 280.0,
      penaltyMultiplier: 50.0,
      isImpassable: false,
    ));
  }

  void addHazardZone(HazardZone zone) {
    hazards.add(zone);
  }

  void removeHazardZone(String id) {
    hazards.removeWhere((h) => h.id == id);
  }

  /// Dijkstra's algorithm with Min-Priority Queue for shortest safe path
  CalculatedRoute computeRoute({
    required GeoCoord start,
    required GeoCoord target,
    bool applyHazardPenalties = true,
  }) {
    final distances = <String, double>{};
    final previous = <String, GeoCoord?>{};
    final visited = <String>{};
    final warnings = <String>[];

    final pq = PriorityQueue<MapEntry<GeoCoord, double>>((a, b) => a.value.compareTo(b.value));

    for (final wp in waypoints) {
      distances[wp.id] = double.infinity;
      previous[wp.id] = null;
    }

    distances[start.id] = 0.0;
    pq.add(MapEntry(start, 0.0));

    while (pq.isNotEmpty) {
      final currentEntry = pq.removeFirst();
      final current = currentEntry.key;

      if (visited.contains(current.id)) continue;
      visited.add(current.id);

      if (current.id == target.id) break;

      // Inspect outgoing edges
      final outgoing = edges.where((e) => e.from.id == current.id);
      for (final edge in outgoing) {
        if (visited.contains(edge.to.id)) continue;

        double weight = edge.baseDistanceMeters;
        bool crossesAnyHazard = false;

        for (final hz in hazards) {
          if (hz.intersectsEdge(edge.from, edge.to)) {
            crossesAnyHazard = true;
            if (applyHazardPenalties) {
              if (hz.isImpassable) {
                weight += 9999999.0;
              } else {
                weight += (edge.baseDistanceMeters * hz.penaltyMultiplier);
              }
            } else {
              warnings.add('Crosses hazard: ${hz.title}');
            }
          }
        }

        final newDist = distances[current.id]! + weight;
        if (newDist < distances[edge.to.id]!) {
          distances[edge.to.id] = newDist;
          previous[edge.to.id] = current;
          pq.add(MapEntry(edge.to, newDist));
        }
      }
    }

    // Reconstruct path
    final path = <GeoCoord>[];
    GeoCoord? curr = target;
    while (curr != null) {
      path.insert(0, curr);
      curr = previous[curr.id];
    }

    if (path.isEmpty || path.first.id != start.id) {
      return CalculatedRoute(
        path: [start, target],
        totalDistanceMeters: start.distanceTo(target),
        estimatedDurationSeconds: (start.distanceTo(target) / 11.1),
        riskScore: 0.0,
        crossedHazards: false,
        hazardWarnings: ['No road graph connection found'],
      );
    }

    // Calculate actual distance without penalty skew
    double actualDistance = 0.0;
    bool hasCrossed = false;
    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      actualDistance += a.distanceTo(b);
      for (final hz in hazards) {
        if (hz.intersectsEdge(a, b)) {
          hasCrossed = true;
        }
      }
    }

    final durationSec = actualDistance / (hasCrossed ? 5.5 : 11.1); // Slowed by debris if crossed

    return CalculatedRoute(
      path: path,
      totalDistanceMeters: actualDistance,
      estimatedDurationSeconds: durationSec,
      riskScore: hasCrossed ? 85.0 : 5.0,
      crossedHazards: hasCrossed,
      hazardWarnings: warnings.toSet().toList(),
    );
  }
}
