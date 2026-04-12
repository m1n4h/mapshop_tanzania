import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get messages => _messages;
  List<Map<String, dynamic>> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchConversations(String userId) async {
    _setLoading(true);
    
    // Mock data - replace with actual API call
    await Future.delayed(const Duration(seconds: 1));
    
    _conversations = [
      {
        'id': '1',
        'participantId': '2',
        'participantName': 'Mama Mary\'s Store',
        'participantAvatar': null,
        'lastMessage': 'Your order is ready for pickup',
        'lastMessageTime': DateTime.now().subtract(const Duration(minutes: 5)),
        'unreadCount': 2,
        'type': 'seller',
      },
      {
        'id': '2',
        'participantId': '3',
        'participantName': 'Kariakoo Super Store',
        'participantAvatar': null,
        'lastMessage': 'Thank you for your order!',
        'lastMessageTime': DateTime.now().subtract(const Duration(hours: 1)),
        'unreadCount': 0,
        'type': 'seller',
      },
      {
        'id': '3',
        'participantId': '4',
        'participantName': 'John Rider',
        'participantAvatar': null,
        'lastMessage': 'I am on my way',
        'lastMessageTime': DateTime.now().subtract(const Duration(minutes: 30)),
        'unreadCount': 1,
        'type': 'rider',
      },
    ];
    
    _setLoading(false);
  }

  Future<void> fetchMessages(String conversationId) async {
    _setLoading(true);
    
    // Mock data - replace with actual API call
    await Future.delayed(const Duration(seconds: 1));
    
    _messages = [
      {
        'id': '1',
        'conversationId': conversationId,
        'senderId': '2',
        'senderName': 'Mama Mary\'s Store',
        'message': 'Hello! Your order has been confirmed.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': true,
      },
      {
        'id': '2',
        'conversationId': conversationId,
        'senderId': '1',
        'senderName': 'You',
        'message': 'Great! When will it be delivered?',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
        'isRead': true,
      },
      {
        'id': '3',
        'conversationId': conversationId,
        'senderId': '2',
        'senderName': 'Mama Mary\'s Store',
        'message': 'Your order is ready for pickup',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
        'isRead': false,
      },
    ];
    
    _setLoading(false);
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String message,
    required String senderId,
  }) async {
    _setLoading(true);
    
    // Mock send - replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderId == '1' ? 'You' : 'Other',
      'message': message,
      'timestamp': DateTime.now(),
      'isRead': false,
    };
    
    _messages.add(newMessage);
    
    // Update conversation last message
    final conversationIndex = _conversations.indexWhere((c) => c['id'] == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex]['lastMessage'] = message;
      _conversations[conversationIndex]['lastMessageTime'] = DateTime.now();
      if (senderId != '1') {
        _conversations[conversationIndex]['unreadCount'] = 
            (_conversations[conversationIndex]['unreadCount'] ?? 0) + 1;
      }
    }
    
    _setLoading(false);
    return true;
  }

  void markAsRead(String conversationId) {
    final conversationIndex = _conversations.indexWhere((c) => c['id'] == conversationId);
    if (conversationIndex != -1) {
      _conversations[conversationIndex]['unreadCount'] = 0;
    }
    
    for (var message in _messages) {
      if (message['conversationId'] == conversationId && message['senderId'] != '1') {
        message['isRead'] = true;
      }
    }
    
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}