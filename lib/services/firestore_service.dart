import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> createUser(User user) async {
    print('\n👤 Creating/Updating user profile in database...');
    await _firestore.collection('users').doc(user.uid).set(user.toJson());
    print('✅ User profile saved successfully!\n');
  }

  Future<User> getUser(String uid) async {
    print('\n🔍 Fetching user profile...');
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    print('✅ User profile retrieved!\n');
    return User.fromSnap(doc);
  }

  Future<void> followUser(String uid, String followId) async {
    print('\n👥 Processing follow/unfollow action...');
    DocumentSnapshot snap = await _firestore.collection('users').doc(uid).get();
    List following = (snap.data()! as dynamic)['following'];

    if (following.contains(followId)) {
      print('🔄 Unfollowing user...');
      await _firestore.collection('users').doc(followId).update({
        'followers': FieldValue.arrayRemove([uid])
      });

      await _firestore.collection('users').doc(uid).update({
        'following': FieldValue.arrayRemove([followId])
      });
      print('✅ User unfollowed successfully!\n');
    } else {
      print('🤝 Following user...');
      await _firestore.collection('users').doc(followId).update({
        'followers': FieldValue.arrayUnion([uid])
      });

      await _firestore.collection('users').doc(uid).update({
        'following': FieldValue.arrayUnion([followId])
      });
      print('✅ User followed successfully!\n');
    }
  }

  // Post operations
  Future<String> uploadPost(
    String uid,
    String username,
    String description,
    String postUrl,
    String profImage,
  ) async {
    print('\n📝 Creating new post...');
    String postId = const Uuid().v1();
    Post post = Post(
      postId: postId,
      uid: uid,
      username: username,
      description: description,
      postUrl: postUrl,
      profImage: profImage,
      datePublished: DateTime.now(),
      likes: [],
    );

    print('💾 Saving post to database...');
    await _firestore.collection('posts').doc(postId).set(post.toJson());
    print('✅ Post created successfully!\n');
    return postId;
  }

  Future<void> likePost(String postId, String uid, List likes) async {
    print('\n❤️ Processing like/unlike action...');
    if (likes.contains(uid)) {
      print('💔 Removing like...');
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([uid])
      });
      print('✅ Post unliked!\n');
    } else {
      print('💖 Adding like...');
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([uid])
      });
      print('✅ Post liked!\n');
    }
  }

  Future<void> postComment(
    String postId,
    String text,
    String uid,
    String username,
    String profilePic,
  ) async {
    print('\n💭 Adding new comment...');
    String commentId = const Uuid().v1();
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .set({
      'commentId': commentId,
      'postId': postId,
      'text': text,
      'uid': uid,
      'username': username,
      'profilePic': profilePic,
      'datePublished': DateTime.now(),
    });
    print('✅ Comment added successfully!\n');
  }

  Future<void> deletePost(String postId) async {
    print('\n🗑️ Deleting post...');
    await _firestore.collection('posts').doc(postId).delete();
    print('✅ Post deleted successfully!\n');
  }

  Stream<QuerySnapshot> getPostsStream() {
    print('\n📱 Loading posts feed...');
    return _firestore
        .collection('posts')
        .orderBy('datePublished', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserPosts(String uid) {
    print('\n👤 Loading user posts...');
    return _firestore
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .orderBy('datePublished', descending: true)
        .snapshots();
  }

  Future<void> sendMessage(String messageContent, String senderId, String recipientId) async {
    print('\n✉️ Sending message...');
    String messageId = const Uuid().v1();
    await _firestore.collection('messages').doc(messageId).set({
      'messageId': messageId,
      'content': messageContent,
      'senderId': senderId,
      'recipientId': recipientId,
      'timestamp': DateTime.now(),
    });
    print('✅ Message sent successfully!\n');
  }
}
