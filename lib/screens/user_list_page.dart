import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/friend_service.dart';
import '../services/auth_service.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  final TextEditingController _searchController = TextEditingController();
  Set<String> _sentRequestIds = {};
  Set<String> _friendIds = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUsers();
    _loadFriendData();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await AuthService.instance.getUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await ChatService.getUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFriendData() async {
    try {
      // Load sent requests
      final sentRequests = await FriendService.getSentRequests();
      final sentIds = sentRequests.requests.map((r) => r.recipientId).toSet();

      // Load friends list
      final friendsResponse = await FriendService.getFriendsList();
      final friendIds = <String>{};
      for (final friend in friendsResponse.friends) {
        // Add both requester and recipient IDs since friendship is bidirectional
        if (friend.requesterId != _currentUserId) {
          friendIds.add(friend.requesterId);
        }
        if (friend.recipientId != _currentUserId) {
          friendIds.add(friend.recipientId);
        }
      }

      setState(() {
        _sentRequestIds = sentIds;
        _friendIds = friendIds;
      });
    } catch (e) {
      print('Error loading friend data: $e');
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user.name.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _sendFriendRequest(User user) async {
    try {
      await FriendService.sendFriendRequest(recipientId: user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent to ${user.name}'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _sentRequestIds.add(user.id);
      });
      // Return true to parent to trigger refresh
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getUserStatus(User user) {
    if (_friendIds.contains(user.id)) {
      return 'Friends';
    } else if (_sentRequestIds.contains(user.id)) {
      return 'Request Sent';
    }
    return '';
  }

  bool _canSendRequest(User user) {
    return !_friendIds.contains(user.id) && !_sentRequestIds.contains(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Friends'),
        backgroundColor: Color(0xFF64B5F6),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      backgroundColor: Color(0xFFE3F2FD),
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
                'Error loading users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              ElevatedButton(onPressed: _loadUsers, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'No users found'
                    : 'No results for "${_searchController.text}"',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _searchController.text.isEmpty
                    ? 'There are no other users available'
                    : 'Try a different search term',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadUsers();
        await _loadFriendData();
      },
      child: ListView.builder(
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          final status = _getUserStatus(user);
          final canSend = _canSendRequest(user);

          return Card(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    ),
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: status.isNotEmpty
                  ? Chip(
                      label: Text(status, style: TextStyle(fontSize: 12)),
                      backgroundColor: status == 'Friends'
                          ? Colors.green[100]
                          : Colors.orange[100],
                      labelStyle: TextStyle(
                        color: status == 'Friends'
                            ? Colors.green[900]
                            : Colors.orange[900],
                      ),
                    )
                  : canSend
                  ? IconButton(
                      icon: Icon(Icons.person_add, color: Colors.blue),
                      onPressed: () => _sendFriendRequest(user),
                      tooltip: 'Send Friend Request',
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
