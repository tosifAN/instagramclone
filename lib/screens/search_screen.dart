import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart' as model;
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isShowUsers = false;

  @override
  void initState() {
    super.initState();
    print('\n🔍 Opening Search Screen...');
    print('📸 Loading recent posts for discovery...');
  }

  @override
  void dispose() {
    print('👋 Closing Search Screen\n');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a user',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              border: InputBorder.none,
              icon: Icon(Icons.search, color: Colors.grey[600]),
            ),
            onChanged: (String query) {
              setState(() {
                _isShowUsers = true;
              });
              if (query.isEmpty) {
                print('🔍 Showing recent posts');
              } else {
                print('🔍 Searching for users matching: $query');
              }
            },
          ),
        ),
      ),
      body: _isShowUsers
          ? FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where(
                    'username',
                    isGreaterThanOrEqualTo: _searchController.text,
                  )
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  print('⌛ Loading search results...');
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
                          'Searching...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final users = (snapshot.data! as dynamic).docs;
                if (users.isEmpty) {
                  print('ℹ️ No users found matching: ${_searchController.text}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching with a different username',
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

                print('✅ Found ${users.length} users matching: ${_searchController.text}');
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    model.User user = model.User.fromSnap(users[index]);

                    return Container(
                      margin: const EdgeInsets.symmetric(
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
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                          radius: 24,
                        ),
                        title: Text(
                          user.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          print('👤 Viewing profile: ${user.username}');
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProfileScreen(uid: user.uid),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            )
          : FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('datePublished', descending: true)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  print('⌛ Loading recent posts...');
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

                final posts = (snapshot.data! as dynamic).docs;
                if (posts.isEmpty) {
                  print('ℹ️ No posts found');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Posts Yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Posts from the community will appear here',
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

                print('✅ Loaded ${posts.length} recent posts');
                return GridView.builder(
                  padding: const EdgeInsets.all(1),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                    childAspectRatio: 1,
                  ),
                  itemCount: posts.length,
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
    );
  }
}
