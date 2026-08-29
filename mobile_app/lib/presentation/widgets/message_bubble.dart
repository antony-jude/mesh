import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/message_entity.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isOutgoing;
    final isEmergency = message.isEmergency;

    Widget statusIcon;
    Color statusColor = AppTheme.textDim;
    String statusText = '';

    switch (message.status) {
      case MessageDeliveryStatus.storedLocally:
        statusIcon = const Icon(Icons.access_time_rounded, size: 12, color: AppTheme.meshYellow);
        statusColor = AppTheme.meshYellow;
        statusText = 'Stored locally (Pending peer)';
        break;
      case MessageDeliveryStatus.relaying:
        statusIcon = const Icon(Icons.alt_route_rounded, size: 12, color: AppTheme.primary);
        statusColor = AppTheme.primary;
        statusText = 'Relaying (Hop ${message.hopCount})';
        break;
      case MessageDeliveryStatus.delivered:
        statusIcon = const Icon(Icons.done_all_rounded, size: 13, color: AppTheme.meshGreen);
        statusColor = AppTheme.meshGreen;
        statusText = 'Delivered (Hop ${message.hopCount})';
        break;
      case MessageDeliveryStatus.read:
        statusIcon = const Icon(Icons.done_all_rounded, size: 13, color: Color(0xFF60A5FA));
        statusColor = const Color(0xFF60A5FA);
        statusText = 'Read';
        break;
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isEmergency
              ? const Color(0xFF3B1219)
              : isMe
                  ? const Color(0xFF1E2D4A)
                  : const Color(0xFF161E2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(
            color: isEmergency
                ? AppTheme.meshRed
                : isMe
                    ? AppTheme.primary.withOpacity(0.4)
                    : AppTheme.borderSubtle,
            width: isEmergency ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isEmergency)
              BoxShadow(
                color: AppTheme.meshRed.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isEmergency ? AppTheme.meshRed : AppTheme.primary,
                  ),
                ),
              ),
            Text(
              message.text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.4,
                color: AppTheme.textMain,
                fontWeight: isEmergency ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: GoogleFonts.firaCode(fontSize: 9, color: AppTheme.textDim),
                ),
                if (isMe) ...[
                  const SizedBox(width: 6),
                  statusIcon,
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDarkest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${message.hopCount} HOPS',
                      style: GoogleFonts.firaCode(fontSize: 8, color: AppTheme.primary),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
