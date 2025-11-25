import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import 'friend_requests_page.dart';

class FriendPage extends StatefulWidget {
  @override
  _FriendPageState createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  List<Friend> _friends = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadPendingRequestsCount();
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
        await FriendService.unfriend(friend.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600
              ? 500
              : constraints.maxWidth * 0.98;
          return Center(
            child: Container(width: maxWidth, child: _buildBody()),
          );
        },
      ),
      backgroundColor: Colors.grey[100],
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
                              color: Colors.red,
                            ),
                            title: Text(
                              'Unfriend',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _unfriend(friend);
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
