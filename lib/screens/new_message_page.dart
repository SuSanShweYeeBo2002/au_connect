import 'package:flutter/material.dart';
import 'chat_page.dart';
import '../services/chat_service.dart';

class NewMessagePage extends StatefulWidget {
  @override
  _NewMessagePageState createState() => _NewMessagePageState();
}

class _NewMessagePageState extends State<NewMessagePage> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      print('Fetching users...');
      final users = await ChatService.getUsers();
      print('Received users: ${users.length}');
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load users: $e'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(label: 'Retry', onPressed: _loadUsers),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF64B5F6),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('New message', style: TextStyle(fontSize: 20)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Type a name or group',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF64B5F6)),
                ),
                prefixText: 'To: ',
                prefixStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
                ),
              ),
            )
          else if (_users.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No users found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    TextButton(onPressed: _loadUsers, child: Text('Retry')),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Available Users',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (!_isLoading && _users.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFF64B5F6),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      radius: 20,
                    ),
                    title: Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    subtitle: Text(
                      user.email,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user.isOnline)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(receiver: user),
                        ),
                      );
                    },
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class Contact {
  final String name;
  final String imagePath;
  final bool isOnline;

  Contact({required this.name, required this.imagePath, this.isOnline = false});
}

final List<Contact> suggestedContacts = [
  Contact(
    name: 'Kko Tun Tun',
    imagePath: 'assets/images/profile_placeholder.png',
  ),
  Contact(
    name: 'Kyaw Ye Htet',
    imagePath: 'assets/images/profile_placeholder.png',
  ),
  Contact(
    name: 'KhinNi Lar Aung Koe',
    imagePath: 'assets/images/profile_placeholder.png',
  ),
  Contact(
    name: 'Susan Shwe Yee Bo',
    imagePath: 'assets/images/profile_placeholder.png',
  ),
  Contact(
    name: 'Htet Aung Bo',
    imagePath: 'assets/images/profile_placeholder.png',
  ),
  Contact(
    name: 'Soe Wana Htun',
    imagePath: 'assets/images/profile_placeholder.png',
    isOnline: true,
  ),
  Contact(
    name: 'Pyae Phyo Thu',
    imagePath: 'assets/images/profile_placeholder.png',
  ),
  Contact(
    name: 'Myatphone Kyaw',
    imagePath: 'assets/images/profile_placeholder.png',
    isOnline: true,
  ),
  Contact(
    name: 'Swan Htet Aung',
    imagePath: 'assets/images/profile_placeholder.png',
    isOnline: true,
  ),
  Contact(
    name: 'Nyan Htoo',
    imagePath: 'assets/images/profile_placeholder.png',
  ),
  Contact(
    name: 'phone myint myat',
    imagePath: 'assets/images/profile_placeholder.png',
  ),
];
