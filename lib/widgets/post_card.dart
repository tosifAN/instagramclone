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
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: CachedNetworkImageProvider(post.profImage),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (post.location != null && post.location!.isNotEmpty)
                        Text(
                          post.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            height: 4,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          if (post.uid == user?.uid)
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                              title: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () async {
                                await _firestoreService.deletePost(post.postId);
                                Navigator.of(context).pop();
                              },
                            ),
                          ListTile(
                            leading: const Icon(Icons.report_outlined),
                            title: const Text('Report'),
                            onTap: () {
                              Navigator.of(context).pop();
                              // TODO: Implement report functionality
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.share_outlined),
                            title: const Text('Share to...'),
                            onTap: () {
                              Navigator.of(context).pop();
                              // TODO: Implement share functionality
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Image Section
          GestureDetector(
            onDoubleTap: () => _likePost(user?.uid ?? ''),
            child: AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: post.postUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0095F6),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[100],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Could not load image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _likePost(user?.uid ?? ''),
                  icon: Icon(
                    post.likes.contains(user?.uid)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 24,
                    color: post.likes.contains(user?.uid)
                        ? Colors.red
                        : null,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Navigate to comments
                  },
                  icon: const Icon(
                    Icons.mode_comment_outlined,
                    size: 24,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Implement share
                  },
                  icon: const Icon(
                    Icons.send_outlined,
                    size: 24,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // TODO: Implement save post
                  },
                  icon: const Icon(
                    Icons.bookmark_border,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Likes and Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.likes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${post.likes.length} ${post.likes.length == 1 ? 'like' : 'likes'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: post.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: ' ${post.description}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to comments
                  },
                  child: Text(
                    'View all comments',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(post.datePublished),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
