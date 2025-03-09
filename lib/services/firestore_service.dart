import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> createUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toJson());
  }

  Future<User> getUser(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    return User.fromSnap(doc);
  }

  Future<void> followUser(String uid, String followId) async {
    DocumentSnapshot snap = await _firestore.collection('users').doc(uid).get();
    List following = (snap.data()! as dynamic)['following'];

    if (following.contains(followId)) {
      await _firestore.collection('users').doc(followId).update({
        'followers': FieldValue.arrayRemove([uid])
      });

      await _firestore.collection('users').doc(uid).update({
        'following': FieldValue.arrayRemove([followId])
      });
    } else {
      await _firestore.collection('users').doc(followId).update({
        'followers': FieldValue.arrayUnion([uid])
      });

      await _firestore.collection('users').doc(uid).update({
        'following': FieldValue.arrayUnion([followId])
      });
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

    await _firestore.collection('posts').doc(postId).set(post.toJson());
    return postId;
  }

  Future<void> likePost(String postId, String uid, List likes) async {
    if (likes.contains(uid)) {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([uid])
      });
    } else {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([uid])
      });
    }
  }

  Future<void> postComment(
    String postId,
    String text,
    String uid,
    String username,
    String profilePic,
  ) async {
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
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  Stream<QuerySnapshot> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('datePublished', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserPosts(String uid) {
    return _firestore
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .orderBy('datePublished', descending: true)
        .snapshots();
  }
}
