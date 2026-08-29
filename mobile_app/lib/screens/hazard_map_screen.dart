import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/routing_service.dart';
import '../services/mesh_service.dart';

class HazardMapScreen extends StatefulWidget {
  final DijkstraRoutingService routingService;
  final MeshService meshService;

  const HazardMapScreen({
    super.key,
    required this.routingService,
    required this.meshService,
  });

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen> {
  CalculatedRoute? _naiveRoute;
  CalculatedRoute? _safeRoute;
  bool _showHazardPenalty = true;

  @override
  void initState() {
    super.initState();
    _recalculateRoutes();
  }

  void _recalculateRoutes() {
    final start = widget.routingService.waypoints.firstWhere((w) => w.id == 'HQ_STATION');
    final target = widget.routingService.waypoints.firstWhere((w) => w.id == 'VICTIM_GROUND_ZERO');

    _naiveRoute = widget.routingService.computeRoute(start: start, target: target, applyHazardPenalties: false);
    _safeRoute = widget.routingService.computeRoute(start: start, target: target, applyHazardPenalties: true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PHASE 4: HAZARD-AWARE RESCUE ROUTING', style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD29922))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD29922).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFD29922)),
                    ),
                    child: Text('DIJKSTRA O((V+E)logV)', style: GoogleFonts.firaCode(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFD29922))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Calculates the optimal extraction path for first responders by weighting real-time disaster hazard zones (collapsed bridges, gas leaks, flooded streets) with a 50x penalty factor to guarantee rescuer safety.',
                style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: const Color(0xFF8B949E)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Route Comparison Cards
        if (_naiveRoute != null && _safeRoute != null) ...[
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dangerous_outlined, color: Color(0xFFFF5252), size: 14),
                          const SizedBox(width: 4),
                          Text('NAIVE ROUTE', style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFFF5252))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${(_naiveRoute!.totalDistanceMeters).toInt()}m', style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Crosses Collapse Zone!', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFFF7B72))),
                      const SizedBox(height: 4),
                      Text('Risk: HIGH (${_naiveRoute!.riskScore.toInt()}%)', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFFF5252))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3FB950)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, color: Color(0xFF3FB950), size: 14),
                          const SizedBox(width: 4),
                          Text('RESQ SAFE PATH', style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF3FB950))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${(_safeRoute!.totalDistanceMeters).toInt()}m', style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Bypasses Hazard Zone', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF3FB950))),
                      const SizedBox(height: 4),
                      Text('Risk: LOW (${_safeRoute!.riskScore.toInt()}%)', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF3FB950))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // Waypoint Route Sequence Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OPTIMIZED EXTRACTION CORRIDOR', style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              if (_safeRoute != null) ...[
                for (int i = 0; i < _safeRoute!.path.length; i++) ...[
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: i == 0 ? const Color(0xFF58A6FF) : (i == _safeRoute!.path.length - 1 ? const Color(0xFFFF5252) : const Color(0xFF238636)),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${i + 1}', style: GoogleFonts.firaCode(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_safeRoute!.path[i].name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            Text('Lat: ${_safeRoute!.path[i].lat}, Lng: ${_safeRoute!.path[i].lng}', style: GoogleFonts.firaCode(fontSize: 9, color: const Color(0xFF8B949E))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (i < _safeRoute!.path.length - 1)
                    Container(
                      margin: const EdgeInsets.only(left: 11),
                      height: 16,
                      width: 2,
                      color: const Color(0xFF3FB950),
                    ),
                ],
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Active Hazards List
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ACTIVE GROUND ZERO HAZARDS', style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              for (final hz in widget.routingService.hazards) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDA3633).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hz.title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('Radius: ${hz.radiusMeters.toInt()}m | Penalty Factor: ${hz.penaltyMultiplier.toInt()}x', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8B949E))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
