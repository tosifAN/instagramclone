import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    print('\n💬 Opening Comments Screen...');
    print('🔄 Loading comments...');
  }

  @override
  void dispose() {
    print('👋 Closing Comments Screen\n');
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) {
      print('❌ Cannot post empty comment');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Please write a comment'),
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
      return;
    }

    setState(() {
      _isPosting = true;
    });

    print('📝 Posting comment...');

    try {
      final user = Provider.of<UserProvider>(context, listen: false).getUser;
      if (user == null) throw 'User not found';

      await _firestoreService.postComment(
        widget.postId,
        _commentController.text,
        user.uid,
        user.username,
        user.photoUrl,
      );

      print('✅ Comment posted successfully');
      _commentController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Comment posted!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('❌ Error posting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Error posting comment: $e'),
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
      }
    } finally {
      setState(() {
        _isPosting = false;
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
          'Comments',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('datePublished', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('⌛ Loading comments...');
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
                          'Loading comments...',
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
                  print('❌ Error loading comments: ${snapshot.error}');
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

                final comments = (snapshot.data! as dynamic).docs;
                if (comments.isEmpty) {
                  print('ℹ️ No comments found');
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
                          'No Comments Yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Be the first to comment on this post!',
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

                print('✅ Loaded ${comments.length} comments');
                return ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index].data();
                    return Container(
                      margin: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.grey[100],
                            backgroundImage: CachedNetworkImageProvider(
                              comment['profilePic'],
                            ),
                            radius: 16,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment['username'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      _getTimeAgo(comment['datePublished'].toDate()),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  comment['text'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 0, color: Colors.grey[100]),
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
                  CircleAvatar(
                    backgroundColor: Colors.grey[100],
                    backgroundImage: CachedNetworkImageProvider(
                      user?.photoUrl ?? '',
                    ),
                    radius: 16,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
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
                  SizedBox(width: 12),
                  TextButton(
                    onPressed: _isPosting ? null : _postComment,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Post',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isPosting ? Colors.grey[400] : Colors.blue,
                      ),
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
