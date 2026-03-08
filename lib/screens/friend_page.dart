import 'dart:math';
import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import '../config/theme_config.dart';
import 'friend_requests_page.dart';
import 'blocked_users_page.dart';

class FriendPage extends StatefulWidget {
  @override
  _FriendPageState createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  List<Friend> _friends = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _pendingRequestsCount = 0;
  late String _currentQuote;

  final List<String> _quotes = [
    'Believe you can and you\'re halfway there.',
    'The only way to do great work is to love what you do.',
    'Success is not final, failure is not fatal: it is the courage to continue that counts.',
    'Your limitation—it\'s only your imagination.',
    'Push yourself, because no one else is going to do it for you.',
    'Great things never come from comfort zones.',
    'Dream it. Wish it. Do it.',
    'Success doesn\'t just find you. You have to go out and get it.',
    'The harder you work for something, the greater you\'ll feel when you achieve it.',
    'Don\'t stop when you\'re tired. Stop when you\'re done.',
  ];

  @override
  void initState() {
    super.initState();
    _selectRandomQuote();
    _loadFriends();
    _loadPendingRequestsCount();
  }

  void _selectRandomQuote() {
    final random = Random();
    _currentQuote = _quotes[random.nextInt(_quotes.length)];
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await FriendService.getFriendsList();
      setState(() {
        _friends = response.friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPendingRequestsCount() async {
    try {
      final response = await FriendService.getPendingRequests();
      setState(() {
        _pendingRequestsCount = response.requests.length;
      });
    } catch (e) {
      // Silently fail for badge count
      print('Error loading pending requests count: $e');
    }
  }

  Future<void> _unfriend(Friend friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unfriend'),
        content: Text(
          'Are you sure you want to remove ${_getFriendName(friend)} from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Unfriend', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final friendUserId = _getFriendUserId(friend);
        await FriendService.unfriend(friendUserId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Friend removed successfully')));
        _loadFriends();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unfriend: ${e.toString()}')),
        );
      }
    }
  }

  String _getFriendName(Friend friend) {
    // Get the other user (not the current user)
    final otherUser = friend.requester ?? friend.recipient;
    return otherUser?.name ?? 'Unknown';
  }

  String _getFriendEmail(Friend friend) {
    final otherUser = friend.requester ?? friend.recipient;
    return otherUser?.email ?? '';
  }

  String _getFriendUserId(Friend friend) {
    // Get the friend's user ID (not the friendship record ID)
    final otherUser = friend.requester ?? friend.recipient;
    return otherUser?.id ?? '';
  }

  Future<void> _blockUser(Friend friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block User'),
        content: Text(
          'Are you sure you want to block ${_getFriendName(friend)}? This will unfriend them and prevent all interactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final friendUserId = _getFriendUserId(friend);
        await FriendService.blockUser(friendUserId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User blocked successfully')));
        _loadFriends();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to block user: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBeige,
      appBar: AppBar(
        title: Text('Friends'),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.person_add_outlined),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendRequestsPage(),
                    ),
                  );
                  if (result == true) {
                    _loadFriends();
                    _loadPendingRequestsCount();
                  }
                },
                tooltip: 'Friend Requests',
              ),
              if (_pendingRequestsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _pendingRequestsCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'blocked') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BlockedUsersPage()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'blocked',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20),
                    SizedBox(width: 12),
                    Text('Blocked Users'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Wide screen (desktop/tablet) - show sidebar layout
          if (constraints.maxWidth > 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main content (friends list)
                Expanded(
                  flex: 7,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 600),
                      child: _buildBody(),
                    ),
                  ),
                ),
                // Right sidebar (aesthetic elements)
                Container(
                  width: 300,
                  padding: EdgeInsets.all(16),
                  child: _buildAestheticSidebar(),
                ),
              ],
            );
          }

          // Mobile/narrow screen - original layout
          double maxWidth = constraints.maxWidth > 600
              ? 500
              : constraints.maxWidth * 0.98;
          return Center(
            child: Container(width: maxWidth, child: _buildBody()),
          );
        },
      ),
    );
  }

  Widget _buildAestheticSidebar() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Friend Statistics Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Your Network',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _buildStatRow(
                  'Friends',
                  _friends.length.toString(),
                  Icons.group,
                ),
                SizedBox(height: 12),
                _buildStatRow(
                  'Pending',
                  _pendingRequestsCount.toString(),
                  Icons.schedule,
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Decorative Quote Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[300]!, Colors.pink[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.format_quote, size: 40, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  _currentQuote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Logo Display
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/VMES-Logo-BG-White.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Error loading friends',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _loadFriends, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_friends.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.blue[300],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'No friends yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Start connecting with others by\nsending friend requests',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendRequestsPage(),
                    ),
                  );
                  if (result == true) {
                    _loadFriends();
                    _loadPendingRequestsCount();
                  }
                },
                icon: Icon(Icons.person_add),
                label: Text('Find Friends'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          final friendName = _getFriendName(friend);
          final friendEmail = _getFriendEmail(friend);

          return Card(
            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue[100],
                child: Text(
                  friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              title: Text(
                friendName,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  friendEmail,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.person_remove,
                              color: Colors.orange,
                            ),
                            title: Text(
                              'Unfriend',
                              style: TextStyle(color: Colors.orange),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _unfriend(friend);
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.block, color: Colors.red),
                            title: Text(
                              'Block',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _blockUser(friend);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
