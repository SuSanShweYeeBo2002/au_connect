import 'package:flutter/material.dart';
import 'chat_page.dart';

class ChatsListPage extends StatelessWidget {
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
                MaterialPageRoute(builder: (context) => ChatPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
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
            child: ListView.builder(
              itemCount: recentChats.length,
              itemBuilder: (context, index) {
                final chat = recentChats[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150',
                    ),
                    child: Text(chat.name[0]),
                  ),
                  title: Text(chat.name),
                  subtitle: Text(chat.lastMessage),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(chat.time),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatPage()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatPreview {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;

  ChatPreview({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
  });
}

final List<ChatPreview> recentChats = [
  ChatPreview(
    name: 'Ariya Goulding',
    lastMessage: 'Have a good day, Roman!',
    time: '10:27 AM',
    unreadCount: 1,
  ),
  ChatPreview(
    name: 'Omari Norris',
    lastMessage: 'Hi, good to hear from you. It\'s bee...',
    time: '9:48 AM',
    unreadCount: 0,
  ),
  ChatPreview(
    name: 'Bella Huffman',
    lastMessage: 'Wow, that looks amazing.',
    time: '10:32 AM',
    unreadCount: 0,
  ),
  ChatPreview(
    name: 'Sherri Matthews',
    lastMessage: 'Hey there, I\'m having trouble open...',
    time: '11:24 AM',
    unreadCount: 3,
  ),
  ChatPreview(
    name: 'Marcus King',
    lastMessage: 'I\'m ready to buy this thing, but I h...',
    time: '9:48 AM',
    unreadCount: 0,
  ),
  ChatPreview(
    name: 'Chloe Hayes',
    lastMessage: 'Hi! My order arrived yest',
    time: '9:20 AM',
    unreadCount: 1,
  ),
];
