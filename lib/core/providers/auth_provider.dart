import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/analytics_service.dart';
import '../constants/app_constants.dart';

enum AuthStatus { initial, authenticated, guest, unauthenticated }

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final Box _settingsBox = Hive.box(StorageKeys.boxSettings);

  User? _user;
  AuthStatus _status = AuthStatus.initial;

  User? get user => _user;
  AuthStatus get status => _status;

  String? get photoUrl => _user?.photoURL;

  AuthProvider();

  Future<void> init() async {
    await Future.delayed(Duration.zero);

    if (!kIsWeb) {
      try {
        await _googleSignIn.initialize();
      } catch (_) {}
    }

    await _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    _user = _auth.currentUser;

    if (_user != null) {
      _status = AuthStatus.authenticated;
    } else {
      final isGuest = _settingsBox.get(
        StorageKeys.keyIsGuest,
        defaultValue: false,
      );
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
        final GoogleSignInAccount googleUser = await _googleSignIn
            .authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      _user = userCredential.user;
      await _settingsBox.put(StorageKeys.keyIsGuest, false);
      _status = AuthStatus.authenticated;

      await AnalyticsService.logLogin('google');

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> continueAsGuest() async {
    await _settingsBox.put(StorageKeys.keyIsGuest, true);
    _status = AuthStatus.guest;

    await AnalyticsService.logLogin('guest');

    notifyListeners();
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    await _auth.signOut();

    await _settingsBox.put(StorageKeys.keyIsGuest, false);
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
