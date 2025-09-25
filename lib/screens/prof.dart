import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top Header with background
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        "https://images.unsplash.com/photo-1506748686214-e9df14d4d9d0", // Replace with banner image
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      "https://via.placeholder.com/150", // Profile picture
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Name + Bio
            Text(
              "John Doe",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "Experimental electronic music pioneer.\nHalf of duo Way Out West. Boss at Anjunadeep.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),

            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {},
                  child: Text("Add Friend"),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {},
                  child: Text("Follow"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat("Followers", "236"),
                _buildStat("Followings", "523"),
                _buildStat("Posts", "18"),
              ],
            ),
            const SizedBox(height: 20),

            // Tab bar section (Posts / Albums / Friends)
            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    tabs: [
                      Tab(text: "POSTS"),
                      Tab(text: "ALBUMS"),
                      Tab(text: "FRIENDS"),
                    ],
                  ),
                  Container(
                    height: 400, // Fixed height for content
                    child: TabBarView(
                      children: [
                        _buildPosts(),
                        Center(child: Text("Albums will show here")),
                        Center(child: Text("Friends will show here")),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildPosts() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      "https://via.placeholder.com/100",
                    ),
                  ),
                  title: Text("John Doe"),
                  subtitle: Text("10 min ago"),
                  trailing: Icon(Icons.more_vert),
                ),
                SizedBox(height: 10),
                Image.network(
                  "https://images.unsplash.com/photo-1522202176988-66273c2fd55f",
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 10),
                Text("Tap into a world of fresh new audio. 🎶"),
              ],
            ),
          ),
        );
      },
    );
  }
}
