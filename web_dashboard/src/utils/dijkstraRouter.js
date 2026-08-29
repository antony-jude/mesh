// Dijkstra Routing Engine with Hazard Zone Penalty Multipliers
// Computes Naive Shortest Road Path vs ResQ-Mesh Hazard-Aware Extraction Corridor

export const DEFAULT_WAYPOINTS = [
  { id: 'HQ_ALPHA', name: 'Rescue Command Base Alpha', lat: 37.7749, lng: -122.4194, type: 'BASE' },
  { id: 'WP_8TH_ST', name: '8th St & Market Intersection', lat: 37.7770, lng: -122.4150, type: 'INTERSECTION' },
  { id: 'WP_MISSION', name: 'Mission Arterial Blvd', lat: 37.7720, lng: -122.4140, type: 'BYPASS' },
  { id: 'WP_7TH_OVERPASS', name: '7th St Bridge Overpass', lat: 37.7790, lng: -122.4100, type: 'INTERSECTION' },
  { id: 'WP_FOLSOM', name: 'Folsom Safe Corridor', lat: 37.7700, lng: -122.4080, type: 'BYPASS' },
  { id: 'WP_CIVIC', name: 'Civic Center Accessway', lat: 37.7810, lng: -122.4160, type: 'BYPASS' },
  { id: 'VICTIM_COLLAPSE', name: 'Victim Ground Zero (Pinned)', lat: 37.7825, lng: -122.4075, type: 'TARGET' },
];

export const DEFAULT_EDGES = [
  // Direct arterial path (crosses bridge area)
  { from: 'HQ_ALPHA', to: 'WP_8TH_ST' },
  { from: 'WP_8TH_ST', to: 'WP_7TH_OVERPASS' },
  { from: 'WP_7TH_OVERPASS', to: 'VICTIM_COLLAPSE' },

  // South detour safe bypass
  { from: 'HQ_ALPHA', to: 'WP_MISSION' },
  { from: 'WP_MISSION', to: 'WP_FOLSOM' },
  { from: 'WP_FOLSOM', to: 'VICTIM_COLLAPSE' },

  // North detour safe bypass
  { from: 'HQ_ALPHA', to: 'WP_CIVIC' },
  { from: 'WP_CIVIC', to: 'WP_7TH_OVERPASS' },

  // Connectors
  { from: 'WP_8TH_ST', to: 'WP_MISSION' },
];

export const INITIAL_HAZARD_ZONES = [
  {
    id: 'HAZ_01',
    title: 'Collapsed 8th St Overpass & Gas Rupture',
    type: 'COLLAPSED_BRIDGE',
    severity: 'CRITICAL',
    lat: 37.7780,
    lng: -122.4125,
    radius: 300, // meters
    penaltyMultiplier: 50,
    isImpassable: false,
    color: '#ef4444'
  },
  {
    id: 'HAZ_02',
    title: 'Submerged Flash Flood Zone',
    type: 'FLOOD',
    severity: 'HIGH',
    lat: 37.7710,
    lng: -122.4110,
    radius: 200,
    penaltyMultiplier: 25,
    isImpassable: false,
    color: '#0284c7'
  }
];

// Haversine distance in meters
export function getDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Check if an edge segment intersects a circular hazard zone
export function edgeIntersectsHazard(wpA, wpB, hazard) {
  const pLat = hazard.lat;
  const pLng = hazard.lng;

  const dx = (wpB.lng - wpA.lng) * Math.cos((wpA.lat * Math.PI) / 180);
  const dy = wpB.lat - wpA.lat;
  const px = (pLng - wpA.lng) * Math.cos((wpA.lat * Math.PI) / 180);
  const py = pLat - wpA.lat;

  const lengthSq = dx * dx + dy * dy;
  if (lengthSq === 0) {
    return getDistanceMeters(wpA.lat, wpA.lng, hazard.lat, hazard.lng) <= hazard.radius;
  }

  const t = Math.max(0, Math.min(1, (px * dx + py * dy) / lengthSq));
  const projLat = wpA.lat + t * (wpB.lat - wpA.lat);
  const projLng = wpA.lng + t * (wpB.lng - wpA.lng);

  return getDistanceMeters(projLat, projLng, hazard.lat, hazard.lng) <= hazard.radius;
}

// Compute Dijkstra Route
export function solveDijkstraRoute({
  waypoints = DEFAULT_WAYPOINTS,
  edges = DEFAULT_EDGES,
  hazards = INITIAL_HAZARD_ZONES,
  startId = 'HQ_ALPHA',
  targetId = 'VICTIM_COLLAPSE',
  applyHazardPenalties = true
}) {
  const wpMap = new Map(waypoints.map(w => [w.id, w]));
  const adjacency = new Map();

  waypoints.forEach(w => adjacency.set(w.id, []));

  // Build undirected graph
  edges.forEach(e => {
    const a = wpMap.get(e.from);
    const b = wpMap.get(e.to);
    if (!a || !b) return;

    const baseDist = getDistanceMeters(a.lat, a.lng, b.lat, b.lng);
    let edgeWeight = baseDist;
    let crossesHazard = false;
    let hazardNames = [];

    hazards.forEach(h => {
      if (edgeIntersectsHazard(a, b, h)) {
        crossesHazard = true;
        hazardNames.push(h.title);
        if (applyHazardPenalties) {
          if (h.isImpassable) {
            edgeWeight += 9999999;
          } else {
            edgeWeight += baseDist * h.penaltyMultiplier;
          }
        }
      }
    });

    adjacency.get(e.from).push({ to: e.to, baseDist, weight: edgeWeight, crossesHazard, hazardNames });
    adjacency.get(e.to).push({ to: e.from, baseDist, weight: edgeWeight, crossesHazard, hazardNames });
  });

  // Dijkstra Algorithm
  const distances = {};
  const previous = {};
  const visited = new Set();
  const queue = [];

  waypoints.forEach(w => {
    distances[w.id] = Infinity;
    previous[w.id] = null;
  });

  distances[startId] = 0;
  queue.push({ id: startId, dist: 0 });

  while (queue.length > 0) {
    queue.sort((a, b) => a.dist - b.dist);
    const { id: u } = queue.shift();

    if (visited.has(u)) continue;
    visited.add(u);

    if (u === targetId) break;

    const neighbors = adjacency.get(u) || [];
    for (const edge of neighbors) {
      if (visited.has(edge.to)) continue;

      const alt = distances[u] + edge.weight;
      if (alt < distances[edge.to]) {
        distances[edge.to] = alt;
        previous[edge.to] = u;
        queue.push({ id: edge.to, dist: alt });
      }
    }
  }

  // Reconstruct path
  const pathIds = [];
  let curr = targetId;
  while (curr !== null) {
    pathIds.unshift(curr);
    curr = previous[curr];
  }

  if (pathIds.length === 0 || pathIds[0] !== startId) {
    return {
      success: false,
      path: [],
      coordinates: [],
      distanceMeters: 0,
      estimatedTimeMin: 0,
      riskScore: 0,
      crossesHazard: false,
      hazardWarnings: []
    };
  }

  const pathWaypoints = pathIds.map(id => wpMap.get(id));
  const coordinates = pathWaypoints.map(w => [w.lat, w.lng]);

  let totalActualDistance = 0;
  let crossedHazards = false;
  const warnings = [];

  for (let i = 0; i < pathWaypoints.length - 1; i++) {
    const a = pathWaypoints[i];
    const b = pathWaypoints[i + 1];
    totalActualDistance += getDistanceMeters(a.lat, a.lng, b.lat, b.lng);

    hazards.forEach(h => {
      if (edgeIntersectsHazard(a, b, h)) {
        crossedHazards = true;
        warnings.push(h.title);
      }
    });
  }

  const avgSpeedKmh = crossedHazards ? 15 : 45; // Impeded through disaster debris
  const durationMinutes = (totalActualDistance / 1000 / avgSpeedKmh) * 60;
  const riskScore = crossedHazards ? 88 : 6;

  return {
    success: true,
    path: pathWaypoints,
    coordinates,
    distanceMeters: Math.round(totalActualDistance),
    estimatedTimeMin: Math.max(1, Math.round(durationMinutes * 10) / 10),
    riskScore,
    crossesHazard: crossedHazards,
    hazardWarnings: [...new Set(warnings)]
  };
}
