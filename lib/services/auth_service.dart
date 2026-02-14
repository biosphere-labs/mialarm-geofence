import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Handles all Firebase Auth operations.
///
/// This is a thin wrapper around FirebaseAuth. In a real app you might
/// add error mapping (FirebaseAuthException → user-friendly messages),
/// but for this demo we let exceptions bubble up to the UI layer.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of auth state changes. Emits null when signed out,
  /// a User when signed in. Used by authStateProvider in Riverpod.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user (null if not signed in).
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Register a new user and create their Firestore profile.
  Future<UserCredential> register(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user document in Firestore
    await _db.collection(Collections.users).doc(credential.user!.uid).set({
      'email': email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update the Firebase Auth display name
    await credential.user!.updateDisplayName(displayName);

    return credential;
  }

  /// Sign out.
  Future<void> signOut() => _auth.signOut();

  /// Send password reset email.
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }
}
