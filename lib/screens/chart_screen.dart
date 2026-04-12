import 'package:flutter/material.dart';
import 'package:mapshop_tanzania/provider/chart_provider.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? conversation;
  final String? orderId;
  
  const ChatScreen({
    super.key,
    this.conversation,
    this.orderId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentUserId = '1'; // Will be fetched from auth

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _loadMessages() {
    if (widget.conversation != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.fetchMessages(widget.conversation!['id']);
      chatProvider.markAsRead(widget.conversation!['id']);
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final message = _messageController.text.trim();
    _messageController.clear();
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(
      conversationId: widget.conversation!['id'],
      message: message,
      senderId: _currentUserId,
    );
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation?['participantName'] ?? 'Chat',
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.conversation?['type'] != null)
              Text(
                widget.conversation!['type'] == 'seller' ? 'Seller' : 'Rider',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.orderId != null)
            IconButton(
              icon: const Icon(Icons.shopping_bag),
              onPressed: () {
                Navigator.pushNamed(context, '/order_tracking', arguments: widget.orderId);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messages[index];
                      final isMe = message['senderId'].toString() == _currentUserId;
                      
                      return _buildMessageBubble(message, isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message['message'],
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message['timestamp']),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}