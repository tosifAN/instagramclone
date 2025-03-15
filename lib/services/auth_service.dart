import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:instagram/models/user.dart' as model;
import 'package:instagram/services/storage_service.dart';
import 'package:instagram/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  String? _verificationId;
  int? _resendToken;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required String bio,
    File? profileImage,
  }) async {
    try {
      print('\n📱 Starting user registration process...');
      print('👤 Creating new account for: $email');
      
      // Create user with email and password
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Account created successfully!');

      String photoUrl = 'https://pixabay.com/vectors/blank-profile-picture-mystery-man-973460/';
      
      if (profileImage != null) {
        print('🖼️ Uploading profile picture...');
        // Upload profile image if provided
        photoUrl = await _storageService.uploadImageToStorage(
          'profilePics',
          profileImage,
        );
        print('✅ Profile picture uploaded successfully!');
      }

      print('📝 Setting up user profile...');
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
      print('✅ User profile created successfully!');
      print('🎉 Registration complete! You can now log in.\n');

      return cred;
    } catch (e) {
      print('❌ Error during registration: ${e.toString()}');
      throw e.toString();
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      print('\n🔐 Attempting to sign in...');
      print('👤 Checking credentials for: $email');
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Login successful!');
      print('🎉 Welcome back!\n');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ Login failed: ${e.message}');
      throw e.message ?? 'An error occurred during sign in';
    }
  }

  // Sign out
  Future<void> signOut() async {
    print('\n👋 Signing out...');
    await _auth.signOut();
    print('✅ You have been signed out successfully!\n');
  }

  // Phone number verification
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    try {
      print('\n📱 Starting phone verification for: $phoneNumber');
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ Auto-verification completed');
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ Phone verification failed: ${e.message}');
          throw e.message ?? 'Phone verification failed';
        },
        codeSent: (String verificationId, int? resendToken) {
          print('📤 Verification code sent');
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      print('❌ Error during phone verification: ${e.toString()}');
      throw e.toString();
    }
  }

  // Verify OTP
  Future<UserCredential> verifyOTP(String smsCode) async {
    try {
      print('\n🔐 Verifying OTP...');
      if (_verificationId == null) throw 'No verification ID found';

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      print('✅ Phone number verified successfully!');
      return userCredential;
    } catch (e) {
      print('❌ OTP verification failed: ${e.toString()}');
      throw e.toString();
    }
  }

  // Link phone number with existing account
  Future<void> linkPhoneNumber(String smsCode) async {
    try {
      print('\n🔗 Linking phone number to account...');
      if (_verificationId == null) throw 'No verification ID found';

      PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await _auth.currentUser?.linkWithCredential(phoneCredential);
      print('✅ Phone number linked successfully!');
    } catch (e) {
      print('❌ Failed to link phone number: ${e.toString()}');
      throw e.toString();
    }
  }

  // Get current user
  User? getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      print('👤 Current user: ${user.email}');
    } else {
      print('ℹ️ No user currently logged in');
    }
    return user;
  }

  // Update user profile
  Future<void> updateProfile({
    String? username,
    String? bio,
    File? profileImage,
  }) async {
    try {
      print('\n✏️ Starting profile update...');
      User? currentUser = getCurrentUser();
      if (currentUser == null) throw 'No user logged in';

      if (profileImage != null) {
        print('🖼️ Uploading new profile picture...');
        String photoUrl = await _storageService.uploadImageToStorage(
          'profilePics',
          profileImage,
        );
        await currentUser.updatePhotoURL(photoUrl);
        print('✅ Profile picture updated successfully!');
      }

      if (username != null || bio != null) {
        print('📝 Updating profile information...');
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
        print('✅ Profile information updated successfully!');
      }
      print('🎉 Profile update complete!\n');
    } catch (e) {
      print('❌ Error updating profile: ${e.toString()}');
      throw e.toString();
    }
  }
}
