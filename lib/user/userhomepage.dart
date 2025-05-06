import 'package:flutter/material.dart';
import 'userprofilepage.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {

  int _currentIndex = 0;
  final List<Widget> _pages = [
    UserHomePage(),
    UserProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),

      //Footer
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex, 
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem( icon: Icon(Icons.home), label: 'Home', ),
          BottomNavigationBarItem( icon: Icon(Icons.person), label: 'Account', ),
        ],
      ),
    );
  }
}
