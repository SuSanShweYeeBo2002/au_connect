import 'package:flutter/material.dart';
import 'add_post_page.dart';
import 'comments_page.dart';
import 'other_user_profile_page.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../widgets/simple_image_viewer.dart';
import '../widgets/optimized_image.dart';
import '../widgets/banner_ad_widget.dart';
import '../config/theme_config.dart';

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
          authorProfileImage: post.authorProfileImage,
          content: post.content,
          image: post.image,
          images: post.images,
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
          authorProfileImage: post.authorProfileImage,
          content: post.content,
          image: post.image,
          images: post.images,
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

  Future<void> _showReportDialog(String postId) async {
    final reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please provide a reason for reporting this post:'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await PostService.reportPost(postId: postId, reason: reason);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Post reported successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showImageGallery(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleImageGalleryViewer(
          imageUrls: images,
          initialIndex: initialIndex,
          heroTag: 'post_image',
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) return SizedBox.shrink();

    // Single image - full width
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _showImageGallery(images, 0),
        child: Container(
          height: 300,
          width: double.infinity,
          child: OptimizedImage(
            imageUrl: images[0],
            fit: BoxFit.cover,
            heroTag: 'post_image_0',
          ),
        ),
      );
    }

    // Two images - side by side
    if (images.length == 2) {
      return Container(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showImageGallery(images, 0),
                child: OptimizedImage(
                  imageUrl: images[0],
                  fit: BoxFit.cover,
                  heroTag: 'post_image_0',
                ),
              ),
            ),
            SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _showImageGallery(images, 1),
                child: OptimizedImage(
                  imageUrl: images[1],
                  fit: BoxFit.cover,
                  heroTag: 'post_image_1',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Three images - one large left, two stacked right
    if (images.length == 3) {
      return Container(
        height: 250,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _showImageGallery(images, 0),
                child: OptimizedImage(
                  imageUrl: images[0],
                  fit: BoxFit.cover,
                  heroTag: 'post_image_0',
                ),
              ),
            ),
            SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showImageGallery(images, 1),
                      child: OptimizedImage(
                        imageUrl: images[1],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        heroTag: 'post_image_1',
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showImageGallery(images, 2),
                      child: OptimizedImage(
                        imageUrl: images[2],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        heroTag: 'post_image_2',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Four or more images - 2x2 grid with "+X more" overlay on last image if more than 4
    return Container(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImageGallery(images, 0),
                    child: OptimizedImage(
                      imageUrl: images[0],
                      fit: BoxFit.cover,
                      heroTag: 'post_image_0',
                    ),
                  ),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImageGallery(images, 1),
                    child: OptimizedImage(
                      imageUrl: images[1],
                      fit: BoxFit.cover,
                      heroTag: 'post_image_1',
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImageGallery(images, 2),
                    child: OptimizedImage(
                      imageUrl: images[2],
                      fit: BoxFit.cover,
                      heroTag: 'post_image_2',
                    ),
                  ),
                ),
                SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showImageGallery(images, 3),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        OptimizedImage(
                          imageUrl: images[3],
                          fit: BoxFit.cover,
                          heroTag: 'post_image_3',
                        ),
                        if (images.length > 4)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                '+${images.length - 4}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        physics: BouncingScrollPhysics(),
        itemCount: posts.length, // No ad at bottom
        itemBuilder: (context, index) {
          final post = posts[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: GestureDetector(
                    onTap: () {
                      // Don't navigate to profile if it's the current user
                      if (currentUserId != post.authorId) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherUserProfilePage(
                              userId: post.authorId,
                              userName: post.authorName,
                            ),
                          ),
                        );
                      }
                    },
                    child: OptimizedCircleAvatar(
                      imageUrl: post.authorProfileImage,
                      fallbackText: post.authorName,
                    ),
                  ),
                  title: GestureDetector(
                    onTap: () {
                      // Don't navigate to profile if it's the current user
                      if (currentUserId != post.authorId) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherUserProfilePage(
                              userId: post.authorId,
                              userName: post.authorName,
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      post.authorName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  subtitle: Text(_formatTime(post.createdAt)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost(post, index);
                      } else if (value == 'report') {
                        _showReportDialog(post.id);
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
                // Display multiple images if available
                if (post.images != null && post.images!.isNotEmpty)
                  _buildImageGallery(post.images!)
                // Fallback to single image for backward compatibility
                else if (post.image != null)
                  GestureDetector(
                    onTap: () => _showImageGallery([post.image!], 0),
                    child: Container(
                      width: double.infinity,
                      child: OptimizedImage(
                        imageUrl: post.image!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        heroTag: 'post_image_0',
                      ),
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
      backgroundColor: AppTheme.primaryBeige,
      appBar: AppBar(
        title: Text('AU CONNECT'),
        elevation: 0,
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
          // Wide screen (desktop/tablet) - show sidebar layout
          if (constraints.maxWidth > 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main content (posts)
                Expanded(
                  flex: 7,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 600),
                      child: _buildContent(),
                    ),
                  ),
                ),
                // Right sidebar (ads) - only show when there are posts
                if (!isLoading && posts.isNotEmpty)
                  Container(
                    width: 300,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Sticky sidebar with ads
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sponsored',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(height: 250, child: BannerAdWidget()),
                              SizedBox(height: 16),
                              Container(height: 250, child: BannerAdWidget()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }

          // Mobile/narrow screen - original layout
          double maxWidth = constraints.maxWidth > 600
              ? 500
              : constraints.maxWidth * 0.98;
          return Center(
            child: Container(width: maxWidth, child: _buildContent()),
          );
        },
      ),
    );
  }
}
