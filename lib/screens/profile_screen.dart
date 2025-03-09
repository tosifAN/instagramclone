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

  void _signOut() async {
    await _authService.signOut();
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
      appBar: AppBar(
        title: Text(user?.username ?? 'Profile'),
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shrinkWrap: true,
                      children: [
                        'Settings',
                        'Sign Out',
                      ].map(
                        (e) => InkWell(
                          onTap: () {
                            if (e == 'Sign Out') {
                              _signOut();
                            }
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Text(e),
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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await Provider.of<UserProvider>(context, listen: false)
                    .refreshUser();
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
                                backgroundColor: Colors.grey,
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
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (user.bio.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(user.bio),
                          ],
                          const SizedBox(height: 16),
                          if (isCurrentUser)
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Implement edit profile
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.grey),
                                minimumSize: const Size(double.infinity, 36),
                              ),
                              child: const Text(
                                'Edit Profile',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(),
                    StreamBuilder(
                      stream: _firestoreService.getUserPosts(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData ||
                            (snapshot.data! as dynamic).docs.length == 0) {
                          return const Center(
                            child: Text('No posts yet'),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: (snapshot.data! as dynamic).docs.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 1.5,
                            mainAxisSpacing: 1.5,
                            childAspectRatio: 1,
                          ),
                          itemBuilder: (context, index) {
                            final post =
                                (snapshot.data! as dynamic).docs[index].data();
                            return CachedNetworkImage(
                              imageUrl: post['postUrl'],
                              fit: BoxFit.cover,
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
