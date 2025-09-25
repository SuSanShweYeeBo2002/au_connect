import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> posts = [
      {
        'author': 'Alice',
        'avatarUrl': 'https://randomuser.me/api/portraits/women/1.jpg',
        'imageUrl':
            'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        'content': 'Enjoying a beautiful day at the park!',
        'likes': 120,
        'comments': [
          {'user': 'Bob', 'text': 'Looks fun!'},
          {'user': 'Diana', 'text': 'Nice photo!'},
        ],
      },
      {
        'author': 'Bob',
        'avatarUrl': 'https://randomuser.me/api/portraits/men/2.jpg',
        'imageUrl':
            'https://images.unsplash.com/photo-1465101046530-73398c7f28ca',
        'content': 'Flutter is awesome! #flutterdev',
        'likes': 89,
        'comments': [
          {'user': 'Alice', 'text': 'Totally agree!'},
        ],
      },
      {
        'author': 'Charlie',
        'avatarUrl': 'https://randomuser.me/api/portraits/men/3.jpg',
        'imageUrl':
            'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
        'content': 'Anyone up for coffee?',
        'likes': 42,
        'comments': [
          {'user': 'Eve', 'text': 'I am!'},
        ],
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Social Feed'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600
              ? 500
              : constraints.maxWidth * 0.98;
          return Center(
            child: Container(
              width: maxWidth,
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(post['avatarUrl']),
                          ),
                          title: Text(
                            post['author'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('2h ago'),
                          trailing: Icon(Icons.more_vert),
                        ),
                        if (post['imageUrl'] != null)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              post['imageUrl'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            post['content'],
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.favorite_border),
                              SizedBox(width: 4),
                              Text('${post['likes']}'),
                              SizedBox(width: 16),
                              Icon(Icons.comment),
                              SizedBox(width: 4),
                              Text('${post['comments'].length}'),
                            ],
                          ),
                        ),
                        if (post['comments'] != null &&
                            post['comments'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...post['comments'].map<Widget>(
                                  (comment) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '${comment['user']}: ${comment['text']}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}
