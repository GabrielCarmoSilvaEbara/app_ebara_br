import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum AuthStatus { initial, authenticated, guest, unauthenticated }

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final Box _settingsBox = Hive.box('settings');

  User? _user;
  AuthStatus _status = AuthStatus.initial;

  User? get user => _user;
  AuthStatus get status => _status;

  String? get photoUrl => _user?.photoURL;

  AuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    _user = _auth.currentUser;

    if (_user != null) {
      _status = AuthStatus.authenticated;
    } else {
      final isGuest = _settingsBox.get('is_guest', defaultValue: false);
      if (isGuest) {
        _status = AuthStatus.guest;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        GoogleSignInAccount? googleUser;

        try {
          googleUser = await _googleSignIn.authenticate();
        } catch (error) {
          if (error.toString().contains('init') ||
              error.toString().contains('Bad state')) {
            await _googleSignIn.initialize();
            googleUser = await _googleSignIn.authenticate();
          } else {
            return;
          }
        }

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: null,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      _user = userCredential.user;
      await _settingsBox.put('is_guest', false);
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> continueAsGuest() async {
    await _settingsBox.put('is_guest', true);
    _status = AuthStatus.guest;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();

    await _settingsBox.put('is_guest', false);
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
