import 'package:flutter/material.dart';
import 'add_post_page.dart';
import 'comments_page.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Post> posts = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPosts();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await AuthService.instance.getUserId();
      setState(() {
        currentUserId = userId;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
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
      final wasLiked = post.isLikedByUser;
      setState(() {
        posts[index] = Post(
          id: post.id,
          authorId: post.authorId,
          authorEmail: post.authorEmail,
          authorName: post.authorName,
          content: post.content,
          image: post.image,
          likeCount: wasLiked ? post.likeCount - 1 : post.likeCount + 1,
          commentCount: post.commentCount,
          isLikedByUser: !wasLiked,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
        );
      });

      final response = await PostService.likePost(post.id);

      // Update the local post with server response
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
          isLikedByUser: response.action == 'liked',
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
        );
      });
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        posts[index] = post; // Revert to original post
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to like post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComments(Post post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsPage(post: post)),
    );

    // Refresh posts if comments were added
    if (result == true) {
      await _loadPosts();
    }
  }

  Future<void> _deletePost(Post post, int index) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Post'),
          content: Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      // Show loading state
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleting post...')));

      // Call the delete API
      final success = await PostService.deletePost(post.id);

      if (success) {
        // Remove post from local list
        setState(() {
          posts.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    backgroundImage: post.authorProfileImage != null
                        ? NetworkImage(post.authorProfileImage!)
                        : null,
                    child: post.authorProfileImage == null
                        ? Text(
                            post.authorName[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    post.authorName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(_formatTime(post.createdAt)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(post, index);
                      } else if (value == 'report') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Report feature coming soon!'),
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      List<PopupMenuEntry<String>> items = [];

                      // Show delete option only for post author
                      if (currentUserId == post.authorId) {
                        items.add(
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      items.add(
                        PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.report),
                              SizedBox(width: 8),
                              Text('Report'),
                            ],
                          ),
                        ),
                      );

                      return items;
                    },
                  ),
                ),
                if (post.image != null)
                  Container(
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Image.network(
                      post.image!,
                      fit: BoxFit.contain,
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
                                post.isLikedByUser
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                key: ValueKey(post.isLikedByUser),
                                color: post.isLikedByUser
                                    ? Colors.red
                                    : Colors.grey[600],
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${post.likeCount}',
                              style: TextStyle(
                                color: post.isLikedByUser
                                    ? Colors.red
                                    : Colors.grey[600],
                                fontWeight: post.isLikedByUser
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
              heroTag: "home_fab",
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
      backgroundColor: Color(0xFFE3F2FD),
    );
  }
}
