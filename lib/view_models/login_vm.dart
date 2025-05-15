import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _mounted = true;

  // Controllers and state
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final errorMessageController = TextEditingController();
  bool isLoading = false;

  // These are callbacks to be set by the View
  VoidCallback? onAdmin;
  VoidCallback? onUser;
  void Function(String reason)? onBanned;

  bool get mounted => _mounted;

  @override
  void dispose() {
    _mounted = false;
    emailController.dispose();
    passwordController.dispose();
    errorMessageController.dispose();
    super.dispose();
  }

  void setEmail(String value) {
    emailController.text = value;
    notifyListeners();
  }

  void setPassword(String value) {
    passwordController.text = value;
    notifyListeners();
  }

  Future<void> login(BuildContext context, VoidCallback? onAdmin,
      VoidCallback? onUser, Function(String) onBanned) async {
    if (!mounted) return; // Check if the view model is still mounted

    isLoading = true;
    String? email = emailController.text;
    String? password = passwordController.text;
    String? errorMessage = errorMessageController.text;
    notifyListeners();

    try {
      final user =
          await _authService.loginUserWithEmailAndPassword(email!, password!);
      if (!mounted) return; // Check if the view model is still mounted

      if (user != null) {
        // User logged in successfully
        String userId = user.uid;

        // Check if the user is banned
        bool isBanned = await _authService.isUserBanned(userId);
        if (!mounted) return; // Check if the view model is still mounted

        if (isBanned) {
          String reason = await _authService.getBanReason(userId).toString();
          onBanned.call(reason);
          return;
        }

        // Fetch user data and determine user type
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (!mounted) return; // Check if the view model is still mounted

        final userType = userDoc['usertype'];

        if (userType == 'admin') {
          onAdmin?.call();
        } else if (userType == 'user') {
          onUser?.call();
        }
      } else {
        errorMessageController.text =
            "Login failed. Please check your credentials.";
      }
    } catch (e) {
      if (!mounted) return; // Check if the view model is still mounted
      errorMessageController.text = "An error occurred: $e";
    } finally {
      if (mounted) {
        // Only update state if still mounted
        isLoading = false;
        notifyListeners();
      }
    }
  }

  static void resetLoginInfo() {
    // Reset the login-related info (like clearing controllers, error messages, etc.)
    // emailController.clear();
    // passwordController.clear();
    // errorMessageController.clear();
  }
}
