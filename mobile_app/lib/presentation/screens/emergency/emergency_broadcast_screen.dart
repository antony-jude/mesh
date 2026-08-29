import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/emergency_payload.dart';
import '../../providers/mesh_state_provider.dart';

class EmergencyBroadcastScreen extends StatefulWidget {
  const EmergencyBroadcastScreen({super.key});

  @override
  State<EmergencyBroadcastScreen> createState() => _EmergencyBroadcastScreenState();
}

class _EmergencyBroadcastScreenState extends State<EmergencyBroadcastScreen> {
  EmergencyCategory _selectedCategory = EmergencyCategory.medical;
  final TextEditingController _customDetailsController = TextEditingController();
  bool _includeLocation = false;
  bool _isTransmitting = false;

  final Map<EmergencyCategory, Map<String, dynamic>> _templates = {
    EmergencyCategory.medical: {
      'title': 'CRITICAL MEDICAL ASSISTANCE NEEDED',
      'desc': 'Injured survivor requiring urgent medical stabilization and extraction.',
      'icon': Icons.medical_services_rounded,
      'color': Color(0xFFEF4444),
    },
    EmergencyCategory.foodWater: {
      'title': 'FOOD & CLEAN WATER SUPPLY CRITICAL',
      'desc': 'Immediate need for potable water and emergency rations.',
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFFF97316),
    },
    EmergencyCategory.evacuation: {
      'title': 'IMMEDIATE EVACUATION REQUIRED',
      'desc': 'Structural collapse / rising hazard. Need immediate evacuation corridor.',
      'icon': Icons.run_circle_outlined,
      'color': Color(0xFFDC2626),
    },
    EmergencyCategory.missingPerson: {
      'title': 'MISSING PERSON SEARCH & RESCUE',
      'desc': 'Unaccounted survivor separated from family in vicinity.',
      'icon': Icons.person_search_rounded,
      'color': Color(0xFFEAB308),
    },
    EmergencyCategory.general: {
      'title': 'GENERAL DISTRESS BROADCAST',
      'desc': 'Emergency assistance required. Standing by on MeshLink.',
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFFF5252),
    },
  };

  void _transmitEmergency() async {
    setState(() => _isTransmitting = true);
    final meshProvider = Provider.of<MeshStateProvider>(context, listen: false);
    final template = _templates[_selectedCategory]!;
    final customDetails = _customDetailsController.text.trim();

    final finalDesc = customDetails.isNotEmpty
        ? '${template['desc']}\nDetails: $customDetails'
        : template['desc'] as String;

    await meshProvider.sendEmergencyBroadcast(
      category: _selectedCategory,
      title: template['title'] as String,
      description: finalDesc,
      includeLocation: _includeLocation,
      lat: _includeLocation ? 37.7825 : null,
      lng: _includeLocation ? -122.4075 : null,
    );

    setState(() => _isTransmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.meshRed,
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('EMERGENCY BROADCAST TRANSMITTED ACROSS ALL MESH HOPS!')),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _customDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDarkest,
      appBar: AppBar(
        backgroundColor: const Color(0xFF261014),
        title: Text(
          'Emergency Mesh Broadcast',
          style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.meshRed),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF261014),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.meshRed.withOpacity(0.6), width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.emergency_share_rounded, color: AppTheme.meshRed, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HIGH PRIORITY FLOOD BROADCAST',
                        style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'This message will flood all nearby nodes and relay through multiple hops with maximum TTL.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'SELECT EMERGENCY TEMPLATE',
            style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),

          // Template Cards
          ..._templates.entries.map((entry) {
            final category = entry.key;
            final item = entry.value;
            final isSelected = _selectedCategory == category;
            final color = item['color'] as Color;

            return InkWell(
              onTap: () => setState(() => _selectedCategory = category),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : AppTheme.borderSubtle,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, color: color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: GoogleFonts.orbitron(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['desc'] as String,
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: color, size: 20),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 14),

          // Custom Details Input
          TextField(
            controller: _customDetailsController,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Additional details (e.g. 2 adults trapped in building B)...',
              hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textDim),
              filled: true,
              fillColor: AppTheme.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.meshRed),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // User-Controlled Location Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Include GPS Coordinates', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('User-controlled privacy toggle', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textDim)),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _includeLocation,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => setState(() => _includeLocation = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Transmit Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.meshRed, width: 2),
              ),
              elevation: 8,
            ),
            onPressed: _isTransmitting ? null : _transmitEmergency,
            child: _isTransmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emergency_rounded, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'BROADCAST TO ENTIRE MESH',
                        style: GoogleFonts.orbitron(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
