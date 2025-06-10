import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../login.dart';
import '../banned_account.dart';
import 'adminprofilepage.dart';
import 'admin_recipe_management.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  bool _isVerifying = true;
  bool _hasAccess = false;

  final List<Widget> _pages = [
    UserManagementPage(),
    AdminRecipeManagement(),
    AdminProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _verifyAdminAccess();
  }

  // Verify admin access on page load
  Future<void> _verifyAdminAccess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _redirectToLogin();
        return;
      }

      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await _authService.signout();
        _redirectToLogin();
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userType = userData['usertype']?.toString().toLowerCase().trim();

      // Check if user is admin
      if (userType != 'admin') {
        await _authService.signout();
        _redirectToLogin();
        return;
      }

      // Check if admin is banned
      bool isBanned = userData['isBanned'] == true || 
                     userData['banned'] == true || 
                     userData['is_banned'] == true;

      if (isBanned) {
        await _authService.signout();
        _redirectToBanned();
        return;
      }

      // Access granted
      setState(() {
        _hasAccess = true;
        _isVerifying = false;
      });

    } catch (e) {
      print('Admin verification error: $e');
      await _authService.signout();
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    }
  }

  void _redirectToBanned() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => BannedAccountPage(
          reason: "Admin account has been suspended.")),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while verifying access
    if (_isVerifying) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                'Verifying admin access...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show access denied if verification failed
    if (!_hasAccess) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 64, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You do not have admin privileges',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _redirectToLogin,
                child: Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Show admin dashboard if access is granted
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
            icon: Icon(Icons.restaurant_menu),
            label: 'Recipe Management',
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
  String _filterStatus = 'all'; // 'all', 'active', 'banned'
  String _sortBy = 'name'; // 'name', 'email', 'date'
  bool _sortAscending = true;

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

        // Debug button for checking banned users
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ElevatedButton.icon(
            onPressed: _debugBannedUsers,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            icon: Icon(Icons.bug_report),
            label: Text('Debug Banned Users'),
          ),
        ),

        // Filter and Sort Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              // Filter Status
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    isExpanded: true,
                    underline: SizedBox(),
                    icon: Icon(Icons.filter_list),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text('All Users')),
                      DropdownMenuItem(value: 'active', child: Text('Active Users')),
                      DropdownMenuItem(value: 'banned', child: Text('Banned Users')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Sort Options
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    underline: SizedBox(),
                    icon: Icon(Icons.sort),
                    items: [
                      DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                      DropdownMenuItem(value: 'email', child: Text('Sort by Email')),
                      DropdownMenuItem(value: 'date', child: Text('Sort by Date')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Sort Direction
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                  tooltip: _sortAscending ? 'Ascending' : 'Descending',
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 8),

        // Enhanced Stats section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  int totalUsers = 0;
                  int bannedUsers = 0;

                  for (var doc in snapshot.data!.docs) {
                    var userData = doc.data() as Map<String, dynamic>;
                    if (userData['usertype'] == 'user') {
                      totalUsers++;
                      // 检查多种可能的banned字段名
                      bool isBanned = userData['isBanned'] == true || 
                                    userData['banned'] == true || 
                                    userData['is_banned'] == true;
                      if (isBanned) {
                        bannedUsers++;
                      }
                    }
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                          'Total Users', totalUsers.toString(), Colors.blue, Icons.people),
                      _buildStatCard('Active Users',
                          (totalUsers - bannedUsers).toString(), Colors.green, Icons.check_circle),
                      _buildStatCard(
                          'Banned Users', bannedUsers.toString(), Colors.red, Icons.block),
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

                    // Filter and sort users
                    var users = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      var userType = data['usertype'] ?? 'Regular User';
                      
                      // Don't show admin accounts in the list
                      if (userType == 'admin') {
                        return false;
                      }
                      
                      return true;
                    }).toList();

                    // Apply search filter
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

                    // Apply status filter
                    if (_filterStatus != 'all') {
                      users = users.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        // 检查多种可能的banned字段名
                        bool isBanned = data['isBanned'] == true || 
                                      data['banned'] == true || 
                                      data['is_banned'] == true;
                        if (_filterStatus == 'active') {
                          return !isBanned;
                        } else if (_filterStatus == 'banned') {
                          return isBanned;
                        }
                        return true;
                      }).toList();
                    }

                    // Apply sorting
                    users.sort((a, b) {
                      var dataA = a.data() as Map<String, dynamic>;
                      var dataB = b.data() as Map<String, dynamic>;
                      
                      dynamic valueA, valueB;
                      
                      switch (_sortBy) {
                        case 'name':
                          valueA = dataA['fullname'] ?? '';
                          valueB = dataB['fullname'] ?? '';
                          break;
                        case 'email':
                          valueA = dataA['email'] ?? '';
                          valueB = dataB['email'] ?? '';
                          break;
                        case 'date':
                          valueA = dataA['createdAt'] ?? '';
                          valueB = dataB['createdAt'] ?? '';
                          break;
                        default:
                          valueA = dataA['fullname'] ?? '';
                          valueB = dataB['fullname'] ?? '';
                      }
                      
                      if (valueA is Timestamp && valueB is Timestamp) {
                        return _sortAscending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
                      } else {
                        String strA = valueA.toString().toLowerCase();
                        String strB = valueB.toString().toLowerCase();
                        return _sortAscending ? strA.compareTo(strB) : strB.compareTo(strA);
                      }
                    });

                    if (users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filter criteria',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        var userData =
                            users[index].data() as Map<String, dynamic>;
                        var userId = users[index].id;

                        var email = userData['email'] ?? 'No Email';
                        var name = userData['fullname'] ?? 'No Name';
                        var userType = userData['usertype'] ?? 'Regular User';
                        // 检查多种可能的banned字段名
                        bool isBanned = userData['isBanned'] == true || 
                                      userData['banned'] == true || 
                                      userData['is_banned'] == true;

                        return Card(
                          margin: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: (userData['isBanned'] == true || userData['banned'] == true || userData['is_banned'] == true) ? Colors.red : Colors.blue,
                              radius: 25,
                              child: Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isBanned ? Colors.red : Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isBanned ? 'Banned' : 'Active',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 用户详细信息区域
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'User Information',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          _buildUserInfoRow('User ID:', userId),
                                          _buildUserInfoRow('Full Name:', name),
                                          _buildUserInfoRow('Email:', email),
                                          _buildUserInfoRow('Account Type:', userType),
                                          _buildUserInfoRow('Contact:', userData['contactno'] ?? 'Not provided'),
                                          _buildUserInfoRow('Status:', isBanned ? '🚫 Banned' : '✅ Active'),
                                          if (isBanned)
                                            FutureBuilder<String?>(
                                              future: _authService.getBanReason(userId),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData && snapshot.data != null) {
                                                  return _buildUserInfoRow('Ban Reason:', snapshot.data!);
                                                }
                                                return SizedBox.shrink();
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    // 操作按钮区域
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Ban/Unban Button
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _showBanConfirmationDialog(
                                                    userId, name, isBanned),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isBanned
                                                  ? Colors.green
                                                  : Colors.orange[700],
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: Icon(isBanned
                                                ? Icons.check_circle
                                                : Icons.block),
                                            label: Text(isBanned ? 'Unban User' : 'Ban User'),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showUserDetailsDialog(userId, userData),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue[600],
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: Icon(Icons.info_outline),
                                            label: Text('View Details'),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        // Delete Button
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _showDeleteConfirmationDialog(
                                                    userId, name),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red.shade700,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            icon: Icon(Icons.delete_forever),
                                            label: Text('Delete'),
                                          ),
                                        ),
                                      ],
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

  // Debug method to check banned users
  Future<void> _debugBannedUsers() async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      
      List<String> debugInfo = [];
      int totalUsers = 0;
      int bannedUsers = 0;
      
      for (var doc in userSnapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>;
        if (userData['usertype'] == 'user') {
          totalUsers++;
          
          // Check all possible banned fields
          bool isBanned = userData['isBanned'] == true || 
                        userData['banned'] == true || 
                        userData['is_banned'] == true;
          
          if (isBanned) {
            bannedUsers++;
            debugInfo.add('BANNED: ${userData['fullname'] ?? 'No Name'} (${userData['email'] ?? 'No Email'})');
            debugInfo.add('  - isBanned: ${userData['isBanned']}');
            debugInfo.add('  - banned: ${userData['banned']}');
            debugInfo.add('  - is_banned: ${userData['is_banned']}');
          }
          
          // Show first few users for reference
          if (debugInfo.length < 10) {
            debugInfo.add('USER: ${userData['fullname'] ?? 'No Name'} - Status: ${isBanned ? 'BANNED' : 'ACTIVE'}');
          }
        }
      }
      
      // Show debug dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Debug: Banned Users'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Users: $totalUsers'),
                Text('Banned Users: $bannedUsers'),
                SizedBox(height: 16),
                Text('User Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: debugInfo.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        debugInfo[index],
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug error: $e')),
      );
    }
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Container(
        width: 110,
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

  void _showUserDetailsDialog(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: (userData['isBanned'] == true || userData['banned'] == true || userData['is_banned'] == true) ? Colors.red : Colors.blue,
                      radius: 25,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['fullname'] ?? 'No Name',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            userData['email'] ?? 'No Email',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // User Details
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildDetailRow(Icons.person, 'Full Name', userData['fullname'] ?? 'Not provided'),
                      _buildDetailRow(Icons.email, 'Email', userData['email'] ?? 'Not provided'),
                      _buildDetailRow(Icons.phone, 'Contact', userData['contactno'] ?? 'Not provided'),
                      _buildDetailRow(Icons.badge, 'User ID', userId),
                      _buildDetailRow(Icons.admin_panel_settings, 'Account Type', userData['usertype'] ?? 'user'),
                      _buildDetailRow(
                        (userData['isBanned'] == true || userData['banned'] == true || userData['is_banned'] == true) ? Icons.block : Icons.check_circle,
                        'Status',
                        (userData['isBanned'] == true || userData['banned'] == true || userData['is_banned'] == true) ? 'Banned' : 'Active',
                        statusColor: (userData['isBanned'] == true || userData['banned'] == true || userData['is_banned'] == true) ? Colors.red : Colors.green,
                      ),
                      if (userData['height'] != null)
                        _buildDetailRow(Icons.height, 'Height', userData['height']),
                      if (userData['weight'] != null)
                        _buildDetailRow(Icons.monitor_weight, 'Weight', userData['weight']),
                      if (userData['gender'] != null)
                        _buildDetailRow(Icons.wc, 'Gender', userData['gender']),
                      if (userData['createdAt'] != null)
                        _buildDetailRow(Icons.date_range, 'Created At', 
                          userData['createdAt'].toDate().toString().split('.')[0]),
                    ],
                  ),
                ),
                
                // Ban Reason if user is banned
                if (userData['isBanned'] == true || userData['banned'] == true || userData['is_banned'] == true)
                  Container(
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Ban Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        FutureBuilder<String?>(
                          future: _authService.getBanReason(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (snapshot.hasData && snapshot.data != null) {
                              return Text(
                                'Reason: ${snapshot.data}',
                                style: TextStyle(fontSize: 14),
                              );
                            }
                            return Text(
                              'No ban reason available',
                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showBanConfirmationDialog(
                            userId, 
                            userData['fullname'] ?? 'User', 
                            userData['isBanned'] == true || userData['banned'] == true || userData['is_banned'] == true
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (userData['isBanned'] == true || userData['banned'] == true || userData['is_banned'] == true) ? Colors.green : Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon((userData['isBanned'] == true || userData['banned'] == true || userData['is_banned'] == true) ? Icons.check_circle : Icons.block),
                        label: Text((userData['isBanned'] == true || userData['banned'] == true || userData['is_banned'] == true) ? 'Unban User' : 'Ban User'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showDeleteConfirmationDialog(userId, userData['fullname'] ?? 'User');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(Icons.delete_forever),
                        label: Text('Delete User'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: statusColor ?? Colors.black87,
                fontWeight: statusColor != null ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
