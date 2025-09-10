import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings page (create later if needed)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Settings tapped")),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      "https://via.placeholder.com/150", // Replace with user image
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat("Posts", "20"),
                        _buildStat("Followers", "150"),
                        _buildStat("Following", "120"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Username + Bio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("John Doe",
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 4),
                  Text("Web Developer | Flutter Enthusiast"),
                ],
              ),
            ),

            // Buttons: Edit Profile + Share Profile
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Edit Profile tapped")),
                        );
                      },
                      child: Text("Edit Profile"),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: Text("Share Profile"),
                    ),
                  ),
                ],
              ),
            ),

            Divider(),

            // Grid of posts
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 9, // Example: 9 posts
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 per row
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                return Image.network(
                  "https://via.placeholder.com/300", // Replace with post images
                  fit: BoxFit.cover,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String count) {
    return Column(
      children: [
        Text(count,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
