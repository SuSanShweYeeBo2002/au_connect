import 'package:flutter/material.dart';
import 'home_page.dart';
import 'friend_page.dart';
import 'campus_corner_page.dart';
import 'profile_page.dart';

class MainTabPage extends StatefulWidget {
  @override
  _MainTabPageState createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    FriendPage(),
    CampusCornerPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Network'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Tools'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'You',
          ),
        ],
      ),
    );
  }
}
