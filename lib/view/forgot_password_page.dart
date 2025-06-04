import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:provider/provider.dart';
import '../view_models/forgot_password_vm.dart';

class ForgotPasswordPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ForgotPasswordViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Forgot Password'),
          backgroundColor: Color(0xFF870C14),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Consumer<ForgotPasswordViewModel>(
              builder: (context, viewModel, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40),
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF870C14),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Enter your email address and we will send you a link to reset your password.',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 30),
                    TextFormField(
                      controller: viewModel.emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 20),
                    if (viewModel.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          viewModel.errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    if (viewModel.successMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          viewModel.successMessage!,
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () => viewModel.sendResetLink(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF870C14),
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: viewModel.isLoading
                            ? CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Send Reset Link',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Color(0xFF870C14),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
=======
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _message = 'Please enter your email address';
        _isSuccess = false;
      });
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      setState(() {
        _isLoading = false;
        _message = 'Password reset email sent. Please check your inbox';
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        String errorMessage = 'An error occurred';

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              errorMessage = 'No user found with this email';
              break;
            case 'invalid-email':
              errorMessage = 'Invalid email format';
              break;
            default:
              errorMessage = e.message ?? 'Failed to send reset email';
          }
        }

        _message = errorMessage;
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(209, 224, 166, 1),
      appBar: AppBar(
        title: Text('Forgot Password'),
        backgroundColor: Color.fromARGB(255, 255, 147, 39),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
          Container(color: Color.fromARGB(6, 116, 116, 116)),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Password Recovery',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Enter your email address and we will send you a password reset link',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 30),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(175, 255, 255, 255),
                        border: UnderlineInputBorder(),
                        labelText: 'Email Address',
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(86, 0, 0, 0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _message,
                          style: TextStyle(
                            color: _isSuccess ? Colors.green : Colors.white,
                            fontWeight: _isSuccess
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  SizedBox(height: 30),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 147, 39),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0)),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Send Reset Link',
                              style: TextStyle(
                                  fontFamily: 'Norwester',
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500)),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 255, 235, 153),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
>>>>>>> origin/main
