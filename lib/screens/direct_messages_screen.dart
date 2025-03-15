import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

class DirectMessagesScreen extends StatefulWidget {
  const DirectMessagesScreen({Key? key}) : super(key: key);

  @override
  _DirectMessagesScreenState createState() => _DirectMessagesScreenState();
}

class _DirectMessagesScreenState extends State<DirectMessagesScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    print('\n💬 Opening Direct Messages...');
    print('🔄 Loading conversations...');
  }

  @override
  void dispose() {
    print('👋 Closing Direct Messages\n');
    super.dispose();
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
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_box_outlined,
              size: 24,
              color: Colors.black,
            ),
            onPressed: () {
              print('✏️ Creating new message...');
              // TODO: Implement new message
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('chats')
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('⌛ Loading conversations...');
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
            print('❌ Error loading conversations: ${snapshot.error}');
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

          final chats = (snapshot.data! as dynamic).docs;
          if (chats.isEmpty) {
            print('ℹ️ No conversations found');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_outlined,
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
                    'Start a conversation with your friends!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      print('✏️ Creating new message...');
                      // TODO: Implement new message
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Start a Chat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          print('✅ Loaded ${chats.length} conversations');
          return ListView.builder(
            padding: EdgeInsets.only(top: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data();
              final bool hasUnread = chat['unreadCount'] > 0;

              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hasUnread ? Colors.blue.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[100],
                        backgroundImage: CachedNetworkImageProvider(
                          chat['otherUserProfilePic'],
                        ),
                        radius: 24,
                      ),
                      if (chat['isOnline'] == true)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat['otherUsername'],
                          style: TextStyle(
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        _getTimeAgo(chat['lastMessageTime'].toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread ? Colors.blue : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat['lastMessage'],
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread ? Colors.grey[800] : Colors.grey[600],
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat['unreadCount'].toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    print('💬 Opening chat with ${chat['otherUsername']}');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chat['chatId'],
                          otherUserId: chat['otherUserId'],
                          otherUsername: chat['otherUsername'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
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
