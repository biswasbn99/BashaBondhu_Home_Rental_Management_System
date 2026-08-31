import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign Up
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String mobile,
    required String city,
    required String userType,
  }) async {
    try {
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // 2. Save additional details in Firestore
        UserModel userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          mobile: mobile,
          city: city,
          userType: userType,
        );

        await _firestore.collection('users').doc(userModel.uid).set(userModel.toMap());
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('SignUp Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      debugPrint('Firestore Error: ${e.code} - ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('General SignUp Error: $e');
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign In
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('SignIn Auth Error: ${e.code} - ${e.message}');
      // Customizing message for clarity
      if (e.code == 'invalid-credential') {
        throw Exception('ইমেইল অথবা পাসওয়ার্ড ভুল। দয়া করে আবার চেষ্টা করুন।');
      }
      rethrow;
    } catch (e) {
      debugPrint('General SignIn Error: $e');
      rethrow;
    }
  }

  // Fetch User Role/Type
  Future<String?> getUserType(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['userType'];
      }
      return null;
    } catch (e) {
      debugPrint('GetUserType Error: $e');
      return null;
    }
  }

  // Send Password Reset Email (100% Free via Firebase Auth)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('✅ Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset auth error: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        throw Exception('এই ইমেইল দিয়ে কোনো অ্যাকাউন্ট পাওয়া যায়নি।');
      } else if (e.code == 'invalid-email') {
        throw Exception('অনুগ্রহ করে একটি সঠিক ইমেইল ঠিকানা দিন।');
      }
      rethrow;
    } catch (e) {
      debugPrint('Password reset general error: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
