import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  bool get isAuthenticated => user != null;

  AuthProvider() {
    user = _auth.currentUser;
    _auth.authStateChanges().listen((u) {
      user = u;
      notifyListeners();
    });
  }

  Future<void> signup(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    user = cred.user;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    user = cred.user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    user = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    user = _auth.currentUser;
    return;
  }

  String get uid => user?.uid ?? 'anonymous';
}
