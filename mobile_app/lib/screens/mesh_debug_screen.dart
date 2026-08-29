import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/sos_packet.dart';
import '../services/mesh_service.dart';
import '../services/sync_service.dart';

class MeshDebugScreen extends StatefulWidget {
  final MeshService meshService;
  final SyncService syncService;

  const MeshDebugScreen({
    super.key,
    required this.meshService,
    required this.syncService,
  });

  @override
  State<MeshDebugScreen> createState() => _MeshDebugScreenState();
}

class _MeshDebugScreenState extends State<MeshDebugScreen> {
  @override
  void initState() {
    super.initState();
    widget.meshService.stateStream.listen((_) {
      if (mounted) setState(() {});
    });
    widget.meshService.logStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.meshService.currentRole;
    final isOnline = widget.syncService.isOnline;
    final logs = widget.meshService.debugLogs;
    final received = widget.meshService.receivedPackets;

    return Column(
      children: [
        // Summary Metrics Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF161B22),
            border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('ROLE', role.name, _getRoleColor(role)),
              _buildStatCard('RX PACKETS', '${widget.meshService.packetsReceivedCount}', const Color(0xFF58A6FF)),
              _buildStatCard('RELAYED', '${widget.meshService.packetsRelayedCount}', const Color(0xFFD2A8FF)),
              _buildStatCard('QUEUED SYNC', '${widget.meshService.queuedForSync.length}', const Color(0xFF3FB950)),
            ],
          ),
        ),

        // Live Action Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF0D1117),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LIVE PROTOCOL EVENT LOG', style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF8B949E), letterSpacing: 0.8)),
              Row(
                children: [
                  if (role == DeviceRole.GATEWAY)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3FB950),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 14),
                      label: Text('Flush to Firestore', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final count = await widget.syncService.flushQueueToCloud();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Flushed $count packets to Firestore!')),
                          );
                        }
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.list_alt_rounded, size: 18, color: Color(0xFF58A6FF)),
                    tooltip: 'Inspect Received Packets',
                    onPressed: () => _showPacketsModal(context, received),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Scrollable Log Console
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Text(
                    'No mesh packets logged yet.\nOriginate an SOS or relay from nearby node.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B949E)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final entry = logs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF21262D)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('HH:mm:ss').format(entry.timestamp),
                            style: GoogleFonts.firaCode(fontSize: 10, color: const Color(0xFF8B949E)),
                          ),
                          const SizedBox(width: 8),
                          _buildLogLevelTag(entry.level),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.message,
                              style: GoogleFonts.firaCode(fontSize: 11, height: 1.3, color: const Color(0xFFE6EDF3)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF8B949E))),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildLogLevelTag(String level) {
    Color tagColor;
    switch (level) {
      case 'PACKET':
        tagColor = const Color(0xFFFF5252);
        break;
      case 'RELAY':
        tagColor = const Color(0xFF58A6FF);
        break;
      case 'SYNC':
        tagColor = const Color(0xFF3FB950);
        break;
      case 'WARN':
        tagColor = const Color(0xFFD29922);
        break;
      default:
        tagColor = const Color(0xFF8B949E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tagColor, width: 0.8),
      ),
      child: Text(
        level,
        style: GoogleFonts.firaCode(fontSize: 9, fontWeight: FontWeight.bold, color: tagColor),
      ),
    );
  }

  void _showPacketsModal(BuildContext context, List<SosPacket> packets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFF30363D), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('STORED SOS PACKETS (${packets.length})', style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 18), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            const Divider(color: Color(0xFF30363D), height: 1),
            Expanded(
              child: packets.isEmpty
                  ? Center(child: Text('No packets stored in mesh memory', style: GoogleFonts.inter(color: const Color(0xFF8B949E))))
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: packets.length,
                      itemBuilder: (c, i) {
                        final p = packets[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(p.packetId.substring(0, 13), style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF58A6FF))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5252).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFFF5252)),
                                    ),
                                    child: Text(p.priorityLabel.name, style: GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFFF5252))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Signal: ${p.signalType.name} | Hops: ${p.hopCount}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8B949E))),
                              Text('Hop Path: ${p.hopPath.join(" -> ")}', style: GoogleFonts.firaCode(fontSize: 10, color: const Color(0xFF3FB950))),
                              const SizedBox(height: 4),
                              Text(p.classificationReasoning, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                            ],
                          ),
                        );
                      },
                    ),
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
