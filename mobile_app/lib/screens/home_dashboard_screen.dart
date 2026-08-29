import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sos_packet.dart';
import '../services/mesh_service.dart';
import '../services/sync_service.dart';
import '../services/audio_triage_service.dart';
import '../services/silent_sos_service.dart';
import '../services/routing_service.dart';
import 'role_selector_screen.dart';
import 'acoustic_triage_screen.dart';
import 'silent_sos_screen.dart';
import 'mesh_debug_screen.dart';
import 'hazard_map_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final MeshService meshService;
  final SyncService syncService;
  final AudioTriageService audioTriageService;
  final SilentSosService silentSosService;
  final DijkstraRoutingService routingService;

  const HomeDashboardScreen({
    super.key,
    required this.meshService,
    required this.syncService,
    required this.audioTriageService,
    required this.silentSosService,
    required this.routingService,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE63946).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE63946), width: 1.5),
              ),
              child: const Icon(Icons.hub_rounded, color: Color(0xFFE63946), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ResQ-Mesh',
                  style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'OFF-GRID MULTIMODAL DISASTER RELAY',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: const Color(0xFF8B949E),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Device Role Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(widget.meshService.currentRole).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getRoleColor(widget.meshService.currentRole), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getRoleColor(widget.meshService.currentRole),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.meshService.currentRole.name,
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getRoleColor(widget.meshService.currentRole),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined, color: Color(0xFF58A6FF)),
            tooltip: 'Switch Node Role',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => RoleSelectorScreen(
                    meshService: widget.meshService,
                    syncService: widget.syncService,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: [
          // Screen 0: Acoustic & Multimodal ML Triage
          AcousticTriageScreen(
            meshService: widget.meshService,
            audioTriageService: widget.audioTriageService,
          ),
          // Screen 1: Silent SOS Tap Detector
          SilentSosScreen(
            meshService: widget.meshService,
            silentSosService: widget.silentSosService,
          ),
          // Screen 2: Mesh Debug & Store-and-Forward Logs
          MeshDebugScreen(
            meshService: widget.meshService,
            syncService: widget.syncService,
          ),
          // Screen 3: Hazard-Aware Dijkstra Routing Map
          HazardMapScreen(
            routingService: widget.routingService,
            meshService: widget.meshService,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          border: Border(top: BorderSide(color: Color(0xFF30363D), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTabIndex,
          onTap: (index) => setState(() => _selectedTabIndex = index),
          backgroundColor: const Color(0xFF161B22),
          selectedItemColor: const Color(0xFF58A6FF),
          unselectedItemColor: const Color(0xFF8B949E),
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.graphic_eq_rounded),
              activeIcon: Icon(Icons.graphic_eq_rounded, color: Color(0xFF58A6FF)),
              label: 'Acoustic ML',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.touch_app_rounded),
              activeIcon: Icon(Icons.touch_app_rounded, color: Color(0xFFFF5252)),
              label: 'Silent SOS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alt_route_rounded),
              activeIcon: Icon(Icons.alt_route_rounded, color: Color(0xFF3FB950)),
              label: 'Mesh Debug',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield_outlined, color: Color(0xFFD29922)),
              label: 'Safe Route',
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(DeviceRole role) {
    switch (role) {
      case DeviceRole.VICTIM:
        return const Color(0xFFFF5252);
      case DeviceRole.RELAY:
        return const Color(0xFF58A6FF);
      case DeviceRole.GATEWAY:
        return const Color(0xFF3FB950);
    }
  }
}
