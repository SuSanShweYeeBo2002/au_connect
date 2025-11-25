import 'package:flutter/material.dart';
import '../services/friend_service.dart';

class BlockedUsersPage extends StatefulWidget {
  @override
  _BlockedUsersPageState createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  List<BlockUser> _blockedUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await FriendService.getBlockedUsers();
      setState(() {
        _blockedUsers = response.blockedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(BlockUser blockedUser) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock User'),
        content: Text(
          'Are you sure you want to unblock ${blockedUser.blockedUser?.name ?? 'this user'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Unblock', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FriendService.unblockUser(blockedUser.blockedId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User unblocked successfully')));
        _loadBlockedUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unblock: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Blocked Users'), elevation: 0),
      body: _buildBody(),
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
                'Error loading blocked users',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBlockedUsers,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_blockedUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.block, size: 80, color: Colors.grey[400]),
              ),
              SizedBox(height: 24),
              Text(
                'No blocked users',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'You haven\'t blocked anyone yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBlockedUsers,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: _blockedUsers.length,
        itemBuilder: (context, index) {
          final blockedUser = _blockedUsers[index];
          final userName = blockedUser.blockedUser?.name ?? 'Unknown';
          final userEmail = blockedUser.blockedUser?.email ?? '';

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
                backgroundColor: Colors.red[100],
                child: Icon(Icons.block, color: Colors.red[800], size: 28),
              ),
              title: Text(
                userName,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  userEmail,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              trailing: ElevatedButton(
                onPressed: () => _unblockUser(blockedUser),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Unblock'),
              ),
            ),
          );
        },
      ),
    );
  }
}
