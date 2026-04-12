import 'package:flutter/material.dart';
import 'package:mapshop_tanzania/provider/chart_provider.dart';
import 'package:mapshop_tanzania/screens/chart_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final userId = await AuthService.getUserId();
    if (userId != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.fetchConversations(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: chatProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatProvider.conversations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: chatProvider.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = chatProvider.conversations[index];
                    return _buildConversationTile(conversation);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Your conversations will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conversation) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: conversation['type'] == 'seller' 
            ? Colors.green.shade100 
            : Colors.blue.shade100,
        child: Icon(
          conversation['type'] == 'seller' ? Icons.store : Icons.delivery_dining,
          color: conversation['type'] == 'seller' ? Colors.green : Colors.blue,
        ),
      ),
      title: Text(
        conversation['participantName'],
        style: TextStyle(
          fontWeight: conversation['unreadCount'] > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation['lastMessage'],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: conversation['unreadCount'] > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(conversation['lastMessageTime']),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          if (conversation['unreadCount'] > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                conversation['unreadCount'].toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversation: conversation),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}