import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  User? _firebaseUser;
  UserModel? _userProfile;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userProfile => _userProfile;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;
  String get displayName => _userProfile?.name ?? _firebaseUser?.displayName ?? 'Student';

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _status = AuthStatus.loading;
      notifyListeners();
      await _fetchUserProfile(user.uid);
      _status = AuthStatus.authenticated;
    } else {
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      _userProfile = await _firestoreService.getUserProfile(uid);
    } catch (_) {
      // profile fetch failure is non-fatal
    }
  }

  // ─── Sign Up ──────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name);

      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email.trim(),
        joinedAt: DateTime.now(),
      );
      await _firestoreService.createUser(userModel);
      _userProfile = userModel;
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authErrorMessage(e.code));
      return false;
    } catch (_) {
      _setError('Sign up failed. Please try again.');
      return false;
    }
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authErrorMessage(e.code));
      return false;
    } catch (_) {
      _setError('Login failed. Please try again.');
      return false;
    }
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  Future<bool> googleSignIn() async {
    _setLoading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Create Firestore profile if first sign-in
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final userModel = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Student',
          email: user.email ?? '',
          avatarUrl: user.photoURL ?? '',
          joinedAt: DateTime.now(),
        );
        await _firestoreService.createUser(userModel);
      }
      _clearError();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authErrorMessage(e.code));
      return false;
    } catch (_) {
      _setError('Google Sign-In failed. Please try again.');
      return false;
    }
  }

  // ─── Forgot Password ──────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    _setLoading();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_authErrorMessage(e.code));
      return false;
    } catch (_) {
      _setError('Could not send reset email. Try again.');
      return false;
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _errorMessage = null;
    if (_firebaseUser != null) {
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
