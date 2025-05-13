import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'adminHomePage.dart';

import '../../services/auth_service.dart';

class AdminSignUpPage extends StatefulWidget {
  @override
  _AdminSignUpState createState() => _AdminSignUpState();
}

class _AdminSignUpState extends State<AdminSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _contactno = TextEditingController();
  final _confirmpassword = TextEditingController();

  bool _isChecked = false;
  String? userID;

  @override
  void dispose() {
    super.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _contactno.dispose();
    _confirmpassword.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Signup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Text(
                    "Admin Details",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Divider(
                    color: Color(0xFF870C14),
                    thickness: 2,
                  ),
                  SizedBox(height: 15),

                  //Name
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: 'Admin Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Admin name is required';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _email,
                    decoration: InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // Contact Number
                  TextFormField(
                    controller: _contactno,
                    decoration: InputDecoration(labelText: 'Contact Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Contact number is required';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmpassword,
                    obscureText: true,
                    decoration: InputDecoration(labelText: 'Confirm Password'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _password.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 20),

                  // Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            _isChecked = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          "I have read and agreed to abide by the rules & regulations",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Sign Up Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF870C14),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text("Sign Up",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_isChecked) {
        try {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF870C14),
                ),
              );
            },
          );

          final user = await _auth.createUserWithEmailAndPassword(
              _email.text.trim(), _password.text);

          // Hide loading indicator
          Navigator.of(context).pop();

          if (user != null) {
            userID = user.uid;
            log("User created successfully");
            await uploadUserToDb();
            goToHome(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to create account. Please try again.'),
                backgroundColor: Color(0xFF870C14),
              ),
            );
          }
        } catch (e) {
          // Hide loading indicator if it's showing
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }

          String errorMessage = 'An error occurred during signup.';
          if (e.toString().contains('email-already-in-use')) {
            errorMessage = 'This email is already registered.';
          } else if (e.toString().contains('invalid-email')) {
            errorMessage = 'Please enter a valid email address.';
          } else if (e.toString().contains('weak-password')) {
            errorMessage = 'Password is too weak. Please use a stronger password.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Color(0xFF870C14),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the Terms and Conditions to sign up.'),
            backgroundColor: Color(0xFF870C14),
          ),
        );
      }
    }
  }

  Future<void> uploadUserToDb() async {
    try {
      await FirebaseFirestore.instance.collection("users").doc(userID).set({
        "email": _email.text.trim(),
        "contactno": _contactno.text.trim(),
        "fullname": _name.text.trim(),
        "userID": userID,
        "usertype": "admin",
        "isBanned": false,
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log("Error uploading user data: $e");
      throw e;
    }
  }

  void goToHome(BuildContext context) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Admin account created successfully! Redirecting to admin dashboard...'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate to AdminHomePage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminHomePage()),
    );
  }
}
