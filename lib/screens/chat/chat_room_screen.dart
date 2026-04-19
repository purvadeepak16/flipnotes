import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../models/chat_model.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatGroup group;

  const ChatRoomScreen({Key? key, required this.group}) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.firebaseUser;
    final userName = authProvider.displayName;

    if (user != null) {
      _messageController.clear();
      await _chatService.sendMessage(widget.group.id, user.uid, userName, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.firebaseUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getGroupMessagesStream(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.chatsPink));
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading messages', style: TextStyle(color: Colors.red)));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hi!',
                        style: TextStyle(color: AppColors.mutedText)),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final timeStr = DateFormat.jm().format(message.timestamp.toDate());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message.senderName,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.mutedText),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? AppColors.chatsPink : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
              ),
              boxShadow: [
                if (!isMe)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  )
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.darkText,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
            child: Text(
              timeStr,
              style: const TextStyle(fontSize: 9, color: AppColors.mutedText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x1A000000), width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.mutedText),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.chatsPink,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
