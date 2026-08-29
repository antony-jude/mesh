import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/node_entity.dart';
import '../../providers/mesh_state_provider.dart';
import '../../widgets/mesh_status_pill.dart';
import '../chat/chat_conversation_screen.dart';
import '../emergency/emergency_broadcast_screen.dart';
import '../nearby/nearby_devices_screen.dart';
import '../network_map/network_map_screen.dart';
import '../simulation/failure_simulation_screen.dart';
import '../debug/developer_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meshProvider = Provider.of<MeshStateProvider>(context);
    final nodes = meshProvider.nodes;
    final messages = meshProvider.messages;
    final connectedCount = nodes.where((n) => n.status == NodeConnectionStatus.connected).length;

    // Group messages into distinct conversations
    final conversations = <String, Map<String, dynamic>>{};
    for (final msg in messages) {
      final convKey = msg.conversationId;
      if (!conversations.containsKey(convKey) || msg.timestamp.isAfter(conversations[convKey]!['lastTime'])) {
        conversations[convKey] = {
          'id': convKey,
          'name': convKey == 'BROADCAST' ? '📢 Emergency Broadcast Channel' : msg.senderId == meshProvider.localNodeId ? msg.receiverId : msg.senderName,
          'lastText': msg.text,
          'lastTime': msg.timestamp,
          'isEmergency': msg.isEmergency,
          'unread': 0,
        };
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDarkest,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary),
              ),
              child: const Icon(Icons.hub_rounded, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MeshLink',
                  style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  'NODE: ${meshProvider.localNodeId}',
                  style: GoogleFonts.firaCode(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined, color: AppTheme.meshYellow),
            tooltip: 'Network Failure Simulator',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FailureSimulationScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined, color: AppTheme.primary),
            tooltip: 'Developer Debug Dashboard',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperDashboardScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Prominent MESH MODE Status Pill
          MeshStatusPill(
            state: meshProvider.connectivityState,
            nearbyCount: nodes.length,
            connectedCount: connectedCount,
          ),

          const SizedBox(height: 14),

          // 2. Metrics Strip (Pending messages, Hops, Battery)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'CONNECTED',
                  value: '$connectedCount / ${nodes.length}',
                  icon: Icons.cell_tower_rounded,
                  color: AppTheme.meshGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'PENDING QUEUE',
                  value: '${meshProvider.pendingQueueSize} msgs',
                  icon: Icons.sync_rounded,
                  color: meshProvider.pendingQueueSize > 0 ? AppTheme.meshYellow : AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'PACKETS RELAYED',
                  value: '${meshProvider.metrics.packetsRelayed}',
                  icon: Icons.alt_route_rounded,
                  color: const Color(0xFFD2A8FF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3. Quick Action Hub
          Row(
            children: [
              // Emergency Broadcast Trigger (High Visibility)
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB91C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.meshRed, width: 1.5),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmergencyBroadcastScreen()),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'EMERGENCY',
                        style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Network Map Button
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.bgSurface,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.borderBright),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NetworkMapScreen()),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hub_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'MAP',
                        style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Nearby Peers Button
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.bgSurface,
                    foregroundColor: AppTheme.textMain,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.borderBright),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NearbyDevicesScreen()),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.devices_other_rounded, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'PEERS',
                        style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Conversations Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE CONVERSATIONS',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                '${conversations.length} Active',
                style: GoogleFonts.firaCode(fontSize: 11, color: AppTheme.textDim),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5. Conversations List
          if (conversations.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: AppTheme.textDim),
                  const SizedBox(height: 10),
                  Text(
                    'No mesh messages yet',
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap Peers or Emergency SOS to transmit across the mesh',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textDim),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: conversations.values.length,
              itemBuilder: (context, index) {
                final conv = conversations.values.toList()[index];
                final isBroadcast = conv['id'] == 'BROADCAST';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: conv['isEmergency'] ? const Color(0xFF261014) : AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: conv['isEmergency'] ? AppTheme.meshRed.withOpacity(0.5) : AppTheme.borderSubtle,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isBroadcast
                          ? AppTheme.meshRed.withOpacity(0.2)
                          : AppTheme.primary.withOpacity(0.2),
                      child: Icon(
                        isBroadcast ? Icons.emergency_rounded : Icons.person_rounded,
                        color: isBroadcast ? AppTheme.meshRed : AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            conv['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: conv['isEmergency'] ? AppTheme.meshRed : Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(conv['lastTime']),
                          style: GoogleFonts.firaCode(fontSize: 10, color: AppTheme.textDim),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      conv['lastText'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatConversationScreen(
                            conversationId: conv['id'],
                            title: conv['name'],
                            isEmergency: conv['isEmergency'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: color,
              ),

              const SizedBox(width: 4),

              // This prevents the label from overflowing
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDim,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.firaCode(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  }

