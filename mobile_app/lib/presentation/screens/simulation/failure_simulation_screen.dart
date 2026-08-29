import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/mesh_state_provider.dart';

enum DemoStage {
  normalMode,
  cellularFailed,
  internetUnavailable,
  meshActivated,
  multiHopRelay,
}

class FailureSimulationScreen extends StatefulWidget {
  const FailureSimulationScreen({super.key});

  @override
  State<FailureSimulationScreen> createState() => _FailureSimulationScreenState();
}

class _FailureSimulationScreenState extends State<FailureSimulationScreen> {
  DemoStage _currentStage = DemoStage.normalMode;
  bool _nodeBConnected = true;
  String _simulationLog = '';

  void _setStage(DemoStage stage) {
    setState(() {
      _currentStage = stage;
      switch (stage) {
        case DemoStage.normalMode:
          _simulationLog = 'Normal LTE / Wi-Fi connected to cloud.';
          break;
        case DemoStage.cellularFailed:
          _simulationLog = '🚨 ALERT: Base station cellular tower link lost! Power grid failure.';
          break;
        case DemoStage.internetUnavailable:
          _simulationLog = '⚠️ Internet gateway unreachable. Engaging zero-infrastructure fallback...';
          break;
        case DemoStage.meshActivated:
          _simulationLog = '✓ MESH MODE ACTIVATED! Discovered 3 nearby MeshLink nodes over BLE.';
          break;
        case DemoStage.multiHopRelay:
          _simulationLog = '✓ Transmitting multi-hop packet: Phone A → Phone B → Phone C → Phone D.';
          break;
      }
    });
  }

  void _runFullSimulationDemo() async {
    _setStage(DemoStage.normalMode);
    await Future.delayed(const Duration(seconds: 1));
    _setStage(DemoStage.cellularFailed);
    await Future.delayed(const Duration(seconds: 2));
    _setStage(DemoStage.internetUnavailable);
    await Future.delayed(const Duration(seconds: 2));
    _setStage(DemoStage.meshActivated);
    await Future.delayed(const Duration(seconds: 2));
    _setStage(DemoStage.multiHopRelay);
  }

  @override
  Widget build(BuildContext context) {
    final meshProvider = Provider.of<MeshStateProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgDarkest,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        title: Text(
          'Network Failure Simulation',
          style: GoogleFonts.orbitron(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.meshYellow),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HACKATHON DEMO HARNESS',
                  style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.meshYellow),
                ),
                const SizedBox(height: 6),
                Text(
                  'Simulate complete cellular tower failure and demonstrate seamless store-and-forward mesh fallback in front of judges.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Automated Run Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.meshYellow,
              foregroundColor: AppTheme.bgDarkest,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(
              'RUN 30-SECOND LIVE DEMO SEQUENCE',
              style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: _runFullSimulationDemo,
          ),

          const SizedBox(height: 20),

          Text(
            'INTERACTIVE STAGES',
            style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDim, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),

          // Stage 1
          _buildStageTile(
            stage: DemoStage.normalMode,
            title: '1. NORMAL MODE',
            subtitle: 'Standard LTE / Internet active',
            icon: Icons.cell_tower_rounded,
            color: AppTheme.meshGreen,
          ),
          // Stage 2
          _buildStageTile(
            stage: DemoStage.cellularFailed,
            title: '2. CELLULAR NETWORK FAILED',
            subtitle: 'Cell towers disconnected in disaster zone',
            icon: Icons.signal_cellular_connected_no_internet_0_bar_rounded,
            color: AppTheme.meshRed,
          ),
          // Stage 3
          _buildStageTile(
            stage: DemoStage.internetUnavailable,
            title: '3. INTERNET UNAVAILABLE',
            subtitle: 'Offline store-and-forward fallback triggered',
            icon: Icons.portable_wifi_off_rounded,
            color: AppTheme.meshYellow,
          ),
          // Stage 4
          _buildStageTile(
            stage: DemoStage.meshActivated,
            title: '4. MESH MODE ACTIVATED',
            subtitle: 'Local BLE/Wi-Fi swarm established with 3 peers',
            icon: Icons.hub_rounded,
            color: AppTheme.primary,
          ),
          // Stage 5
          _buildStageTile(
            stage: DemoStage.multiHopRelay,
            title: '5. 4-NODE HOP RELAY (A → B → C → D)',
            subtitle: 'Multi-hop store-and-forward packet transmission',
            icon: Icons.alt_route_rounded,
            color: const Color(0xFFD2A8FF),
          ),

          const SizedBox(height: 20),

          // 4-Phone Diagram & Link Severing Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '4-PHONE RELAY TOPOLOGY',
                  style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPhoneNode('Phone A\n(Origin)', true),
                    _buildHopArrow(_nodeBConnected),
                    _buildPhoneNode('Phone B\n(Relay 1)', _nodeBConnected),
                    _buildHopArrow(true),
                    _buildPhoneNode('Phone C\n(Relay 2)', true),
                    _buildHopArrow(true),
                    _buildPhoneNode('Phone D\n(Target)', true),
                  ],
                ),
                const Divider(color: AppTheme.borderSubtle, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sever Phone B Relay Link', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Demonstrates offline queue buffering', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textDim)),
                      ],
                    ),
                    Switch(
                      value: _nodeBConnected,
                      activeColor: AppTheme.meshGreen,
                      inactiveThumbColor: AppTheme.meshRed,
                      onChanged: (val) {
                        setState(() {
                          _nodeBConnected = val;
                          _simulationLog = val
                              ? '✓ Phone B reconnected! Stored pending messages auto-synchronized.'
                              : '⚠️ Phone B disconnected! Messages will buffer in local queue.';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Live Simulation Log Box
          if (_simulationLog.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgDarkest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderBright),
              ),
              child: Text(
                _simulationLog,
                style: GoogleFonts.firaCode(fontSize: 11, color: AppTheme.primary, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStageTile({
    required DemoStage stage,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isCurrent = _currentStage == stage;

    return InkWell(
      onTap: () => _setStage(stage),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent ? color.withOpacity(0.15) : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrent ? color : AppTheme.borderSubtle,
            width: isCurrent ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ),
            if (isCurrent)
              Icon(Icons.check_circle_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNode(String label, bool active) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary.withOpacity(0.2) : AppTheme.bgDarkest,
            shape: BoxShape.circle,
            border: Border.all(color: active ? AppTheme.primary : AppTheme.meshRed),
          ),
          child: Icon(Icons.phone_android_rounded, size: 16, color: active ? AppTheme.primary : AppTheme.meshRed),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.firaCode(fontSize: 8, color: active ? Colors.white : AppTheme.meshRed),
        ),
      ],
    );
  }

  Widget _buildHopArrow(bool active) {
    return Icon(
      Icons.arrow_forward_rounded,
      size: 14,
      color: active ? AppTheme.meshGreen : AppTheme.meshRed,
    );
  }
}
