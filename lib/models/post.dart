import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String uid;
  final String username;
  final String description;
  final String postUrl;
  final String profImage;
  final DateTime datePublished;
  final List<String> likes;

  Post({
    required this.postId,
    required this.uid,
    required this.username,
    required this.description,
    required this.postUrl,
    required this.profImage,
    required this.datePublished,
    required this.likes,
  });

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'uid': uid,
        'username': username,
        'description': description,
        'postUrl': postUrl,
        'profImage': profImage,
        'datePublished': datePublished,
        'likes': likes,
      };

  static Post fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return Post(
      postId: snapshot['postId'] ?? '',
      uid: snapshot['uid'] ?? '',
      username: snapshot['username'] ?? '',
      description: snapshot['description'] ?? '',
      postUrl: snapshot['postUrl'] ?? '',
      profImage: snapshot['profImage'] ?? '',
      datePublished: (snapshot['datePublished'] as Timestamp).toDate(),
      likes: List<String>.from(snapshot['likes'] ?? []),
    );
  }
}
