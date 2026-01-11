import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'new_message_page.dart';
import '../services/chat_service.dart';

class ChatsListPage extends StatefulWidget {
  @override
  _ChatsListPageState createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Conversation> _conversations = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final conversations = await ChatService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading conversations: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load conversations')));
      }
      setState(() => _isLoading = false);
    }
  }

  List<Conversation> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((conversation) {
      return conversation.user.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF64B5F6),
        title: Text('Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewMessagePage()),
              );
            },
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadConversations),
        ],
      ),
      body: Column(
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
                hintText: 'Search conversations',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a new conversation',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _filteredConversations[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFF64B5F6),
                          backgroundImage:
                              conversation.user.profileImage != null
                              ? NetworkImage(conversation.user.profileImage!)
                              : null,
                          child: conversation.user.profileImage == null
                              ? Text(
                                  conversation.user.name
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(conversation.user.name),
                        subtitle: Text(
                          conversation.lastMessage.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: SizedBox(
                          width: 80, // Fixed width to prevent overflow
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(conversation.lastMessage.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (conversation.unreadCount > 0) ...[
                                SizedBox(height: 4),
                                Container(
                                  constraints: BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    conversation.unreadCount > 99
                                        ? '99+'
                                        : conversation.unreadCount.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                receiver: conversation.user,
                                onConversationUpdated: _loadConversations,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "chats_list_fab",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewMessagePage()),
          );
        },
        backgroundColor: Color(0xFF64B5F6),
        child: Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
