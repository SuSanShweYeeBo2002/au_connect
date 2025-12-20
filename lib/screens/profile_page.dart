import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Post> _userPosts = [];
  bool _isLoadingPosts = true;
  bool _isLoadingProfile = true;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;
  int _currentPage = 1;
  bool _hasMorePosts = true;
  final ImagePicker _picker = ImagePicker();

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

      final response = await UserService.getCurrentUser();
      final userData = response['data'];

      setState(() {
        _userId = userData['_id'];
        _userName = userData['email']?.split('@')[0] ?? 'User';
        _userEmail = userData['email'];
        _profileImageUrl = userData['profileImage'];
        _isLoadingProfile = false;
      });

      if (_userId != null) {
        await _loadUserPosts();
      }
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

  Future<void> _showEditProfileDialog() async {
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final emailController = TextEditingController(text: _userEmail);
        final passwordController = TextEditingController();
        final confirmPasswordController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 12),
                Text('Edit Profile'),
              ],
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'New Password (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text;
                  final confirmPassword = confirmPasswordController.text;

                  // Validation
                  if (email.isEmpty) {
                    setState(() => errorMessage = 'Email is required');
                    return;
                  }

                  if (password.isNotEmpty && password != confirmPassword) {
                    setState(() => errorMessage = 'Passwords do not match');
                    return;
                  }

                  if (email == _userEmail && password.isEmpty) {
                    setState(() => errorMessage = 'No changes to update');
                    return;
                  }

                  setState(() => errorMessage = null);

                  try {
                    await UserService.updateCurrentUser(
                      email: email != _userEmail ? email : null,
                      password: password.isNotEmpty ? password : null,
                    );

                    Navigator.pop(context);

                    // Reload user data
                    await _loadUserData();

                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Profile updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    setState(() => errorMessage = 'Error: $e');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    print('_pickAndUploadImage called');
    try {
      // Pick image - directly from gallery for web compatibility
      print('Opening image picker...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      print('Image selected: ${image?.path}');
      if (image == null) {
        print('No image selected');
        return;
      }

      XFile finalImage = image;

      // Crop image on mobile only (not on web)
      if (!kIsWeb) {
        print('Opening image cropper for mobile...');
        final CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Profile Image',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              cropStyle: CropStyle.circle,
            ),
            IOSUiSettings(
              title: 'Crop Profile Image',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              cropStyle: CropStyle.circle,
            ),
          ],
        );

        if (croppedFile == null) {
          print('Cropping cancelled');
          return;
        }

        print('Image cropped: ${croppedFile.path}');
        finalImage = XFile(croppedFile.path);
      } else {
        print('Skipping crop on web platform');
      }

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
      }

      // Upload image
      final response = await UserService.uploadProfileImage(finalImage);
      print('Upload response: $response');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Update profile image URL
      final newImageUrl = response['data']['profileImage'];
      print('New profile image URL: $newImageUrl');
      setState(() {
        _profileImageUrl = newImageUrl;
      });
      print('State updated with URL: $_profileImageUrl');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Profile Image'),
        content: Text('Are you sure you want to delete your profile image?'),
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
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
      }

      await UserService.deleteProfileImage();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Clear profile image URL
      setState(() {
        _profileImageUrl = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile image deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error deleting image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_profileImageUrl != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Profile Image'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfileImage();
                },
              ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text(
                _profileImageUrl != null
                    ? 'Change Profile Image'
                    : 'Upload Profile Image',
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel),
              title: Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
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

                    const SizedBox(height: 10),

                    // Upload Photo Button
                    ElevatedButton.icon(
                      onPressed: () {
                        print('Upload photo button clicked!');
                        _pickAndUploadImage();
                      },
                      icon: Icon(Icons.camera_alt),
                      label: Text('Upload Profile Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
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
                            onPressed: _isLoadingProfile
                                ? null
                                : _showEditProfileDialog,
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
                  AspectRatio(
                    aspectRatio: 1, // Square aspect ratio for profile posts
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
