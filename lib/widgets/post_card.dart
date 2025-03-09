import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../models/user.dart' as model;
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final FirestoreService _firestoreService = FirestoreService();

  PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  void _likePost(String uid) async {
    await _firestoreService.likePost(post.postId, uid, post.likes);
  }

  @override
  Widget build(BuildContext context) {
    final model.User? user = Provider.of<UserProvider>(context).getUser;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ).copyWith(right: 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: CachedNetworkImageProvider(post.profImage),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      post.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shrinkWrap: true,
                          children: [
                            'Delete',
                          ]
                              .map(
                                (e) => InkWell(
                                  onTap: () async {
                                    if (e == 'Delete' && post.uid == user?.uid) {
                                      await _firestoreService.deletePost(post.postId);
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    child: Text(e),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),

          // Image Section
          GestureDetector(
            onDoubleTap: () => _likePost(user?.uid ?? ''),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: post.postUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),

          // Like & Comment Section
          Row(
            children: [
              IconButton(
                onPressed: () => _likePost(user?.uid ?? ''),
                icon: Icon(
                  post.likes.contains(user?.uid)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: post.likes.contains(user?.uid)
                      ? Colors.red
                      : null,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.comment_outlined),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.send),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),

          // Description and Comments
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.w800),
                  child: Text(
                    '${post.likes.length} likes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 8),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: post.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' ${post.description}'),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: const Text(
                      'View all comments',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    timeago.format(post.datePublished),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
