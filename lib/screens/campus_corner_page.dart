import 'package:flutter/material.dart';
import 'pomodoro_timer_page.dart';
import 'idea_cloud_page.dart';
import 'upcoming_event_page.dart';
import 'au_poll_page.dart';
import 'study_sessions_page_simple.dart';
import 'shop_and_lost_found_page.dart';
import '../services/user_service.dart';
import '../config/theme_config.dart';

class CampusCornerPage extends StatefulWidget {
  @override
  State<CampusCornerPage> createState() => _CampusCornerPageState();
}

class _CampusCornerPageState extends State<CampusCornerPage> {
  bool _isLoading = true;
  String _userName = 'User';
  String _userEmail = '';
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await UserService.getCurrentUser();
      final userData = response['data'];

      if (mounted) {
        setState(() {
          _userName =
              userData['displayName'] ??
              userData['email']?.split('@')[0] ??
              'User';
          _userEmail = userData['email'] ?? '';
          _profileImageUrl = userData['profileImage'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBeige,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600
              ? 400
              : constraints.maxWidth * 0.98;
          return Center(
            child: Container(
              width: maxWidth,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 32.0,
                    horizontal: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppTheme.brownLight,
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                            child: _isLoading
                                ? CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : (_profileImageUrl == null
                                      ? Text(
                                          _userName.isNotEmpty
                                              ? _userName[0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _userEmail,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShopAndLostFoundPage(),
                                ),
                              );
                            },
                            child: _CampusTile(
                              title: 'Shop & Lost Found',
                              color: AppTheme.cardBackground,
                              icon: Icons.shopping_bag,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PomodoroTimerPage(),
                                ),
                              );
                            },
                            child: _CampusTile(
                              title: 'Pomodoro Study Timer',
                              color: AppTheme.secondaryBeige,
                              icon: Icons.timer,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UpcomingEventPage(),
                                ),
                              );
                            },
                            child: _CampusTile(
                              title: 'Events & Notices',
                              color: AppTheme.cardBackground,
                              icon: Icons.event,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AuPollPage(),
                                ),
                              );
                            },
                            child: _CampusTile(
                              title: 'AU Poll',
                              color: AppTheme.cardBackground,
                              icon: Icons.poll,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => IdeaCloudPage(),
                                ),
                              );
                            },
                            child: _CampusTile(
                              title: 'Idea Cloud',
                              color: AppTheme.secondaryBeige,
                              icon: Icons.cloud,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudySessionsPage(),
                                ),
                              );
                            },
                            child: _CampusTile(
                              title: 'Study Buddy',
                              color: AppTheme.secondaryBeige,
                              icon: Icons.groups,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brownPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(Icons.logout, size: 24),
                            label: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                context,
                                '/signin',
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CampusTile extends StatelessWidget {
  final String title;
  // ...existing code...
  final Color? color;
  final IconData? icon;

  const _CampusTile({
    required this.title,
    // ...existing code...
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: AppTheme.brownPrimary, size: 28),
          if (icon != null) SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                // ...existing code...
              ],
            ),
          ),
        ],
      ),
    );
  }
}
