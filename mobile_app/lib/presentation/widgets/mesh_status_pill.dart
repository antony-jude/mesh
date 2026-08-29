import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/mesh_network_manager.dart';

class MeshStatusPill extends StatelessWidget {
  final MeshConnectivityState state;
  final int nearbyCount;
  final int connectedCount;

  const MeshStatusPill({
    super.key,
    required this.state,
    required this.nearbyCount,
    required this.connectedCount,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusTitle;
    String statusSubtitle;
    IconData statusIcon;

    switch (state) {
      case MeshConnectivityState.connected:
        statusColor = AppTheme.meshGreen;
        statusTitle = 'MESH MODE ACTIVE';
        statusSubtitle = 'Online through $connectedCount nearby devices';
        statusIcon = Icons.hub_rounded;
        break;
      case MeshConnectivityState.limited:
        statusColor = AppTheme.meshYellow;
        statusTitle = 'LIMITED MESH';
        statusSubtitle = 'Connected to $connectedCount peer (Searching for relays)';
        statusIcon = Icons.wifi_tethering_rounded;
        break;
      case MeshConnectivityState.isolated:
        statusColor = AppTheme.meshRed;
        statusTitle = 'ISOLATED NODE';
        statusSubtitle = 'No nearby devices found • Store-and-forward active';
        statusIcon = Icons.portable_wifi_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: statusColor, blurRadius: 6, spreadRadius: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusTitle,
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  statusSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bgDarkest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              children: [
                Text(
                  '$nearbyCount',
                  style: GoogleFonts.firaCode(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                Text(
                  'NEARBY',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
