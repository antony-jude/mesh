import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/mesh_state_provider.dart';

class DeveloperDashboardScreen extends StatelessWidget {
  const DeveloperDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meshProvider = Provider.of<MeshStateProvider>(context);
    final metrics = meshProvider.metrics;
    final nodes = meshProvider.nodes;

    return Scaffold(
      backgroundColor: AppTheme.bgDarkest,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        title: Text(
          'MeshLink Telemetry & Debug',
          style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Node Identity Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LOCAL NODE IDENTITY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDim)),
                    Text('BLE & WI-FI ACTIVE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.meshGreen)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(meshProvider.localNodeId, style: GoogleFonts.firaCode(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                Text(meshProvider.displayName, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
                const Divider(color: AppTheme.borderSubtle, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn('TRANSPORT', meshProvider.networkManager.transport.transportName),
                    _buildInfoColumn('BATTERY', '84% (Optimal)'),
                    _buildInfoColumn('DEFAULT TTL', '10 Hops'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'PACKET ROUTING METRICS',
            style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),

          // Routing Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _buildMetricCard('PACKETS SENT', '${metrics.packetsSent}', AppTheme.primary, Icons.arrow_upward_rounded),
              _buildMetricCard('PACKETS RECEIVED', '${metrics.packetsReceived}', AppTheme.meshGreen, Icons.arrow_downward_rounded),
              _buildMetricCard('PACKETS RELAYED', '${metrics.packetsRelayed}', const Color(0xFFD2A8FF), Icons.alt_route_rounded),
              _buildMetricCard('DUPLICATES DROPPED', '${metrics.packetsDroppedDuplicates}', AppTheme.meshYellow, Icons.loop_rounded),
              _buildMetricCard('EXPIRED TTL DROPPED', '${metrics.packetsDroppedExpiredTtl}', AppTheme.meshRed, Icons.timer_off_outlined),
              _buildMetricCard('DELIVERY ACKS', '${metrics.deliveryAcksReceived}', const Color(0xFF60A5FA), Icons.done_all_rounded),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'ROUTING TABLE & PEER HOPS (${nodes.length})',
            style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),

          // Peer routing table
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppTheme.bgDarkest,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('NODE ID', style: GoogleFonts.firaCode(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textDim))),
                      Expanded(flex: 2, child: Text('HOPS', style: GoogleFonts.firaCode(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textDim))),
                      Expanded(flex: 2, child: Text('RSSI', style: GoogleFonts.firaCode(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textDim))),
                      Expanded(flex: 2, child: Text('STATUS', style: GoogleFonts.firaCode(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textDim))),
                    ],
                  ),
                ),
                ...nodes.map((n) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(n.nodeId, style: GoogleFonts.firaCode(fontSize: 10, color: Colors.white))),
                        Expanded(flex: 2, child: Text('${n.hopCount}', style: GoogleFonts.firaCode(fontSize: 10, color: AppTheme.primary))),
                        Expanded(flex: 2, child: Text(n.rssi != null ? '${n.rssi} dBm' : 'Relayed', style: GoogleFonts.firaCode(fontSize: 9, color: AppTheme.textMuted))),
                        Expanded(
                          flex: 2,
                          child: Text(
                            n.status.name.toUpperCase(),
                            style: GoogleFonts.firaCode(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: n.status.name == 'connected' ? AppTheme.meshGreen : AppTheme.meshYellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.textDim)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.firaCode(fontSize: 10, color: Colors.white)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.textDim)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
