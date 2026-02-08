import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import 'simple_image_viewer.dart';
import '../screens/other_user_profile_page.dart';

class CommentRepliesWidget extends StatefulWidget {
  final String commentId;
  final int initialReplyCount;
  final bool autoExpand;
  final VoidCallback? onReplyAdded;

  const CommentRepliesWidget({
    Key? key,
    required this.commentId,
    this.initialReplyCount = 0,
    this.autoExpand = false,
    this.onReplyAdded,
  }) : super(key: key);

  @override
  State<CommentRepliesWidget> createState() => _CommentRepliesWidgetState();
}

class _CommentRepliesWidgetState extends State<CommentRepliesWidget> {
  List<CommentReply> replies = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isSubmitting = false;
  late bool showReplies;
  String? currentUserId;
  int currentPage = 1;
  bool hasMore = false;

  final TextEditingController _replyController = TextEditingController();
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    showReplies = widget.autoExpand;
    _loadCurrentUser();
    _scrollController.addListener(_onScroll);
    if (showReplies) {
      _loadReplies();
    }
  }

  @override
  void didUpdateWidget(CommentRepliesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // React to autoExpand changes from parent
    if (widget.autoExpand != oldWidget.autoExpand && widget.autoExpand) {
      setState(() {
        showReplies = true;
      });
      if (replies.isEmpty) {
        _loadReplies();
      }
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await AuthService.instance.getUserId();
      if (mounted) {
        setState(() {
          currentUserId = userId;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasMore) {
      _loadMoreReplies();
    }
  }

  Future<void> _loadReplies() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      currentPage = 1;
    });

    try {
      final response = await PostService.getReplies(
        commentId: widget.commentId,
        page: currentPage,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          replies = response.replies;
          hasMore = response.pagination.hasNext;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load replies: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreReplies() async {
    if (isLoadingMore || !hasMore) return;

    setState(() {
      isLoadingMore = true;
      currentPage++;
    });

    try {
      final response = await PostService.getReplies(
        commentId: widget.commentId,
        page: currentPage,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          replies.addAll(response.replies);
          hasMore = response.pagination.hasNext;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
          currentPage--; // Revert page increment on error
        });
      }
    }
  }

  Future<void> _toggleReplies() async {
    setState(() {
      showReplies = !showReplies;
    });

    if (showReplies && replies.isEmpty) {
      await _loadReplies();
    }
  }

  Future<void> _addReply() async {
    final content = _replyController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a reply')));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final newReply = await PostService.addReply(
        commentId: widget.commentId,
        content: content,
        imageFile: _selectedImage,
      );

      _replyController.clear();
      setState(() => _selectedImage = null);

      setState(() {
        replies.insert(0, newReply);
        isSubmitting = false;
        showReplies = true;
      });

      // Notify parent to refresh comment data
      widget.onReplyAdded?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reply added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add reply: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteReply(CommentReply reply, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Reply'),
          content: Text(
            'Are you sure you want to delete this reply? This action cannot be undone.',
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
      final success = await PostService.deleteReply(reply.id);

      if (success && mounted) {
        setState(() {
          replies.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reply deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete reply: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _showImageViewer(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SimpleImageViewer(imageUrl: imageUrl, heroTag: 'reply_image'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final replyCount = replies.isNotEmpty
        ? replies.length
        : widget.initialReplyCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reply toggle button
        if (replyCount > 0 || showReplies)
          TextButton.icon(
            onPressed: _toggleReplies,
            icon: Icon(
              showReplies ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
            ),
            label: Text(
              showReplies
                  ? 'Hide replies'
                  : 'View ${replyCount} ${replyCount == 1 ? 'reply' : 'replies'}',
              style: TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(0, 30),
            ),
          ),

        // Replies list
        if (showReplies) ...[
          if (isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // Reply input
            Container(
              margin: EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Column(
                children: [
                  // Image preview
                  if (_selectedImage != null) ...[
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _selectedImage!.path,
                              width: double.infinity,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image, size: 30),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                padding: EdgeInsets.all(2),
                                minimumSize: Size(24, 24),
                              ),
                              onPressed: () {
                                setState(() => _selectedImage = null);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                  // Reply input
                  Row(
                    children: [
                      // Image picker button
                      IconButton(
                        icon: Icon(Icons.image, size: 20),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(),
                        onPressed: () async {
                          final image = await _imagePicker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setState(() => _selectedImage = image);
                          }
                        },
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: InputDecoration(
                            hintText: 'Write a reply...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: isSubmitting ? null : _addReply,
                          icon: isSubmitting
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(Icons.send, color: Colors.white, size: 20),
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Replies
            ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: replies.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == replies.length) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final reply = replies[index];
                return Container(
                  margin: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (currentUserId != reply.authorId) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OtherUserProfilePage(
                                      userId: reply.authorId,
                                      userName: reply.authorName,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[400],
                              backgroundImage: reply.authorProfileImage != null
                                  ? NetworkImage(reply.authorProfileImage!)
                                  : null,
                              child: reply.authorProfileImage == null
                                  ? Text(
                                      reply.authorName[0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (currentUserId != reply.authorId) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OtherUserProfilePage(
                                                userId: reply.authorId,
                                                userName: reply.authorName,
                                              ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    reply.authorName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatTime(reply.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (currentUserId == reply.authorId)
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteReply(reply, index);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(reply.content, style: TextStyle(fontSize: 13)),
                      if (reply.image != null) ...[
                        SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showImageViewer(reply.image!),
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: 180,
                              maxHeight: 120,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Stack(
                                children: [
                                  Image.network(
                                    reply.image!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 180,
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.zoom_in,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ],
    );
  }
}
