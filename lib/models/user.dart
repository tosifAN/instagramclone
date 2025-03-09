import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String username;
  final String photoUrl;
  final String bio;
  final List<String> followers;
  final List<String> following;

  User({
    required this.uid,
    required this.email,
    required this.username,
    required this.photoUrl,
    required this.bio,
    required this.followers,
    required this.following,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'username': username,
        'photoUrl': photoUrl,
        'bio': bio,
        'followers': followers,
        'following': following,
      };

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;
    return User(
      uid: snapshot['uid'] ?? '',
      email: snapshot['email'] ?? '',
      username: snapshot['username'] ?? '',
      photoUrl: snapshot['photoUrl'] ?? '',
      bio: snapshot['bio'] ?? '',
      followers: List<String>.from(snapshot['followers'] ?? []),
      following: List<String>.from(snapshot['following'] ?? []),
    );
  }
}
