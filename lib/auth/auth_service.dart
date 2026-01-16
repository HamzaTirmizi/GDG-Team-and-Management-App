// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // -------------------- Email Signup --------------------
  Future<User?> signUpWithEmail({
    required String name,
    required String studentId,
    required String email,
    required String password,
  }) async {
    // Check if email already exists in Firestore

    // Create Firebase Auth user
    final UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // Save user data in Firestore
    await _firestoreService.saveUserData(
      uid: uid,
      name: name,
      studentId: studentId,
      email: email,
      password: password,
      role: 'member',
    );

    return cred.user;
  }

  // -------------------- Email Login --------------------
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw FirebaseAuthException(
          code: 'NO_ACCOUNT',
          message: 'No account exists with this email.',
        );
      } else if (e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'WRONG_PASSWORD',
          message: 'Password is incorrect.',
        );
      } else {
        rethrow;
      }
    }
  }

  // -------------------- Google Sign-In Step 1 --------------------
  Future<User?> startGoogleSignIn() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCred = await _auth.signInWithCredential(credential);
    final User user = userCred.user!;

    // Check Firestore for existing user
    final doc = await _firestoreService.getUserDoc(user.uid);

    if (doc.exists) {
      // Existing user → direct login
      return user;
    }

    // New Google user → Firestore doc not created yet
    return user;
  }

  // -------------------- Google Sign-In Step 2 --------------------
  // Call after collecting studentId for first-time Google users
  Future<User?> completeGoogleSignIn({required String studentId}) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'NO_AUTH_USER',
        message: 'No signed-in user found.',
      );
    }

    final doc = await _firestoreService.getUserDoc(user.uid);
    if (doc.exists) {
      // Already exists → nothing to do
      return user;
    }

    // Save Firestore doc for first-time Google user
    await _firestoreService.saveUserData(
      uid: user.uid,
      name: user.displayName ?? '',
      studentId: studentId,
      email: user.email ?? '',
      password: 'google', // placeholder
      role: 'member',     // default
    );

    return user;
  }

  // -------------------- Update editable fields --------------------
  Future<void> updateEditableFields({
    required String uid,
    String? semester,
    String? photoUrl,
    String? chapterId,
    String? teamId,
    String? role,
  }) async {
    await _firestoreService.updateUserData(
      uid: uid,
      semester: semester,
      photoUrl: photoUrl,
      chapterId: chapterId,
      teamId: teamId,
      role: role,
    );
  }

  // -------------------- Get user doc --------------------
  Future<DocumentSnapshot> getUserDoc(String uid) async {
    return await _firestoreService.getUserDoc(uid);
  }

  Stream<DocumentSnapshot> streamUserDoc(String uid) {
    return _firestoreService.streamUserDoc(uid);
  }

  // -------------------- Sign Out --------------------
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    // Placeholder for future Microsoft/Outlook Sign-Out
  }

  // -------------------- Placeholder: Microsoft/Outlook Sign-In --------------------
  Future<User?> startMicrosoftSignIn() async {
    // Leave space for future implementation
    return null;
  }
}
