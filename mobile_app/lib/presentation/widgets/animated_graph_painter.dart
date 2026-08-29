import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/node_entity.dart';

class AnimatedGraphPainter extends CustomPainter {
  final List<NodeEntity> nodes;
  final String localNodeId;
  final double animationProgress;

  AnimatedGraphPainter({
    required this.nodes,
    required this.localNodeId,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.38;

    final nodePositions = <String, Offset>{};
    nodePositions[localNodeId] = center;

    // Arrange peers in circle around local node
    final peerCount = nodes.length;
    for (int i = 0; i < peerCount; i++) {
      final angle = (2 * pi / max(1, peerCount)) * i - (pi / 2);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      nodePositions[nodes[i].nodeId] = Offset(x, y);
    }

    final linePaint = Paint()
      ..color = AppTheme.borderBright
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final activeLinePaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw Links
    for (final node in nodes) {
      final pos = nodePositions[node.nodeId];
      if (pos == null) continue;

      canvas.drawLine(center, pos, node.status == NodeConnectionStatus.connected ? activeLinePaint : linePaint);

      // Animated Packet Particle on active links
      if (node.status == NodeConnectionStatus.connected) {
        final progress = (animationProgress + (nodes.indexOf(node) * 0.25)) % 1.0;
        final px = center.dx + (pos.dx - center.dx) * progress;
        final py = center.dy + (pos.dy - center.dy) * progress;

        final particlePaint = Paint()
          ..color = AppTheme.primary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(px, py), 4, particlePaint);
      }
    }

    // Draw Peer Nodes
    for (final node in nodes) {
      final pos = nodePositions[node.nodeId];
      if (pos == null) continue;
      _drawNodeCircle(canvas, pos, node.nodeId, node.displayName, node.status == NodeConnectionStatus.connected, false);
    }

    // Draw Local Center Node
    _drawNodeCircle(canvas, center, localNodeId, 'YOU (Local)', true, true);
  }

  void _drawNodeCircle(Canvas canvas, Offset pos, String id, String label, bool isConnected, bool isLocal) {
    final color = isLocal
        ? AppTheme.primary
        : isConnected
            ? AppTheme.meshGreen
            : AppTheme.meshYellow;

    // Outer Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, isLocal ? 24 : 20, glowPaint);

    // Border
    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pos, isLocal ? 20 : 16, borderPaint);

    // Inner Fill
    final fillPaint = Paint()
      ..color = AppTheme.bgDarkest
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, isLocal ? 19 : 15, fillPaint);

    // Text Label below
    final textSpan = TextSpan(
      text: id,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        fontFamily: 'Orbitron',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy + (isLocal ? 24 : 20)));
  }

  @override
  bool shouldRepaint(covariant AnimatedGraphPainter oldDelegate) => true;
}
