import 'package:flutter/material.dart';

class FriendPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> friends = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve'];
    return Scaffold(
      appBar: AppBar(title: Text('Friends')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600
              ? 500
              : constraints.maxWidth * 0.98;
          return Center(
            child: Container(
              width: maxWidth,
              child: ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(friends[index][0])),
                      title: Text(friends[index]),
                      subtitle: Text('Online'),
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
