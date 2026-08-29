import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/mesh_state_provider.dart';
import '../../widgets/message_bubble.dart';

class ChatConversationScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final String? receiverNodeId;
  final bool isEmergency;

  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.receiverNodeId,
    this.isEmergency = false,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final meshProvider = Provider.of<MeshStateProvider>(context, listen: false);
    final receiver = widget.receiverNodeId ?? widget.conversationId;

    meshProvider.sendChatMessage(receiver, text);
    _textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meshProvider = Provider.of<MeshStateProvider>(context);
    final conversationMessages = meshProvider.messages.where((m) =>
        m.conversationId == widget.conversationId ||
        (widget.conversationId == 'BROADCAST' && m.isEmergency) ||
        m.receiverId == widget.conversationId ||
        m.senderId == widget.conversationId).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDarkest,
      appBar: AppBar(
        backgroundColor: widget.isEmergency ? const Color(0xFF261014) : AppTheme.bgSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.meshGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.conversationId == 'BROADCAST' ? 'ALL MESH NODES' : 'P2P ENCRYPTED VIA BLE MESH',
                  style: GoogleFonts.firaCode(fontSize: 8.5, color: AppTheme.textDim),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Offline Mesh Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: const Color(0xFF161E2E),
            child: Row(
              children: [
                const Icon(Icons.offline_bolt_rounded, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No cellular required. Messages are encrypted & store-and-forwarded.',
                    style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: conversationMessages.isEmpty
                ? Center(
                    child: Text(
                      'No messages in this mesh thread yet.\nType a message below to transmit.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textDim),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: conversationMessages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(message: conversationMessages[index]);
                    },
                  ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.bgSurface,
              border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type mesh message...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDim),
                        filled: true,
                        fillColor: AppTheme.bgDarkest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.bgDarkest, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
