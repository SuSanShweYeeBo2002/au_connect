import 'package:flutter/material.dart';

class CommentReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;
  final String? currentReaction;

  const CommentReactionPicker({
    Key? key,
    required this.onReactionSelected,
    this.currentReaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reactions = [
      {'type': 'like', 'emoji': '👍', 'label': 'Like'},
      {'type': 'love', 'emoji': '❤️', 'label': 'Love'},
      {'type': 'haha', 'emoji': '😄', 'label': 'Haha'},
      {'type': 'wow', 'emoji': '😮', 'label': 'Wow'},
      {'type': 'sad', 'emoji': '😢', 'label': 'Sad'},
      {'type': 'angry', 'emoji': '😠', 'label': 'Angry'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((reaction) {
          final isSelected = currentReaction == reaction['type'];
          return GestureDetector(
            onTap: () => onReactionSelected(reaction['type'] as String),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reaction['emoji'] as String,
                    style: TextStyle(fontSize: 24),
                  ),
                  if (isSelected) ...[
                    SizedBox(height: 2),
                    Text(
                      reaction['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Reaction display widget for showing a single reaction type
class ReactionDisplay extends StatelessWidget {
  final String reactionType;
  final int count;
  final bool isUserReaction;
  final VoidCallback? onTap;

  const ReactionDisplay({
    Key? key,
    required this.reactionType,
    required this.count,
    this.isUserReaction = false,
    this.onTap,
  }) : super(key: key);

  String _getEmoji(String type) {
    switch (type) {
      case 'like':
        return '👍';
      case 'love':
        return '❤️';
      case 'haha':
        return '😄';
      case 'wow':
        return '😮';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      default:
        return '👍';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isUserReaction
              ? Colors.blue.withOpacity(0.2)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: isUserReaction
              ? Border.all(color: Colors.blue, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getEmoji(reactionType), style: TextStyle(fontSize: 16)),
            SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isUserReaction
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isUserReaction ? Colors.blue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
