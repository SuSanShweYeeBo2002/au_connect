import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import 'user_list_page.dart';

class FriendRequestsPage extends StatefulWidget {
  @override
  _FriendRequestsPageState createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Friend> _pendingRequests = [];
  List<Friend> _sentRequests = [];
  bool _isLoadingPending = false;
  bool _isLoadingSent = false;
  String? _errorMessage;
  bool _hasChanges = false; // Track if friends list changed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingRequests();
    _loadSentRequests();
  }

  @override
  void didUpdateWidget(FriendRequestsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when widget updates
    _loadPendingRequests();
    _loadSentRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoadingPending = true;
      _errorMessage = null;
    });

    try {
      final response = await FriendService.getPendingRequests();
      setState(() {
        _pendingRequests = response.requests;
        _isLoadingPending = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingPending = false;
      });
    }
  }

  Future<void> _loadSentRequests() async {
    setState(() {
      _isLoadingSent = true;
    });

    try {
      final response = await FriendService.getSentRequests();
      setState(() {
        _sentRequests = response.requests;
        _isLoadingSent = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSent = false;
      });
    }
  }

  Future<void> _acceptRequest(Friend request) async {
    try {
      await FriendService.updateFriendRequest(
        requestId: request.id,
        status: FriendStatus.accepted,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Friend request accepted')));
      setState(() {
        _hasChanges = true;
      });
      _loadPendingRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept request: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectRequest(Friend request) async {
    try {
      await FriendService.updateFriendRequest(
        requestId: request.id,
        status: FriendStatus.rejected,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Friend request rejected')));
      setState(() {
        _hasChanges = true;
      });
      _loadPendingRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject request: ${e.toString()}')),
      );
    }
  }

  Future<void> _cancelRequest(Friend request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Request'),
        content: Text('Are you sure you want to cancel this friend request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FriendService.cancelFriendRequest(request.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Friend request cancelled')));
        _loadSentRequests();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel request: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showSendRequestDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserListPage()),
    );

    // Reload sent requests if a friend request was sent
    if (result == true) {
      setState(() {
        _hasChanges = true;
      });
      _loadSentRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Friend Requests'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                text: 'Received',
                icon: _pendingRequests.isNotEmpty
                    ? Badge(
                        label: Text(_pendingRequests.length.toString()),
                        child: Icon(Icons.inbox),
                      )
                    : Icon(Icons.inbox),
              ),
              Tab(text: 'Sent', icon: Icon(Icons.send)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildPendingRequestsList(), _buildSentRequestsList()],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showSendRequestDialog,
          child: Icon(Icons.person_add),
          tooltip: 'Send Friend Request',
        ),
        backgroundColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildPendingRequestsList() {
    if (_isLoadingPending) {
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
                'Error loading requests',
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
                onPressed: _loadPendingRequests,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No pending requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You don\'t have any friend requests at the moment',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      child: ListView.builder(
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          final requester = request.requester;
          final requesterName = requester?.name ?? 'Unknown';
          final requesterEmail = requester?.email ?? '';

          return Card(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  requesterName.isNotEmpty
                      ? requesterName[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(requesterName),
              subtitle: Text(requesterEmail),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => _acceptRequest(request),
                    tooltip: 'Accept',
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rejectRequest(request),
                    tooltip: 'Reject',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSentRequestsList() {
    if (_isLoadingSent) {
      return Center(child: CircularProgressIndicator());
    }

    if (_sentRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.send_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No sent requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'You haven\'t sent any friend requests yet',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSentRequests,
      child: ListView.builder(
        itemCount: _sentRequests.length,
        itemBuilder: (context, index) {
          final request = _sentRequests[index];
          final recipient = request.recipient;
          final recipientName = recipient?.name ?? 'Unknown';
          final recipientEmail = recipient?.email ?? '';

          return Card(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  recipientName.isNotEmpty
                      ? recipientName[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(recipientName),
              subtitle: Text('$recipientEmail • Pending'),
              trailing: IconButton(
                icon: Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _cancelRequest(request),
                tooltip: 'Cancel',
              ),
            ),
          );
        },
      ),
    );
  }
}
