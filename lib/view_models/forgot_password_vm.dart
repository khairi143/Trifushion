import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final emailController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      errorMessage = 'Please enter your email address';
      notifyListeners();
      return;
    }

    try {
      isLoading = true;
      errorMessage = null;
      successMessage = null;
      notifyListeners();

      await _authService.sendPasswordResetEmail(email);

      successMessage = 'Password reset link sent to $email';
      errorMessage = null;
    } on FirebaseAuthException catch (e) {
      errorMessage = _getErrorMessage(e.code);
      successMessage = null;
    } catch (e) {
      errorMessage = 'An unknown error occurred';
      successMessage = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'invalid-email':
        return 'Please enter a valid email address';
      default:
        return 'Failed to send reset link. Please try again.';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
