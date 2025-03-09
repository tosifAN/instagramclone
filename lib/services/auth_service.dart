import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/models/user.dart' as model;
import 'package:instagram/services/storage_service.dart';
import 'package:instagram/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String bio,
    File? profileImage,
  }) async {
    try {
      // Create user with email and password
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String photoUrl = 'https://pixabay.com/vectors/blank-profile-picture-mystery-man-973460/';
      
      if (profileImage != null) {
        // Upload profile image if provided
        photoUrl = await _storageService.uploadImageToStorage(
          'profilePics',
          profileImage,
        );
      }

      // Create user model
      model.User user = model.User(
        uid: cred.user!.uid,
        username: username,
        email: email,
        photoUrl: photoUrl,
        bio: bio,
        followers: [],
        following: [],
      );

      // Save user data to Firestore
      await _firestoreService.createUser(user);

      return cred;
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An error occurred during sign in';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Update user profile
  Future<void> updateProfile({
    String? username,
    String? bio,
    File? profileImage,
  }) async {
    try {
      User? currentUser = getCurrentUser();
      if (currentUser == null) throw 'No user logged in';

      if (profileImage != null) {
        String photoUrl = await _storageService.uploadImageToStorage(
          'profilePics',
          profileImage,
        );
        await currentUser.updatePhotoURL(photoUrl);
      }

      if (username != null || bio != null) {
        model.User user = await _firestoreService.getUser(currentUser.uid);
        await _firestoreService.createUser(
          model.User(
            uid: user.uid,
            username: username ?? user.username,
            email: user.email,
            photoUrl: user.photoUrl,
            bio: bio ?? user.bio,
            followers: user.followers,
            following: user.following,
          ),
        );
      }
    } catch (e) {
      throw e.toString();
    }
  }
}
