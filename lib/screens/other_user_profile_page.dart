import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  final String? userName; // Optional hint for AppBar

  const OtherUserProfilePage({Key? key, required this.userId, this.userName})
    : super(key: key);

  @override
  _OtherUserProfilePageState createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  List<Post> _userPosts = [];
  bool _isLoadingPosts = true;
  bool _isLoadingProfile = true;
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoadingProfile = true;
      });

      final response = await UserService.getUserById(widget.userId);
      final userData = response['data'];

      setState(() {
        _userName =
            userData['displayName'] ??
            userData['email']?.split('@')[0] ??
            'User';
        _userEmail = userData['email'];
        _profileImageUrl = userData['profileImage'];
        _isLoadingProfile = false;
      });

      await _loadUserPosts();
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      setState(() {
        _isLoadingPosts = true;
      });

      final response = await PostService.getPostsByAuthor(
        authorId: widget.userId,
        page: _currentPage,
        limit: 10,
      );

      setState(() {
        _userPosts = response.posts;
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
          authorProfileImage: _userPosts[index].authorProfileImage,
          content: _userPosts[index].content,
          image: _userPosts[index].image,
          images: _userPosts[index].images,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE3F2FD),
      appBar: AppBar(
        title: Text(_userName ?? widget.userName ?? 'Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
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
                          height: 120,
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
                          bottom: -40,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                            child: _profileImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey[600],
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 45),

                    if (_isLoadingProfile)
                      CircularProgressIndicator()
                    else ...[
                      Text(_userName ?? "User", style: TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail ?? "",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],

                    const SizedBox(height: 20),
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
                            height: 700,
                            child: TabBarView(
                              children: [
                                _buildPosts(),
                                _buildAlbum(),
                                _buildAbout(),
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
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null
                        ? Icon(Icons.person, color: Colors.grey[600])
                        : null,
                  ),
                  title: Text(post.authorName),
                  subtitle: Text(_formatDate(post.createdAt)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(post.content, style: TextStyle(fontSize: 16)),
                ),
                // Display images from either 'images' array or singular 'image' field
                if (post.images != null && post.images!.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1,
                    child: PageView.builder(
                      itemCount: post.images!.length,
                      itemBuilder: (context, imgIndex) {
                        return Stack(
                          children: [
                            Image.network(
                              post.images![imgIndex],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (post.images!.length > 1)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${imgIndex + 1}/${post.images!.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  )
                else if (post.image != null && post.image!.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      post.image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
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

  Widget _buildAlbum() {
    if (_isLoadingPosts) {
      return Center(child: CircularProgressIndicator());
    }

    // Filter posts that have images
    final postsWithImages = _userPosts
        .where(
          (post) =>
              (post.image != null && post.image!.isNotEmpty) ||
              (post.images != null && post.images!.isNotEmpty),
        )
        .toList();

    if (postsWithImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No photos yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Photos from posts will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserPosts,
      child: GridView.builder(
        padding: EdgeInsets.all(4),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: postsWithImages.length,
        itemBuilder: (context, index) {
          final post = postsWithImages[index];
          final displayImage = post.images != null && post.images!.isNotEmpty
              ? post.images![0]
              : post.image!;

          return GestureDetector(
            onTap: () {
              // Show full image in a dialog
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBar(
                        title: Text(post.authorName),
                        leading: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Flexible(
                        child: post.images != null && post.images!.isNotEmpty
                            ? PageView.builder(
                                itemCount: post.images!.length,
                                itemBuilder: (context, imgIndex) {
                                  return Image.network(
                                    post.images![imgIndex],
                                    fit: BoxFit.contain,
                                  );
                                },
                              )
                            : Image.network(post.image!, fit: BoxFit.contain),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(post.content),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  displayImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
                if (post.images != null && post.images!.length > 1)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.collections,
                            color: Colors.white,
                            size: 12,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${post.images!.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAbout() {
    if (_isLoadingProfile) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(Icons.person, 'Name', _userName ?? 'User'),
                  SizedBox(height: 12),
                  _buildInfoRow(Icons.email, 'Email', _userEmail ?? 'N/A'),
                  SizedBox(height: 12),
                  _buildInfoRow(Icons.account_circle, 'User ID', widget.userId),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.post_add,
                    'Total Posts',
                    '${_userPosts.length}',
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.photo,
                    'Photos',
                    '${_userPosts.fold<int>(0, (sum, p) => sum + ((p.images?.length ?? 0) + ((p.image != null && p.image!.isNotEmpty) ? 1 : 0)))}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
