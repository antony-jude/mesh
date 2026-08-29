import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sos_packet.dart';
import '../services/mesh_service.dart';
import '../services/silent_sos_service.dart';

class SilentSosScreen extends StatefulWidget {
  final MeshService meshService;
  final SilentSosService silentSosService;

  const SilentSosScreen({
    super.key,
    required this.meshService,
    required this.silentSosService,
  });

  @override
  State<SilentSosScreen> createState() => _SilentSosScreenState();
}

class _SilentSosScreenState extends State<SilentSosScreen> with SingleTickerProviderStateMixin {
  int _currentTapCount = 0;
  double _currentMagnitude = 0.0;
  bool _isListening = false;
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

    widget.silentSosService.tapProgressStream.listen((count) {
      if (mounted) {
        setState(() => _currentTapCount = count);
      }
    });

    widget.silentSosService.rawMagnitudeStream.listen((mag) {
      if (mounted) {
        setState(() => _currentMagnitude = mag);
      }
    });

    widget.silentSosService.sosTriggeredStream.listen((packet) {
      if (mounted) {
        widget.meshService.broadcastSosPacket(packet);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDA3633),
            content: Row(
              children: [
                const Icon(Icons.emergency_share, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SILENT SOS TRIGGERED! CRITICAL packet broadcasted over mesh.',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description Card
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
                  Row(
                    children: [
                      const Icon(Icons.sensors, color: Color(0xFFFF5252), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'STAGE C — SILENT SOS ACCELEROMETER',
                        style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFF5252)),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isListening,
                    activeColor: const Color(0xFFFF5252),
                    onChanged: (val) {
                      setState(() => _isListening = val);
                      if (val) {
                        widget.silentSosService.startListening(deviceId: widget.meshService.deviceId);
                      } else {
                        widget.silentSosService.stopListening();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Designed for incapacitated, buried, or quiet victims who cannot speak or type. Rhythmic accelerometer peak detection decodes deliberate tap patterns (3 Short + 1 Long Tap) and instantly emits an unalterable CRITICAL priority mesh packet.',
                style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: const Color(0xFF8B949E)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Rhythm Progress Indicators
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            children: [
              Text('REQUIRED RHYTHM: [ SHORT • SHORT • SHORT • LONG ]', style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE6EDF3))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTapStep(1, 'SHORT', _currentTapCount >= 1),
                  _buildTapStep(2, 'SHORT', _currentTapCount >= 2),
                  _buildTapStep(3, 'SHORT', _currentTapCount >= 3),
                  _buildTapStep(4, 'LONG', _currentTapCount >= 4, isLong: true),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Large Interactive Tap Target Pad
        Center(
          child: GestureDetector(
            onTapDown: (_) {
              final isLong = _currentTapCount == 3;
              widget.silentSosService.simulateTap(
                tapType: isLong ? TapType.long : TapType.short,
                deviceId: widget.meshService.deviceId,
              );
            },
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                final scale = _currentTapCount > 0 ? 1.0 + (_pulseAnim.value * 0.05) : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _currentTapCount == 0 ? const Color(0xFF21262D) : const Color(0xFFDA3633).withOpacity(0.8),
                          _currentTapCount == 0 ? const Color(0xFF161B22) : const Color(0xFF8E1515),
                        ],
                      ),
                      border: Border.all(
                        color: _currentTapCount == 0 ? const Color(0xFF30363D) : const Color(0xFFFF5252),
                        width: _currentTapCount > 0 ? 3.0 : 1.5,
                      ),
                      boxShadow: [
                        if (_currentTapCount > 0)
                          BoxShadow(
                            color: const Color(0xFFFF5252).withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 54,
                          color: _currentTapCount > 0 ? Colors.white : const Color(0xFF8B949E),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentTapCount == 0 ? 'TAP SCREEN OR KNOCK PHONE' : 'TAP ${_currentTapCount}/4 RECORDED',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.orbitron(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _currentTapCount > 0 ? Colors.white : const Color(0xFF8B949E),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Live Acceleration Sensor Stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF21262D)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SENSOR MAGNITUDE', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8B949E))),
              Text(
                '${_currentMagnitude.toStringAsFixed(2)} m/s²',
                style: GoogleFonts.firaCode(fontSize: 12, fontWeight: FontWeight.bold, color: _currentMagnitude > 14.5 ? const Color(0xFFFF5252) : Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTapStep(int index, String label, bool active, {bool isLong = false}) {
    return Column(
      children: [
        Container(
          width: isLong ? 54 : 42,
          height: 42,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF5252) : const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(isLong ? 10 : 21),
            border: Border.all(color: active ? const Color(0xFFFF5252) : const Color(0xFF30363D), width: 1.5),
          ),
          child: Center(
            child: Text(
              '$index',
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: active ? Colors.black : const Color(0xFF8B949E),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: active ? const Color(0xFFFF5252) : const Color(0xFF8B949E),
          ),
        ),
      ],
    );
  }
}
