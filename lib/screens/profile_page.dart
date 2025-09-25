import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600
              ? 500
              : constraints.maxWidth * 0.98;
          return Center(
            child: Container(
              width: maxWidth,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 190,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(
                                "https://i.pinimg.com/originals/49/73/5b/49735b38c27ca67787e201a8f4b0fd6d.jpg",
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
                              "https://win.gg/wp-content/uploads/2022/03/baki-hanma.jpg.webp",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),

                    Text("Baki Hanma", style: TextStyle(fontSize: 22)),

                    const SizedBox(height: 6),
                    Text(
                      "Software Engineer at Google!!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {},
                            child: Text(
                              "Edit",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(width: 10), // spacing between the buttons
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: BorderSide(color: Colors.blue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {},
                            child: Text("Log out"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: _showStat("followers", "256"),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: _showStat("following", "356"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    //const SizedBox(height: 10),
                    DefaultTabController(
                      length: 4,
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: Colors.blue,
                            tabs: [
                              Tab(text: "Posts"),
                              Tab(text: "Album"),
                              Tab(text: "Class"),
                              Tab(text: "About"),
                            ],
                          ),
                          Container(
                            height: 400,
                            child: TabBarView(
                              children: [
                                _buildPosts(),
                                Center(child: Text("Photos will show here")),
                                Center(child: Text("Classes will show here")),
                                Center(child: Text("About infos")),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _showStat(String label, String data) {
    return Column(
      children: [
        Text(data, style: TextStyle(fontSize: 18)),
        Text(label),
      ],
    );
  }

  Widget _buildPosts() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    "https://win.gg/wp-content/uploads/2022/03/baki-hanma.jpg.webp",
                  ),
                ),
                title: Text("Baki Hanma"),
                subtitle: Text("10 min ago"),
                trailing: Icon(Icons.more_vert),
              ),
              SizedBox(height: 10),
              Image.network(
                "https://th.bing.com/th/id/OIP.2jUQVYzbkgUqB_7LOAuP3QHaEK?w=310&h=180&c=7&r=0&o=7&dpr=1.4&pid=1.7&rm=3",
                fit: BoxFit.cover,
              ),
              SizedBox(height: 10),
              Text("A fight!!"),
            ],
          ),
        );
      },
    );
  }
}
