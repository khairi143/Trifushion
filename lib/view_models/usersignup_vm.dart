import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class UserSignUpViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final formKey = GlobalKey<FormState>();

  // Controllers
  final fullname = TextEditingController();
  final email = TextEditingController();
  final contactNo = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();
  String? gender;
  bool isChecked = false;
  bool isLoading = false;

  Future<String?> signUp(BuildContext context) async {
    if (!formKey.currentState!.validate()) return null;
    if (!isChecked) return 'You must accept the terms.';

    isLoading = true;
    notifyListeners();

    // Check if the email is already in use
    final nameQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: fullname.text.trim())
        .get();

    if (nameQuery.docs.isNotEmpty) {
      return 'This name is already taken. Please choose another one.';
    }

    // Check if the email is already in use
    final emailQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.text.trim())
        .get();

    if (emailQuery.docs.isNotEmpty) {
      return 'This email is already in use. Please choose another one.';
    }

    try {
      final user = await _authService.createUserWithEmailAndPassword(
        email.text.trim(),
        password.text.trim(),
      );

      if (user != null) {
        final newUser = UserModel(
          name: fullname.text.trim(),
          email: email.text.trim(),
          contactNo: contactNo.text.trim(),
          height: height.text.trim(),
          weight: weight.text.trim(),
          gender: gender!,
          userId: user.uid,
        );

        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set(newUser.toMap());

        return null; // Success
      } else {
        return 'User creation failed.';
      }
    } catch (e) {
      return e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void disposeControllers() {
    fullname.dispose();
    email.dispose();
    contactNo.dispose();
    password.dispose();
    confirmPassword.dispose();
    height.dispose();
    weight.dispose();
  }
}
