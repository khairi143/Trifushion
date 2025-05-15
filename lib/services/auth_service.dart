import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      log("Something went wrong");
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      log("Something went wrong");
    }
    return null;
  }

  // Function to clear login information when signing out
  static Function clearLoginInfo = () {};

  Future<void> signout() async {
    try {
      await _auth.signOut();
      // Call the clear login info function
      clearLoginInfo();
    } catch (e) {
      log("Something went wrong during signout");
    }
  }

  getUserID() {
    return _auth.currentUser?.uid;
  }

  updateEmail(email) async {
    await _auth.currentUser?.updateEmail(email);
  }

  // Method to update user password
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      // Get current user
      User? user = _auth.currentUser;
      if (user == null) throw Exception("No authenticated user found");

      // Get user email
      String? email = user.email;
      if (email == null) throw Exception("User has no email");

      // Re-authenticate user with current password
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      log("Error updating password: $e");
      throw e;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      log("Error sending password reset email: $e");
      // Re-throw the error to handle it in the UI
      throw FirebaseAuthException(
        code: e is FirebaseAuthException ? e.code : 'unknown_error',
        message: e.toString(),
      );
    }
  }

  listenForTokenChanges() async {
    // Listen to changes in authentication state
    FirebaseAuth.instance.userChanges().listen((User? user) async {
      if (user != null) {
        // Force refresh the token to get the latest ID token
        try {
          String? idToken = await user.getIdToken(true);

          print("New ID token: $idToken");

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
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

  // Check if current user is an admin
  Future<bool> isCurrentUserAdmin() async {
    String? uid = getUserID();
    if (uid == null) return false;

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['usertype'] == 'admin';
      }
    } catch (e) {
      log("Error checking admin status: $e");
    }
    return false;
  }

  // Ban a user
  Future<bool> banUser(String uid, String reason) async {
    // First check if the current user is an admin
    if (!await isCurrentUserAdmin()) {
      log("Only admins can ban users");
      return false;
    }

    try {
      // Update user document to set isBanned to true
      await _firestore.collection('users').doc(uid).update({
        'isBanned': true,
      });

      // Log admin action
      await _firestore.collection('adminActions').add({
        'action': 'ban',
        'targetUserId': uid,
        'adminId': getUserID(),
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      log("Error banning user: $e");
      return false;
    }
  }

  // Unban a user
  Future<bool> unbanUser(String uid, String reason) async {
    // First check if the current user is an admin
    if (!await isCurrentUserAdmin()) {
      log("Only admins can unban users");
      return false;
    }

    try {
      // Update user document to set isBanned to false
      await _firestore.collection('users').doc(uid).update({
        'isBanned': false,
      });

      // Log admin action
      await _firestore.collection('adminActions').add({
        'action': 'unban',
        'targetUserId': uid,
        'adminId': getUserID(),
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      log("Error unbanning user: $e");
      return false;
    }
  }

  // Check if a user is banned
  Future<bool> isUserBanned(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc['isBanned'] == true;
      }
    } catch (e) {
      log("Error checking ban status: $e");
    }
    return false;
  }

  // Get the reason why a user was banned
  Future<String?> getBanReason(String uid) async {
    try {
      // Query the most recent ban record
      QuerySnapshot actions = await _firestore
          .collection('adminActions')
          .where('targetUserId', isEqualTo: uid)
          .where('action', isEqualTo: 'ban')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (actions.docs.isNotEmpty) {
        return actions.docs.first['reason'];
      }
    } catch (e) {
      log("Error getting ban reason: $e");
    }
    return null;
  }

  // Delete a user
  Future<bool> deleteUser(String uid) async {
    // First check if the current user is an admin
    if (!await isCurrentUserAdmin()) {
      log("Only admins can delete users");
      return false;
    }

    try {
      // Log admin action first
      await _firestore.collection('adminActions').add({
        'action': 'delete',
        'targetUserId': uid,
        'adminId': getUserID(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Note: This doesn't delete the Firebase Auth user account
      // For a complete deletion, you'd need Firebase Admin SDK or Cloud Functions

      return true;
    } catch (e) {
      log("Error deleting user: $e");
      return false;
    }
  }
}
