import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sos_packet.dart';
import '../services/mesh_service.dart';
import '../services/audio_triage_service.dart';

class AcousticTriageScreen extends StatefulWidget {
  final MeshService meshService;
  final AudioTriageService audioTriageService;

  const AcousticTriageScreen({
    super.key,
    required this.meshService,
    required this.audioTriageService,
  });

  @override
  State<AcousticTriageScreen> createState() => _AcousticTriageScreenState();
}

class _AcousticTriageScreenState extends State<AcousticTriageScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  AudioClassificationResult? _latestClassification;
  GeminiNanoTriageResult? _latestTriage;
  bool _isMonitoring = false;

  final List<double> _liveWaveform = List.generate(24, (index) => 0.15 + (index % 4) * 0.1);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

    widget.audioTriageService.acousticEventStream.listen((event) {
      if (mounted) {
        setState(() {
          _latestClassification = event;
          _updateWaveform();
        });
      }
    });

    widget.audioTriageService.triageResultStream.listen((triage) {
      if (mounted) {
        setState(() {
          _latestTriage = triage;
        });
      }
    });
  }

  void _updateWaveform() {
    final random = Random();
    for (int i = 0; i < _liveWaveform.length; i++) {
      _liveWaveform[i] = 0.1 + random.nextDouble() * 0.85;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mic Status Banner
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
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _isMonitoring ? const Color(0xFF3FB950) : const Color(0xFF8B949E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isMonitoring ? 'PASSIVE MIC SAMPLING ACTIVE' : 'PASSIVE MIC STANDBY',
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isMonitoring ? const Color(0xFF3FB950) : const Color(0xFF8B949E),
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _isMonitoring,
                    activeColor: const Color(0xFF3FB950),
                    onChanged: (val) {
                      setState(() => _isMonitoring = val);
                      if (val) {
                        widget.audioTriageService.startPassiveMonitoring(
                          location: LocationPoint(lat: 37.7749, lng: -122.4194, accuracyM: 4.0),
                        );
                      } else {
                        widget.audioTriageService.stopPassiveMonitoring();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Live Waveform Visualizer
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF21262D)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _liveWaveform.map((val) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 4,
                      height: 40 * val,
                      decoration: BoxDecoration(
                        color: _isMonitoring ? const Color(0xFF58A6FF) : const Color(0xFF30363D),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stage A: MediaPipe Classifier Card
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
                  Text('STAGE A — FAST CLASSIFIER (MEDIAPIPE)', style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF58A6FF))),
                  Text('YAMNet On-Device', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8B949E))),
                ],
              ),
              const SizedBox(height: 12),
              if (_latestClassification != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_latestClassification!.category, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('${(_latestClassification!.confidence * 100).toStringAsFixed(1)}%', style: GoogleFonts.firaCode(fontSize: 14, fontWeight: FontWeight.bold, color: _latestClassification!.isDistressRelevant ? const Color(0xFFFF5252) : const Color(0xFF3FB950))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _latestClassification!.confidence,
                    backgroundColor: const Color(0xFF21262D),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _latestClassification!.isDistressRelevant ? const Color(0xFFFF5252) : const Color(0xFF58A6FF),
                    ),
                    minHeight: 8,
                  ),
                ),
              ] else ...[
                Text('No active audio event. Select a distress trigger below.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B949E))),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stage B: Gemini Nano Reasoning Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _latestTriage != null ? _getPriorityColor(_latestTriage!.priorityLabel) : const Color(0xFF30363D),
              width: _latestTriage != null ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFD2A8FF), size: 16),
                      const SizedBox(width: 6),
                      Text('STAGE B — GEMINI NANO REASONING', style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFD2A8FF))),
                    ],
                  ),
                  if (_latestTriage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(_latestTriage!.priorityLabel).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _getPriorityColor(_latestTriage!.priorityLabel)),
                      ),
                      child: Text(
                        _latestTriage!.priorityLabel.name,
                        style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, color: _getPriorityColor(_latestTriage!.priorityLabel)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_latestTriage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Text(
                    '"${_latestTriage!.reasoning}"',
                    style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, height: 1.4, color: const Color(0xFFE6EDF3)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Inference Mode: Fully Offline On-Device (AICore / Nano)', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF8B949E))),
                    Text('Score: ${(_latestTriage!.priorityScore * 100).toInt()}/100', style: GoogleFonts.firaCode(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ] else ...[
                Text('Gemini Nano reasoning pipeline ready. Triggers automatically upon high-confidence distress classification.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8B949E))),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Live Demo Acoustic Soundboard Triggers
        Text('LIVE DEMO ACOUSTIC SOUNDBOARD', style: GoogleFonts.orbitron(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF8B949E), letterSpacing: 1.0)),
        const SizedBox(height: 10),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _buildSoundboardButton(
              title: 'Rubble Tapping / Knock',
              confidence: 0.94,
              icon: Icons.pan_tool_alt_outlined,
              color: const Color(0xFFFF7B72),
            ),
            _buildSoundboardButton(
              title: 'Crying, sobbing',
              confidence: 0.89,
              icon: Icons.sentiment_very_dissatisfied,
              color: const Color(0xFFFFA657),
            ),
            _buildSoundboardButton(
              title: 'Structural Creaking / Collapse',
              confidence: 0.96,
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFFF5252),
            ),
            _buildSoundboardButton(
              title: 'Screaming / Distress',
              confidence: 0.92,
              icon: Icons.record_voice_over_outlined,
              color: const Color(0xFFFF5252),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSoundboardButton({
    required String title,
    required double confidence,
    required IconData icon,
    required Color color,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleKey(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
      ),
      onPressed: () async {
        final packet = await widget.audioTriageService.simulateAudioEvent(
          category: title,
          confidence: confidence,
          deviceId: widget.meshService.deviceId,
        );

        if (packet != null) {
          await widget.meshService.broadcastSosPacket(packet);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF238636),
                content: Text('Acoustic SOS [${packet.priorityLabel.name}] broadcasted across mesh!'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                Text('${(confidence * 100).toInt()}% conf', style: GoogleFonts.firaCode(fontSize: 9, color: const Color(0xFF8B949E))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(PriorityLabel label) {
    switch (label) {
      case PriorityLabel.CRITICAL:
        return const Color(0xFFFF5252);
      case PriorityLabel.HIGH:
        return const Color(0xFFFFA657);
      case PriorityLabel.MEDIUM:
        return const Color(0xFFD29922);
      case PriorityLabel.LOW:
        return const Color(0xFF3FB950);
    }
  }
}
