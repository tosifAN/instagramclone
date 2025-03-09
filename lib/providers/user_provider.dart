import 'package:flutter/material.dart';
import 'package:instagram/models/user.dart' as model;
import 'package:instagram/services/firestore_service.dart';
import 'package:instagram/services/auth_service.dart';

class UserProvider with ChangeNotifier {
  model.User? _user;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  model.User? get getUser => _user;

  Future<void> refreshUser() async {
    try {
      var currentUser = _authService.getCurrentUser();
      if (currentUser != null) {
        model.User user = await _firestoreService.getUser(currentUser.uid);
        _user = user;
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }
}
