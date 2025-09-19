import 'package:flutter/material.dart';
import 'chat_page.dart';

class NewMessagePage extends StatelessWidget {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Suggested',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (var contact in suggestedContacts)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(contact.imagePath),
                      radius: 20,
                    ),
                    title: Text(
                      contact.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ChatPage()),
                      );
                    },
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
              ],
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
