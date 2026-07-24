import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Stream of Auth State changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase User
  User? get currentUser => _auth.currentUser;

  // Sign Register: Create user in Auth & save profile to Firestore
  Future<UserModel> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    User? user;
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'USER_NULL',
          message: 'User creation failed.',
        );
      }

      // Update Firebase Auth Display Name
      await user.updateDisplayName(name.trim());

      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      // Save user to Firestore "users" collection
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (_) {
      if (user != null) {
        try {
          await user.delete();
        } catch (_) {
          await _auth.signOut();
        }
      }
      rethrow;
    } catch (e) {
      if (user != null) {
        try {
          await user.delete();
        } catch (_) {
          await _auth.signOut();
        }
      }
      throw Exception('Failed to register user: ${e.toString()}');
    }
  }

  // Sign Login: Sign in with email and password
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to log in: ${e.toString()}');
    }
  }

  // Get User Profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to load user profile: ${e.toString()}');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
