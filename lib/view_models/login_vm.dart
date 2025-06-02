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

    // Clear previous error messages
    errorMessageController.clear();
    
    // Validate input
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      errorMessageController.text = "Please enter both email and password";
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      // Step 1: Authenticate user with Firebase
      final user = await _authService.loginUserWithEmailAndPassword(email, password);
      if (!mounted) return;

      if (user == null) {
        throw Exception("Authentication failed. Please check your credentials.");
      }

      String userId = user.uid;
      
      // Step 2: Verify user exists in Firestore and get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!mounted) return;

      if (!userDoc.exists) {
        // Sign out the user if no data found
        await _authService.signout();
        throw Exception("User account not found. Please contact support.");
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Step 3: Strict user type validation
      final userType = userData['usertype']?.toString().toLowerCase().trim();
      
      if (userType == null || userType.isEmpty) {
        await _authService.signout();
        throw Exception("Account type not defined. Please contact support.");
      }

      // Step 4: Check if user is banned (with multiple field names for compatibility)
      bool isBanned = userData['isBanned'] == true || 
                     userData['banned'] == true || 
                     userData['is_banned'] == true;
      
      if (isBanned) {
        await _authService.signout();
        String? banReason = await _authService.getBanReason(userId);
        onBanned.call(banReason ?? "Account has been suspended. Contact support for details.");
        return;
      }

      // Step 5: Strict role-based access control
      switch (userType) {
        case 'admin':
          // Additional admin verification
          if (await _verifyAdminAccess(userId, userData)) {
            onAdmin?.call();
          } else {
            await _authService.signout();
            throw Exception("Admin access denied. Invalid permissions.");
          }
          break;
          
        case 'user':
          // Additional user verification
          if (await _verifyUserAccess(userId, userData)) {
            onUser?.call();
          } else {
            await _authService.signout();
            throw Exception("User access denied. Account may be suspended.");
          }
          break;
          
        default:
          await _authService.signout();
          throw Exception("Invalid account type: '$userType'. Please contact support.");
      }

    } catch (e) {
      if (!mounted) return;
      
      // Enhanced error handling
      String errorMessage = e.toString();
      
      // Clean up error message
      if (errorMessage.contains('Exception:')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      if (errorMessage.contains('[firebase_auth/')) {
        if (errorMessage.contains('user-not-found')) {
          errorMessage = "No account found with this email address.";
        } else if (errorMessage.contains('wrong-password')) {
          errorMessage = "Incorrect password. Please try again.";
        } else if (errorMessage.contains('invalid-email')) {
          errorMessage = "Invalid email address format.";
        } else if (errorMessage.contains('user-disabled')) {
          errorMessage = "This account has been disabled.";
        } else if (errorMessage.contains('too-many-requests')) {
          errorMessage = "Too many failed attempts. Please try again later.";
        } else {
          errorMessage = "Login failed. Please check your credentials.";
        }
      }
      
      errorMessageController.text = errorMessage;
      print("Login error: $e"); // For debugging
      
    } finally {
      if (mounted) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // Verify admin access with additional security checks
  Future<bool> _verifyAdminAccess(String userId, Map<String, dynamic> userData) async {
    try {
      // Check if user has admin privileges
      if (userData['usertype'] != 'admin') {
        return false;
      }
      
      // Additional admin verification (you can add more checks here)
      // For example: check admin creation date, admin permissions, etc.
      String? email = userData['email']?.toString();
      if (email == null || email.isEmpty) {
        return false;
      }
      
      // Log admin login for security auditing
      await _logAdminAccess(userId, email);
      
      return true;
    } catch (e) {
      print("Admin verification error: $e");
      return false;
    }
  }

  // Verify user access with additional security checks
  Future<bool> _verifyUserAccess(String userId, Map<String, dynamic> userData) async {
    try {
      // Check if user has valid user account
      if (userData['usertype'] != 'user') {
        return false;
      }
      
      // Additional user verification
      String? email = userData['email']?.toString();
      if (email == null || email.isEmpty) {
        return false;
      }
      
      // Check account status
      bool isActive = userData['isActive'] != false; // Default to true if not specified
      if (!isActive) {
        return false;
      }
      
      return true;
    } catch (e) {
      print("User verification error: $e");
      return false;
    }
  }

  // Log admin access for security auditing
  Future<void> _logAdminAccess(String userId, String email) async {
    try {
      await _firestore.collection('adminActions').add({
        'actionType': 'ADMIN_LOGIN',
        'userId': userId,
        'email': email,
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'loginTime': DateTime.now().toIso8601String(),
          'action': 'Admin successfully logged in',
        }
      });
    } catch (e) {
      print("Error logging admin access: $e");
      // Don't throw error here as it's just for logging
    }
  }

  static void resetLoginInfo() {
    // Reset the login-related info (like clearing controllers, error messages, etc.)
    // emailController.clear();
    // passwordController.clear();
    // errorMessageController.clear();
  }
}
