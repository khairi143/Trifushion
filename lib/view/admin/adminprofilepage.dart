import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();

  // Controllers for editing user information
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State variables
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isChangingPassword = false;
  String? _userId;
  Map<String, dynamic>? _userData;
  String? _error;
  String? _selectedGender;
  List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _userId = _auth.getUserID();

      if (_userId != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();

        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>;

            // Initialize controllers with user data
            _nameController.text = _userData?['fullname'] ?? '';
            _contactController.text = _userData?['contactno'] ?? '';
            _selectedGender = _userData?['gender'] ?? 'Other';
          });
        } else {
          setState(() {
            _error = 'User profile not found';
          });
        }
      } else {
        setState(() {
          _error = 'User not authenticated';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading profile: $e';
      });
      print('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save updated user data to Firestore
  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_userId != null) {
        // Create updated data map
        Map<String, dynamic> updatedData = {
          'fullname': _nameController.text.trim(),
          'contactno': _contactController.text.trim(),
          'gender': _selectedGender,
        };

        // Update Firestore document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .update(updatedData);

        // Reload user data
        await _loadUserData();

        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error updating profile: $e';
      });
      print('Error updating profile: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Change password
  Future<void> _changePassword() async {
    // Validate password form
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call Firebase Auth to update password
      await _auth.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _isChangingPassword = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error changing password: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error changing password: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildProfileView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'An unknown error occurred',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserData,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // User Type Badge
            Center(
              child: Chip(
                label: Text(
                  'Admin Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.blue.shade800,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            SizedBox(height: 30),

            // Name Field
            Text(
              'Full Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                enabled: _isEditing,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            SizedBox(height: 20),

            // Email Field (Read-only)
            Text(
              'Email Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              initialValue: _userData?['email'] ?? 'No email',
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                enabled: false,
                fillColor: Colors.grey.shade100,
                filled: true,
              ),
              readOnly: true,
            ),
            SizedBox(height: 20),

            // Gender Selection
            Text(
              'Gender',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
                enabled: _isEditing,
              ),
              items: _genderOptions.map((String gender) {
                return DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: _isEditing
                  ? (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    }
                  : null,
            ),
            SizedBox(height: 20),

            // Contact Field
            Text(
              'Contact Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _contactController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                enabled: _isEditing,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Contact number is required';
                }
                return null;
              },
            ),
            SizedBox(height: 30),

            // Password Change Section
            if (_isChangingPassword) ...[
              Divider(),
              SizedBox(height: 10),
              Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),

              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_open),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Confirm New Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_open),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Password Change Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isChangingPassword = false;
                        _currentPasswordController.clear();
                        _newPasswordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    icon: Icon(Icons.cancel),
                    label: Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton.icon(
                    onPressed: _changePassword,
                    icon: Icon(Icons.check),
                    label: Text('Update Password'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Divider(),
            ],

            SizedBox(height: 40),

            // Profile Edit Buttons
            Center(
              child: _isEditing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              // Reset controllers to original values
                              _nameController.text =
                                  _userData?['fullname'] ?? '';
                              _contactController.text =
                                  _userData?['contactno'] ?? '';
                              _selectedGender = _userData?['gender'] ?? 'Other';
                            });
                          },
                          icon: Icon(Icons.cancel),
                          label: Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                        SizedBox(width: 20),
                        ElevatedButton.icon(
                          onPressed: _saveUserData,
                          icon: Icon(Icons.check),
                          label: Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: Icon(Icons.edit),
                          label: Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                        ),
                        SizedBox(height: 20),
                        if (!_isChangingPassword)
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isChangingPassword = true;
                              });
                            },
                            icon: Icon(Icons.lock),
                            label: Text('Change Password'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                      ],
                    ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
