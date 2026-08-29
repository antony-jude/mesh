import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/node_entity.dart';
import '../../providers/mesh_state_provider.dart';
import '../chat/chat_conversation_screen.dart';

class NearbyDevicesScreen extends StatelessWidget {
  const NearbyDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meshProvider = Provider.of<MeshStateProvider>(context);
    final nodes = meshProvider.nodes;

    return Scaffold(
      backgroundColor: AppTheme.bgDarkest,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        title: Text(
          'Nearby Mesh Nodes',
          style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            tooltip: 'Rescan BLE / Wi-Fi',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scanning for nearby BLE / Wi-Fi mesh beacons...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Radio status card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bluetooth_audio_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RADIO INTERFACE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textDim)),
                        Text('BLE Low Energy + Wi-Fi P2P', style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.meshGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.meshGreen),
                  ),
                  child: Text(
                    'ACTIVE DISCOVERY',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.meshGreen),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'DISCOVERED PEERS (${nodes.length})',
            style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),

          ...nodes.map((node) {
            final isConnected = node.status == NodeConnectionStatus.connected;
            final isDirect = node.isDirectNeighbor;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnected ? AppTheme.meshGreen.withOpacity(0.5) : AppTheme.borderSubtle,
                  width: isConnected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Status Dot & Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isConnected ? AppTheme.meshGreen.withOpacity(0.15) : AppTheme.bgDarkest,
                      shape: BoxShape.circle,
                      border: Border.all(color: isConnected ? AppTheme.meshGreen : AppTheme.borderBright),
                    ),
                    child: Center(
                      child: Icon(
                        isDirect ? Icons.bluetooth_rounded : Icons.alt_route_rounded,
                        color: isConnected ? AppTheme.meshGreen : AppTheme.textMuted,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Node Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              node.displayName,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDirect ? AppTheme.primary.withOpacity(0.15) : const Color(0xFF8B5CF6).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isDirect ? '1 HOP' : '${node.hopCount} HOPS',
                                style: GoogleFonts.firaCode(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDirect ? AppTheme.primary : const Color(0xFFC084FC),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'ID: ${node.nodeId} • ${node.rssi != null ? "${node.rssi} dBm" : "Relayed"} • Battery: ${node.batteryLevel ?? 75}%',
                          style: GoogleFonts.firaCode(fontSize: 10, color: AppTheme.textDim),
                        ),
                        if (node.intermediateHops.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Relay Path: ${node.intermediateHops.join(" → ")}',
                              style: GoogleFonts.inter(fontSize: 10, color: AppTheme.meshGreen),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primary, size: 20),
                        tooltip: 'Send Direct Message',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatConversationScreen(
                                conversationId: node.nodeId,
                                title: node.displayName,
                                receiverNodeId: node.nodeId,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          isConnected ? Icons.link_off_rounded : Icons.link_rounded,
                          color: isConnected ? AppTheme.meshRed : AppTheme.meshGreen,
                          size: 20,
                        ),
                        tooltip: isConnected ? 'Disconnect Link' : 'Connect Link',
                        onPressed: () {
                          if (isConnected) {
                            meshProvider.disconnectNode(node.nodeId);
                          } else {
                            meshProvider.connectToNode(node.nodeId);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
