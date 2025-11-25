import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Post> _userPosts = [];
  bool _isLoadingPosts = true;
  String? _userId;
  int _currentPage = 1;
  bool _hasMorePosts = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = await AuthService.instance.getUserId();
    setState(() {
      _userId = userId;
    });
    if (userId != null) {
      await _loadUserPosts();
    }
  }

  Future<void> _loadUserPosts() async {
    if (_userId == null) return;

    try {
      setState(() {
        _isLoadingPosts = true;
      });

      final response = await PostService.getPostsByAuthor(
        authorId: _userId!,
        page: _currentPage,
        limit: 10,
      );

      setState(() {
        _userPosts = response.posts;
        _hasMorePosts = response.pagination.hasNext;
        _isLoadingPosts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPosts = false;
      });
      print('Error loading user posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load posts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLike(String postId, int index) async {
    try {
      final response = await PostService.likePost(postId);

      setState(() {
        _userPosts[index] = Post(
          id: _userPosts[index].id,
          authorId: _userPosts[index].authorId,
          authorEmail: _userPosts[index].authorEmail,
          authorName: _userPosts[index].authorName,
          content: _userPosts[index].content,
          image: _userPosts[index].image,
          likeCount: response.likeCount,
          commentCount: _userPosts[index].commentCount,
          isLikedByUser: response.action == 'liked',
          createdAt: _userPosts[index].createdAt,
          updatedAt: _userPosts[index].updatedAt,
        );
      });
    } catch (e) {
      print('Error liking post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(String postId, int index) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await PostService.deletePost(postId);
      if (success) {
        setState(() {
          _userPosts.removeAt(index);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      // Call the AuthService logout method to clear stored data
      await AuthService.instance.logout();

      // Navigate to signin page and clear navigation stack
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } catch (e) {
      // Show error message if logout fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                            onPressed: _logout,
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
                      length: 3,
                      child: Column(
                        children: [
                          TabBar(
                            labelColor: Colors.blue,
                            tabs: [
                              Tab(text: "Posts"),
                              Tab(text: "Album"),
                              Tab(text: "About"),
                            ],
                          ),
                          Container(
                            height: 400,
                            child: TabBarView(
                              children: [
                                _buildPosts(),
                                Center(child: Text("Photos will show here")),
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
    if (_isLoadingPosts) {
      return Center(child: CircularProgressIndicator());
    }

    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserPosts,
      child: ListView.builder(
        itemCount: _userPosts.length,
        itemBuilder: (context, index) {
          final post = _userPosts[index];
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
                  title: Text(post.authorName),
                  subtitle: Text(_formatDate(post.createdAt)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _handleDelete(post.id, index);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(post.content, style: TextStyle(fontSize: 16)),
                ),
                if (post.image != null && post.image!.isNotEmpty)
                  Image.network(
                    post.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.broken_image, size: 64),
                        ),
                      );
                    },
                  ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post.isLikedByUser
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: post.isLikedByUser ? Colors.red : null,
                        ),
                        onPressed: () => _handleLike(post.id, index),
                      ),
                      Text('${post.likeCount}'),
                      SizedBox(width: 16),
                      Icon(Icons.comment),
                      SizedBox(width: 4),
                      Text('${post.commentCount}'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
