import 'package:flutter/material.dart';
import 'home_page.dart';
import 'friend_page.dart';
import 'campus_corner_page.dart';

class MainTabPage extends StatefulWidget {
  @override
  _MainTabPageState createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [HomePage(), FriendPage(), CampusCornerPage()];

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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Friend'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Campus'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement messaging functionality
        },
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 6.0,
        child: const Icon(Icons.message, color: Colors.white),
        tooltip: 'Messages',
      ),
    );
  }
}
