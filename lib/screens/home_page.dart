import 'package:flutter/material.dart';
import 'add_post_page.dart';
import '../services/post_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Post> posts = [];
  bool isLoading = true;
  String? errorMessage;
  Set<String> likedPosts = {}; // Track which posts are liked by current user

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await PostService.getPosts();
      setState(() {
        posts = response.posts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _likePost(Post post, int index) async {
    try {
      // Optimistically update UI
      final wasLiked = likedPosts.contains(post.id);
      setState(() {
        if (wasLiked) {
          likedPosts.remove(post.id);
        } else {
          likedPosts.add(post.id);
        }
      });

      final response = await PostService.likePost(post.id);

      // Update the local post with new like count
      setState(() {
        posts[index] = Post(
          id: post.id,
          authorId: post.authorId,
          authorEmail: post.authorEmail,
          authorName: post.authorName,
          content: post.content,
          image: post.image,
          likeCount: response.likeCount,
          commentCount: post.commentCount,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
        );

        // Ensure liked state matches server response
        if (response.action == 'liked') {
          likedPosts.add(post.id);
        } else {
          likedPosts.remove(post.id);
        }
      });

      // Show subtle feedback
      if (response.action == 'liked') {
        // Optionally show a small animation or haptic feedback
        // HapticFeedback.lightImpact(); // Uncomment if you want haptic feedback
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        if (likedPosts.contains(post.id)) {
          likedPosts.remove(post.id);
        } else {
          likedPosts.add(post.id);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to like post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComments(Post post) {
    // TODO: Implement comments functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comments feature coming soon!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Failed to load posts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPosts, child: Text('Retry')),
          ],
        ),
      );
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to share something!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
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
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      post.authorName[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    post.authorName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_formatTime(post.createdAt)),
                  trailing: Icon(Icons.more_vert),
                ),
                if (post.image != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      post.image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(post.content, style: TextStyle(fontSize: 16)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _likePost(post, index),
                        child: Row(
                          children: [
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 200),
                              child: Icon(
                                likedPosts.contains(post.id)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                key: ValueKey(likedPosts.contains(post.id)),
                                color: likedPosts.contains(post.id)
                                    ? Colors.red
                                    : Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${post.likeCount}',
                              style: TextStyle(
                                color: likedPosts.contains(post.id)
                                    ? Colors.red
                                    : Colors.grey[600],
                                fontWeight: likedPosts.contains(post.id)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _showComments(post),
                        child: Row(
                          children: [
                            Icon(Icons.comment, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text('${post.commentCount}'),
                          ],
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
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AU CONNECT'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPostPage()),
                );

                // If post was created successfully, refresh posts and show success message
                if (result != null) {
                  await _loadPosts(); // Refresh the posts list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Post created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(Icons.add, color: Colors.white),
              mini: true,
              tooltip: 'Add Post',
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth > 600
              ? 500
              : constraints.maxWidth * 0.98;
          return Center(
            child: Container(width: maxWidth, child: _buildContent()),
          );
        },
      ),
      backgroundColor: Colors.grey[200],
    );
  }
}
