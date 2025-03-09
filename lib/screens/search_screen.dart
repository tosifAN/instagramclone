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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: TextFormField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search for a user',
            border: InputBorder.none,
          ),
          onChanged: (String _) {
            setState(() {
              _isShowUsers = true;
            });
          },
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
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return ListView.builder(
                  itemCount: (snapshot.data! as dynamic).docs.length,
                  itemBuilder: (context, index) {
                    model.User user = model.User.fromSnap(
                        (snapshot.data! as dynamic).docs[index]);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                      ),
                      title: Text(user.username),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(uid: user.uid),
                        ),
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
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1.5,
                    mainAxisSpacing: 1.5,
                    childAspectRatio: 1,
                  ),
                  itemCount: (snapshot.data! as dynamic).docs.length,
                  itemBuilder: (context, index) {
                    final post = (snapshot.data! as dynamic).docs[index].data();
                    return GestureDetector(
                      onTap: () {
                        // TODO: Navigate to post detail screen
                      },
                      child: CachedNetworkImage(
                        imageUrl: post['postUrl'],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
