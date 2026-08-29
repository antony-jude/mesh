import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sos_packet.dart';
import '../services/mesh_service.dart';
import '../services/sync_service.dart';

class RoleSelectorScreen extends StatefulWidget {
  final MeshService meshService;
  final SyncService syncService;

  const RoleSelectorScreen({
    super.key,
    required this.meshService,
    required this.syncService,
  });

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen> {
  @override
  Widget build(BuildContext context) {
    final currentRole = widget.meshService.currentRole;
    final isOnline = widget.syncService.isOnline;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mesh Node Configuration',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device Info Card
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
                    Text('NODE IDENTIFIER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF8B949E))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF238636).withOpacity(0.3) : const Color(0xFFDA3633).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isOnline ? const Color(0xFF3FB950) : const Color(0xFFF85149)),
                      ),
                      child: Text(
                        isOnline ? 'CLOUD CONNECTED' : 'AIRPLANE / MESH ONLY',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isOnline ? const Color(0xFF3FB950) : const Color(0xFFF85149)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(widget.meshService.deviceId, style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF58A6FF))),
                const Divider(color: Color(0xFF30363D), height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetric('STRATEGY', 'P2P_CLUSTER'),
                    _buildMetric('ENCRYPTION', 'AES-256 (CBC)'),
                    _buildMetric('PEERS', '${widget.meshService.connectedEndpoints.length} ACTIVE'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'SELECT OPERATIONAL ROLE',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF8B949E), letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),

          // Role 1: VICTIM
          _buildRoleTile(
            role: DeviceRole.VICTIM,
            title: '1. VICTIM / SENSOR NODE',
            subtitle: 'Runs passive on-device audio ML triage & accelerometer silent SOS. Encrypts and transmits emergency packets into the BLE/Wi-Fi mesh.',
            color: const Color(0xFFFF5252),
            icon: Icons.person_pin_circle_outlined,
            isSelected: currentRole == DeviceRole.VICTIM,
          ),
          const SizedBox(height: 12),

          // Role 2: RELAY
          _buildRoleTile(
            role: DeviceRole.RELAY,
            title: '2. STORE-AND-FORWARD RELAY',
            subtitle: 'Acts as intermediate mesh hop. Receives encrypted packets, dedupes by UUID, increments hop count, and flood-rebroadcasts to neighbor nodes.',
            color: const Color(0xFF58A6FF),
            icon: Icons.repeat_rounded,
            isSelected: currentRole == DeviceRole.RELAY,
          ),
          const SizedBox(height: 12),

          // Role 3: GATEWAY
          _buildRoleTile(
            role: DeviceRole.GATEWAY,
            title: '3. CLOUD GATEWAY NODE',
            subtitle: 'Buffers received mesh packets in an offline queue. When cellular/Wi-Fi connection is detected, automatically flushes batch to Firestore.',
            color: const Color(0xFF3FB950),
            icon: Icons.cloud_sync_outlined,
            isSelected: currentRole == DeviceRole.GATEWAY,
          ),

          const SizedBox(height: 24),
          // Demo Connectivity Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simulate Internet Reconnection', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Toggles Gateway upload trigger for live demo', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8B949E))),
                  ],
                ),
                Switch(
                  value: isOnline,
                  activeColor: const Color(0xFF3FB950),
                  onChanged: (val) {
                    widget.syncService.setSimulatedConnectivity(val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF8B949E))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }

  Widget _buildRoleTile({
    required DeviceRole role,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        widget.meshService.setRole(role);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFF30363D),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.white)),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                          child: Text('ACTIVE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: const Color(0xFF8B949E))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
