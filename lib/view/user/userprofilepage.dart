import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _weightController = TextEditingController();
  TextEditingController _heightController = TextEditingController();
  TextEditingController _contactController = TextEditingController();
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String? _gender;
  String? userID;

  @override
  void initState() {
    super.initState();
    userID = _auth.getUserID();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;

        // Populate the text controllers with fetched data
        _fullNameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _weightController.text = data['weight'] ?? '';
        _heightController.text = data['height'] ?? '';
        _contactController.text = data['contactno'] ?? '';
        _gender = data['gender'] ?? 'Male';
      } else {
        print("User data not found!");
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String email = _emailController.text;
          bool updateEmail = false;

          // Re-authenticate the user before updating the email
          String currentPassword =
              _passwordController.text; // Get current password from the user
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );

          if (email != user.email) {
            await user.reauthenticateWithCredential(credential);
            await user.verifyBeforeUpdateEmail(email);
            updateEmail = true;
          }

          // Update Firestore with new profile data
          await FirebaseFirestore.instance.collection('users').doc(userID).set({
            'email': user.email,
            'weight': _weightController.text,
            'height': _heightController.text,
            'gender': _gender,
            'contactno': _contactController.text,
            'name': _fullNameController.text,
            'userID': userID,
            'usertype': 'user',
          });

          if (mounted) {
            if (updateEmail) {
              _showDialog(
                  'Your profile has been successfully updated! Please check your new email inbox to verify and confirm the email change.',
                  isSuccess: true);
            } else {
              _showDialog('Profile updated successfully!', isSuccess: true);
            }
          }
        }
      } catch (e) {
        if (mounted) {
          _showDialog('Failed to update profile: $e', isSuccess: false);
        }
      }
    }
  }

  void _showDialog(String message, {required bool isSuccess}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isSuccess ? 'Success' : 'Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Form for user details
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      //Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Full Name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Email',
                        ),
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
                      const SizedBox(height: 10),

                      // Height
                      TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Height (cm)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Height is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      // Weight
                      TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Weight (kg)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Weight is required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

                      // Gender
                      DropdownButtonFormField<String>(
                        value: _gender,
                        onChanged: (String? newValue) {
                          setState(() {
                            _gender = newValue;
                          });
                        },
                        items: <String>['Male', 'Female', 'Other']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Gender',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Gender is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Contact Number
                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Contact No.',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Contact number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Password',
                        ),
                        obscureText:
                            true, // This hides the password as asterisks
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
                      const SizedBox(height: 20),

                      // Submit Button
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF870C14),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            textStyle: const TextStyle(fontSize: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Update Profile",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
