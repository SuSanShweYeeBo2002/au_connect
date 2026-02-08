import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../widgets/simple_image_viewer.dart';
import '../widgets/comment_reaction_picker.dart';
import '../widgets/comment_replies_widget.dart';
import 'other_user_profile_page.dart';

class CommentsPage extends StatefulWidget {
  final Post post;

  const CommentsPage({Key? key, required this.post}) : super(key: key);

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _commentController = TextEditingController();
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  List<Comment> comments = [];
  bool isLoading = false;
  bool isSubmitting = false;
  bool _commentsAdded = false; // Track if any comments were added
  String? currentUserId;

  // Reaction state
  Map<String, String?> userReactions = {}; // commentId -> reactionType
  Map<String, bool> showReactionPicker = {}; // commentId -> bool
  Map<String, CommentReactionsResponse?> commentReactions =
      {}; // commentId -> reactions
  Map<String, bool> showReplies = {}; // commentId -> bool

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadComments();
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

  Future<void> _loadComments() async {
    setState(() => isLoading = true);
    try {
      final response = await PostService.getComments(postId: widget.post.id);
      setState(() {
        comments = response.comments;
        isLoading = false;
      });

      // Load user reactions and comment reactions for all comments in parallel
      await Future.wait([
        ...comments.map((comment) => _loadUserReaction(comment.id)),
        ...comments.map((comment) => _loadCommentReactions(comment.id)),
      ]);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load comments: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserReaction(String commentId) async {
    try {
      final reaction = await PostService.getUserReaction(commentId);
      if (mounted) {
        setState(() {
          userReactions[commentId] = reaction?.reactionType;
        });
      }
    } catch (e) {
      print('Error loading user reaction for comment $commentId: $e');
    }
  }

  Future<void> _loadCommentReactions(String commentId) async {
    try {
      final reactions = await PostService.getReactions(commentId: commentId);
      print(
        'Reactions loaded for $commentId: total=${reactions.total}, counts=${reactions.counts}',
      );
      if (mounted) {
        setState(() {
          commentReactions[commentId] = reactions;
        });
      }
    } catch (e) {
      print('Error loading reactions for comment $commentId: $e');
    }
  }

  Future<void> _handleReaction(String commentId, String reactionType) async {
    final currentReaction = userReactions[commentId];

    try {
      if (currentReaction == reactionType) {
        // Remove reaction if same type clicked
        await PostService.removeReaction(commentId);
        setState(() {
          userReactions[commentId] = null;
          showReactionPicker[commentId] = false;
        });
      } else {
        // Add or update reaction
        await PostService.addOrUpdateReaction(
          commentId: commentId,
          reactionType: reactionType,
        );
        setState(() {
          userReactions[commentId] = reactionType;
          showReactionPicker[commentId] = false;
        });
      }

      // Reload reactions to get updated counts
      await _loadCommentReactions(commentId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update reaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleReactionPicker(String commentId) {
    setState(() {
      showReactionPicker[commentId] = !(showReactionPicker[commentId] ?? false);
    });
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a comment')));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await PostService.addComment(
        postId: widget.post.id,
        content: content,
        imageFile: _selectedImage,
      );

      // Clear the input fields
      _commentController.clear();
      setState(() => _selectedImage = null);

      setState(() => isSubmitting = false);

      // Mark that comments were added
      _commentsAdded = true;

      // Reload comments from server to get the latest list
      await _loadComments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Hide keyboard
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: $e'),
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

  void _showImageViewer(String imageUrl, String commentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleImageViewer(
          imageUrl: imageUrl,
          heroTag: 'comment_image_$commentId',
        ),
      ),
    );
  }

  Future<void> _deleteComment(Comment comment, int index) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Comment'),
          content: Text(
            'Are you sure you want to delete this comment? This action cannot be undone.',
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
      ).showSnackBar(SnackBar(content: Text('Deleting comment...')));

      // Call the delete API
      final success = await PostService.deleteComment(comment.id);

      if (success) {
        // Remove comment from local list
        setState(() {
          comments.removeAt(index);
        });

        // Mark that comments were modified
        _commentsAdded = true;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pop(_commentsAdded);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Comments'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_commentsAdded);
            },
          ),
        ),
        body: Column(
          children: [
            // Post summary
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Don't navigate to profile if it's the current user
                      if (currentUserId != widget.post.authorId) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OtherUserProfilePage(
                              userId: widget.post.authorId,
                              userName: widget.post.authorName,
                            ),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      backgroundImage: widget.post.authorProfileImage != null
                          ? NetworkImage(widget.post.authorProfileImage!)
                          : null,
                      child: widget.post.authorProfileImage == null
                          ? Text(
                              widget.post.authorName[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Don't navigate to profile if it's the current user
                            if (currentUserId != widget.post.authorId) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherUserProfilePage(
                                    userId: widget.post.authorId,
                                    userName: widget.post.authorName,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            widget.post.authorName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.post.content,
                          style: TextStyle(color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Comments list
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.comment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Be the first to comment!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadComments,
                      child: ListView.separated(
                        padding: EdgeInsets.all(16),
                        itemCount: comments.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        // Don't navigate to profile if it's the current user
                                        if (currentUserId != comment.userId) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OtherUserProfilePage(
                                                    userId: comment.userId,
                                                    userName: comment.userName,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.grey[400],
                                        backgroundImage:
                                            comment.userProfileImage != null
                                            ? NetworkImage(
                                                comment.userProfileImage!,
                                              )
                                            : null,
                                        child: comment.userProfileImage == null
                                            ? Text(
                                                comment.userName[0]
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              // Don't navigate to profile if it's the current user
                                              if (currentUserId !=
                                                  comment.userId) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        OtherUserProfilePage(
                                                          userId:
                                                              comment.userId,
                                                          userName:
                                                              comment.userName,
                                                        ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text(
                                              comment.userName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatTime(comment.createdAt),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (currentUserId == comment.userId ||
                                        currentUserId == widget.post.authorId)
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        onSelected: (value) {
                                          if (value == 'delete') {
                                            _deleteComment(comment, index);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.red,
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
                                Text(comment.content),
                                if (comment.image != null) ...[
                                  SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _showImageViewer(
                                      comment.image!,
                                      comment.id,
                                    ),
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth: 200,
                                        maxHeight: 150,
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
                                              comment.image!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      width: 200,
                                                      height: 150,
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
                                            // Subtle overlay to indicate it's tappable
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Container(
                                                padding: EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.zoom_in,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // Reaction and Reply actions
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Reaction button
                                    InkWell(
                                      onTap: () =>
                                          _toggleReactionPicker(comment.id),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              userReactions[comment.id] != null
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color:
                                                userReactions[comment.id] !=
                                                    null
                                                ? Colors.blue
                                                : Colors.grey[400]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.thumb_up_outlined,
                                              size: 14,
                                              color:
                                                  userReactions[comment.id] !=
                                                      null
                                                  ? Colors.blue
                                                  : Colors.grey[600],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'React',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    userReactions[comment.id] !=
                                                        null
                                                    ? Colors.blue
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),

                                    // Reply button
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          showReplies[comment.id] =
                                              !(showReplies[comment.id] ??
                                                  false);
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: showReplies[comment.id] == true
                                              ? Colors.grey.withOpacity(0.1)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color:
                                                showReplies[comment.id] == true
                                                ? Colors.grey[700]!
                                                : Colors.grey[400]!,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.reply_outlined,
                                              size: 14,
                                              color:
                                                  showReplies[comment.id] ==
                                                      true
                                                  ? Colors.grey[700]
                                                  : Colors.grey[600],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Reply',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    showReplies[comment.id] ==
                                                        true
                                                    ? Colors.grey[700]
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),

                                    // Reaction count badge (Facebook-style)
                                    if ((commentReactions[comment.id]?.total ??
                                            comment.reactionCount) >
                                        0)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Show actual reaction emojis if data is loaded
                                            if (commentReactions[comment.id] !=
                                                null) ...[
                                              ...commentReactions[comment.id]!
                                                  .counts
                                                  .entries
                                                  .where((e) => e.value > 0)
                                                  .take(3)
                                                  .map((entry) {
                                                    final emojis = {
                                                      'like': '👍',
                                                      'love': '❤️',
                                                      'haha': '😄',
                                                      'wow': '😮',
                                                      'sad': '😢',
                                                      'angry': '😠',
                                                    };
                                                    return Text(
                                                      emojis[entry.key] ?? '👍',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    );
                                                  }),
                                            ] else
                                              // Show default thumbs up if data not loaded yet
                                              Text(
                                                '👍',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            SizedBox(width: 4),
                                            Text(
                                              '${commentReactions[comment.id]?.total ?? comment.reactionCount}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    SizedBox(width: 12),

                                    // Reply count badge
                                    if (comment.replyCount > 0)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.comment_outlined,
                                              size: 12,
                                              color: Colors.grey[700],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '${comment.replyCount}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),

                                // Reaction picker overlay
                                if (showReactionPicker[comment.id] == true) ...[
                                  SizedBox(height: 8),
                                  CommentReactionPicker(
                                    currentReaction: userReactions[comment.id],
                                    onReactionSelected: (reactionType) {
                                      _handleReaction(comment.id, reactionType);
                                    },
                                  ),
                                ],

                                // Display reactions
                                if (commentReactions[comment.id] != null &&
                                    commentReactions[comment.id]!.total >
                                        0) ...[
                                  SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: commentReactions[comment.id]!
                                        .counts
                                        .entries
                                        .where((entry) => entry.value > 0)
                                        .map((entry) {
                                          return ReactionDisplay(
                                            reactionType: entry.key,
                                            count: entry.value,
                                            isUserReaction:
                                                userReactions[comment.id] ==
                                                entry.key,
                                            onTap: () {
                                              _handleReaction(
                                                comment.id,
                                                entry.key,
                                              );
                                            },
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],

                                // Replies widget
                                CommentRepliesWidget(
                                  commentId: comment.id,
                                  initialReplyCount: comment.replyCount,
                                  autoExpand: showReplies[comment.id] ?? false,
                                  onReplyAdded: _loadComments,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),

            // Comment input
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  // Image preview
                  if (_selectedImage != null) ...[
                    Container(
                      height: 120,
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
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image, size: 40),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                padding: EdgeInsets.all(4),
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

                  // Comment input
                  Row(
                    children: [
                      // Image picker button
                      IconButton(
                        icon: Icon(Icons.image, color: Colors.grey[700]),
                        onPressed: () async {
                          final image = await _imagePicker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setState(() => _selectedImage = image);
                          }
                        },
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: isSubmitting ? null : _addComment,
                          icon: isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
