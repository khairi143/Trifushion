import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../login.dart';
import 'adminprofilepage.dart';

class AdminHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();

  final List<Widget> _pages = [
    UserManagementPage(),
    AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          // Add logout button to app bar
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutConfirmationDialog(context);
            },
          ),
        ],
      ),

      // Body content based on current index
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the current index on tap
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'User Management',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _authService.signout(); // Sign out the user

                  // Close the dialog
                  Navigator.of(context).pop();

                  // Navigate back to login page and clear history
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                } catch (e) {
                  print("Error during logout: $e");
                  Navigator.of(context).pop(); // Close dialog on error
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error during logout')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fix field naming inconsistencies
    _checkAndFixUserFields();
  }

  // Method to check and fix field naming inconsistencies
  Future<void> _checkAndFixUserFields() async {
    try {
      // Get all users from Firestore
      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (var doc in userSnapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>;
        var docRef = FirebaseFirestore.instance.collection('users').doc(doc.id);

        // Check if 'name' field exists but 'fullname' doesn't
        if (userData.containsKey('name') && !userData.containsKey('fullname')) {
          // Update document to use 'fullname' instead of 'name'
          await docRef.update({'fullname': userData['name']});
          print('Updated user ${doc.id} to use fullname field');
        }

        // Add the 'isBanned' field if it doesn't exist
        if (!userData.containsKey('isBanned')) {
          await docRef.update({'isBanned': false});
          print('Added isBanned field to user ${doc.id}');
        }
      }
    } catch (e) {
      print('Error fixing user fields: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Users',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Stats section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  int totalUsers = 0;
                  int bannedUsers = 0;

                  snapshot.data!.docs.forEach((doc) {
                    var userData = doc.data() as Map<String, dynamic>;
                    if (userData['usertype'] == 'user') {
                      totalUsers++;
                      if (userData['isBanned'] == true) {
                        bannedUsers++;
                      }
                    }
                  });

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                          'Total Users', totalUsers.toString(), Colors.blue),
                      _buildStatCard('Active Users',
                          (totalUsers - bannedUsers).toString(), Colors.green),
                      _buildStatCard(
                          'Banned Users', bannedUsers.toString(), Colors.red),
                    ],
                  );
                } else {
                  return SizedBox(height: 85);
                }
              }),
        ),

        SizedBox(height: 10),

        // User list
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error loading: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No users found'));
                    }

                    // Filter users
                    var users = snapshot.data!.docs;
                    if (_searchQuery.isNotEmpty) {
                      users = users.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        var email = data['email'] ?? '';
                        var name = data['fullname'] ?? '';
                        return email
                                .toString()
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            name
                                .toString()
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        var userData =
                            users[index].data() as Map<String, dynamic>;
                        var userId = users[index].id;

                        // Enhanced debugging to show all available fields
                        print('User data for $userId: $userData');

                        var email = userData['email'] ?? 'No Email';
                        var name = userData['fullname'] ?? 'No Name';
                        var userType = userData['usertype'] ?? 'Regular User';
                        var isBanned = userData['isBanned'] ?? false;

                        // Don't show admin accounts in the list
                        if (userType == 'admin') {
                          return SizedBox.shrink();
                        }

                        return Card(
                          margin: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isBanned ? Colors.red : Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(email),
                                Text(
                                  isBanned ? 'Banned' : 'Active',
                                  style: TextStyle(
                                    color: isBanned ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    // Ban/Unban Button
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _showBanConfirmationDialog(
                                              userId, name, isBanned),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isBanned
                                            ? Colors.green
                                            : Colors.red,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                      icon: Icon(isBanned
                                          ? Icons.check_circle
                                          : Icons.block),
                                      label: Text(isBanned ? 'Unban' : 'Ban'),
                                    ),

                                    // Delete Button
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _showDeleteConfirmationDialog(
                                              userId, name),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade800,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                      icon: Icon(Icons.delete_forever),
                                      label: Text('Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        width: 100,
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBanConfirmationDialog(
      String userId, String userName, bool isCurrentlyBanned) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              isCurrentlyBanned ? 'Confirm User Unban' : 'Confirm User Ban'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${isCurrentlyBanned ? 'Unban' : 'Ban'} user: $userName'),
              SizedBox(height: 20),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                setState(() {
                  _isLoading = true;
                });

                bool success;
                if (isCurrentlyBanned) {
                  success = await _authService.unbanUser(
                      userId, reasonController.text);
                } else {
                  success =
                      await _authService.banUser(userId, reasonController.text);
                }

                setState(() {
                  _isLoading = false;
                });

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'User ${isCurrentlyBanned ? 'unbanned' : 'banned'} successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Operation failed, please try again')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentlyBanned ? Colors.green : Colors.red,
              ),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm User Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Warning: This action cannot be undone!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                  'Are you sure you want to permanently delete user: $userName?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                setState(() {
                  _isLoading = true;
                });

                bool success = await _authService.deleteUser(userId);

                setState(() {
                  _isLoading = false;
                });

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Deletion failed, please try again')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
