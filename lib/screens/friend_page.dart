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
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.person_add),
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
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadFriends),
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
      backgroundColor: Colors.grey[200],
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
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No friends yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Start adding friends to connect with them',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendRequestsPage(),
                    ),
                  );
                  _loadFriends();
                },
                icon: Icon(Icons.person_add),
                label: Text('Send Friend Request'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: ListView.builder(
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          final friendName = _getFriendName(friend);
          final friendEmail = _getFriendEmail(friend);

          return Card(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                ),
              ),
              title: Text(friendName),
              subtitle: Text(friendEmail),
              trailing: PopupMenuButton(
                icon: Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'unfriend') {
                    _unfriend(friend);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'unfriend',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Unfriend', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
