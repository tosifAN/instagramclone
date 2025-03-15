import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import 'profile_screen.dart';

class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({Key? key}) : super(key: key);

  @override
  _ActivityFeedScreenState createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    print('\n❤️ Opening Activity Feed...');
    print('🔄 Loading notifications...');
  }

  @override
  void dispose() {
    print('👋 Closing Activity Feed\n');
    super.dispose();
  }

  String _getActivityText(String type, String username) {
    switch (type) {
      case 'like':
        return '$username liked your post';
      case 'follow':
        return '$username started following you';
      case 'comment':
        return '$username commented on your post';
      default:
        return 'Unknown activity';
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'follow':
        return Icons.person_add;
      case 'comment':
        return Icons.chat_bubble;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'follow':
        return Colors.blue;
      case 'comment':
        return Colors.green;
      default:
        return Colors.grey;
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
          'Activity',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('notifications')
            .orderBy('datePublished', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('⌛ Loading notifications...');
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
                    'Loading activity...',
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
            print('❌ Error loading notifications: ${snapshot.error}');
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

          final activities = (snapshot.data! as dynamic).docs;
          if (activities.isEmpty) {
            print('ℹ️ No notifications found');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Activity Yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When someone interacts with your posts\nor follows you, you\'ll see it here.',
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

          print('✅ Loaded ${activities.length} notifications');
          return RefreshIndicator(
            color: Colors.blue,
            onRefresh: () async {
              print('🔄 Refreshing notifications...');
              await Future.delayed(Duration(seconds: 1));
              print('✅ Notifications refreshed');
            },
            child: ListView.builder(
              padding: EdgeInsets.only(top: 8),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index].data();
                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                            activity['userProfilePic'],
                          ),
                          radius: 24,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _getActivityColor(activity['type']),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getActivityIcon(activity['type']),
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                        children: [
                          TextSpan(
                            text: activity['username'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: ' ${_getActivityText(activity['type'], '').toLowerCase()}',
                          ),
                        ],
                      ),
                    ),
                    subtitle: Text(
                      _getTimeAgo(activity['datePublished'].toDate()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      print('👤 Viewing profile: ${activity['username']}');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            uid: activity['userId'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
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
