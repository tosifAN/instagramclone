import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUsername;

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUsername,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    print('\n💬 Opening chat with ${widget.otherUsername}...');
    print('🔄 Loading messages...');
    _markChatAsRead();
  }

  @override
  void dispose() {
    print('👋 Closing chat with ${widget.otherUsername}\n');
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markChatAsRead() async {
    print('✓ Marking messages as read...');
    // TODO: Implement mark as read functionality
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      print('❌ Cannot send empty message');
      return;
    }

    setState(() {
      _isSending = true;
    });

    print('📤 Sending message...');

    try {
      final user = Provider.of<UserProvider>(context, listen: false).getUser;
      if (user == null) throw 'User not found';
      await _firestoreService.sendMessage(
        _messageController.text,  // messageContent
        user.uid,                // senderId
        widget.otherUserId,      // recipientId
      );

      print('✅ Message sent successfully');
      _messageController.clear();
    } catch (e) {
      print('❌ Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Error sending message: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.otherUsername,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline,
              size: 24,
              color: Colors.black,
            ),
            onPressed: () {
              print('ℹ️ Opening chat info...');
              // TODO: Implement chat info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('⌛ Loading messages...');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.blue,
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading messages...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  print('❌ Error loading messages: ${snapshot.error}');
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Please try again later',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final messages = (snapshot.data! as dynamic).docs;
                if (messages.isEmpty) {
                  print('ℹ️ No messages found');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Messages Yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                print('✅ Loaded ${messages.length} messages');
                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data();
                    final bool isMe = message['senderId'] == user?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          top: 4,
                          bottom: 4,
                          left: isMe ? 64 : 0,
                          right: isMe ? 0 : 64,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey[100],
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'],
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.grey[800],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _getTimeAgo(message['timestamp'].toDate()),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[100]!,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isSending ? Icons.hourglass_empty : Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isSending ? null : _sendMessage,
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}m';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
