import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? uid;
  const ProfileScreen({Key? key, this.uid}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  int _postCount = 0;

  @override
  void initState() {
    super.initState();
    print('\n👤 Opening Profile Screen...');
    print('🔄 Loading user data and posts...');
  }

  @override
  void dispose() {
    print('👋 Closing Profile Screen\n');
    super.dispose();
  }

  void _signOut() async {
    print('🚪 Signing out...');
    await _authService.signOut();
    print('✅ Signed out successfully');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).getUser;
    final isCurrentUser = widget.uid == null || widget.uid == user?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          user?.username ?? 'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                print('⚙️ Opening menu options...');
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      children: [
                        'Settings',
                        'Sign Out',
                      ].map(
                        (e) => InkWell(
                          onTap: () {
                            if (e == 'Sign Out') {
                              _signOut();
                            } else {
                              print('⚙️ Opening $e...');
                            }
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Text(
                              e,
                              style: TextStyle(
                                fontSize: 14,
                                color: e == 'Sign Out' ? Colors.red : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading profile...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: Colors.blue,
              onRefresh: () async {
                print('🔄 Refreshing profile...');
                await Provider.of<UserProvider>(context, listen: false)
                    .refreshUser();
                print('✅ Profile refreshed');
              },
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[100],
                                backgroundImage: CachedNetworkImageProvider(
                                  user.photoUrl,
                                ),
                                radius: 40,
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    buildStatColumn(_postCount, "posts"),
                                    buildStatColumn(
                                        user.followers.length, "followers"),
                                    buildStatColumn(
                                        user.following.length, "following"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          if (user.bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.bio,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (isCurrentUser)
                            ElevatedButton(
                              onPressed: () {
                                print('✏️ Opening Edit Profile...');
                                // TODO: Implement edit profile
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: const Size(double.infinity, 36),
                              ),
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Divider(height: 0, color: Colors.grey[100]),
                    StreamBuilder(
                      stream: _firestoreService.getUserPosts(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          print('⌛ Loading posts...');
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.blue,
                                    strokeWidth: 2,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading posts...',
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

                        final posts = (snapshot.data! as dynamic).docs;
                        if (!snapshot.hasData || posts.length == 0) {
                          print('ℹ️ No posts found');
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.photo_library_outlined,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No Posts Yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    isCurrentUser
                                        ? 'Share your first photo with the world!'
                                        : 'This user hasn\'t posted anything yet.',
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

                        print('✅ Loaded ${posts.length} posts');
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(1),
                          itemCount: posts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 1,
                            mainAxisSpacing: 1,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            final post = posts[index].data();
                            return GestureDetector(
                              onTap: () {
                                print('🖼️ Opening post details...');
                                // TODO: Navigate to post detail screen
                              },
                              child: CachedNetworkImage(
                                imageUrl: post['postUrl'],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[100],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.blue,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[100],
                                  child: Icon(
                                    Icons.error_outline,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          num.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
