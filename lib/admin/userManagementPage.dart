import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Only load accounts with user type, excluding admins
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('usertype', isEqualTo: 'user')
          .get();

      List<Map<String, dynamic>> users = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id; // Save document ID for later updates
        users.add(userData);
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Filter user list
  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _users;
    }

    return _users.where((user) {
      String name = user['name'] ?? '';
      String email = user['email'] ?? '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Change user account status (disable/enable)
  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': !currentStatus,
      });

      // Update local list to reflect changes
      setState(() {
        for (var user in _users) {
          if (user['id'] == userId) {
            user['isActive'] = !currentStatus;
            break;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(currentStatus
              ? 'User has been disabled'
              : 'User has been enabled'),
          backgroundColor: currentStatus ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      print('Error changing user status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show user details dialog
  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Name', user['name'] ?? 'Not provided'),
                _buildDetailRow('Email', user['email'] ?? 'Not provided'),
                _buildDetailRow('Contact', user['contactno'] ?? 'Not provided'),
                _buildDetailRow('Gender', user['gender'] ?? 'Not provided'),
                _buildDetailRow(
                    'Height', '${user['height'] ?? 'Not provided'} cm'),
                _buildDetailRow(
                    'Weight', '${user['weight'] ?? 'Not provided'} kg'),
                _buildDetailRow(
                    'Status', user['isActive'] == true ? 'Active' : 'Disabled'),
                _buildDetailRow('User ID', user['id'] ?? 'Not provided'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Helper to build detail rows
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Users',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(child: Text('No users found'))
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final bool isActive = user['isActive'] ?? true;
                          final String userName =
                              user['name'] ?? 'Unknown User';
                          final String firstLetter = userName.isNotEmpty
                              ? userName.substring(0, 1)
                              : '?';

                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(firstLetter),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              title: Text(userName),
                              subtitle: Text(user['email'] ?? 'No Email'),
                              onTap: () => _showUserDetails(user),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 4.0),
                                    decoration: BoxDecoration(
                                      color:
                                          isActive ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Disabled',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8.0),
                                  ElevatedButton(
                                    onPressed: () => _showConfirmationDialog(
                                        user['id'], isActive),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isActive ? Colors.red : Colors.green,
                                    ),
                                    child: Text(
                                      isActive ? 'Disable' : 'Enable',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        child: Icon(Icons.refresh),
        tooltip: 'Refresh User List',
      ),
    );
  }

  void _showConfirmationDialog(String userId, bool currentStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(currentStatus ? 'Disable User' : 'Enable User'),
          content: Text(currentStatus
              ? 'Are you sure you want to disable this user? Once disabled, the user will not be able to log in to the system.'
              : 'Are you sure you want to enable this user? Once enabled, the user will be able to log in to the system normally.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _toggleUserStatus(userId, currentStatus);
              },
              child: Text('Confirm'),
              style: TextButton.styleFrom(
                foregroundColor: currentStatus ? Colors.red : Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }
}
