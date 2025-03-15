import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/post_card.dart';
import '../models/post.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    print('\n📱 Opening Feed Screen...');
    print('🔄 Loading posts...');
  }

  @override
  void dispose() {
    print('👋 Closing Feed Screen\n');
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
        title: const Text(
          'Instagram',
          style: TextStyle(
            fontFamily: 'Billabong',
            fontSize: 32,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 24),
            onPressed: () {
              print('📸 Opening Add Post screen...');
              // TODO: Navigate to add post screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_outlined, size: 24),
            onPressed: () {
              print('❤️ Opening Activity Feed...');
              // TODO: Navigate to activity feed
            },
          ),
          IconButton(
            icon: const Icon(Icons.messenger_outline, size: 24),
            onPressed: () {
              print('💬 Opening Direct Messages...');
              // TODO: Navigate to direct messages
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.blue,
        onRefresh: () async {
          print('🔄 Refreshing feed...');
          await Future.delayed(const Duration(seconds: 1));
          print('✅ Feed refreshed!');
        },
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .orderBy('datePublished', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              print('⌛ Loading posts...');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.blue,
                      strokeWidth: 2,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading posts...',
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
              print('❌ Error loading posts: ${snapshot.error}');
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
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Something went wrong',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please try again later',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print('ℹ️ No posts found');
              return Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 96,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Posts Yet',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When you share photos, they will appear on your profile.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          print('📸 Opening Add Post screen...');
                          // TODO: Navigate to share photo screen
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Share your first photo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            print('✅ Posts loaded successfully! Found ${snapshot.data!.docs.length} posts');
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                Post post = Post.fromSnap(snapshot.data!.docs[index]);
                return Column(
                  children: [
                    PostCard(post: post),
                    if (index < snapshot.data!.docs.length - 1)
                      Divider(
                        height: 0,
                        color: Colors.grey[100],
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
