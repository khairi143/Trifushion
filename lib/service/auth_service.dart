import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final _auth = FirebaseAuth.instance;

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } catch(e) {
      log("Something went wrong");
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    } catch(e) {
      log("Something went wrong");
    }
    return null;
  }

  Future<void> signout() async {
    try{
      await _auth.signOut();
    } catch(e) {
      log("Something went wrong");
    }
  }

  getUserID() {
    return _auth.currentUser?.uid;
  }

  updateEmail(email) async {
    await _auth.currentUser?.updateEmail(email);
  }


  listenForTokenChanges() async {
    // Listen to changes in authentication state
    FirebaseAuth.instance.userChanges().listen((User? user) async {
      if (user != null) {
        // Force refresh the token to get the latest ID token
        try {
          String? idToken = await user.getIdToken(true);

          print("New ID token: $idToken");

          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'email': user.email,
          });

          // You can now use this token to authenticate API requests or for other purposes
        } catch (e) {
          print("Error refreshing token: $e");
        }
      } else {
        print("User is signed out");
      }
    });
  }
}