import 'package:flutter/material.dart';

import '../models/models.dart';

/// Card widget for displaying a post comment
class CommentCard extends StatelessWidget {
  final PostComment comment;
  final String currentUserId;
  final Function(String) onLikeToggled;
  final Function(String)? onEdit;
  final Function(String)? onDelete;
  final Function(String)? onReport;
  
  const CommentCard({
    Key? key,
    required this.comment,
    required this.currentUserId,
    required this.onLikeToggled,
    this.onEdit,
    this.onDelete,
    this.onReport,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final bool isAuthor = comment.userId == currentUserId;
    
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(
                    comment.userDisplayName[0],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userDisplayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDate(comment.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isAuthor || onReport != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) {
                        onEdit!(comment.commentId);
                      } else if (value == 'delete' && onDelete != null) {
                        onDelete!(comment.commentId);
                      } else if (value == 'report' && onReport != null) {
                        onReport!(comment.commentId);
                      }
                    },
                    itemBuilder: (context) => [
                      if (isAuthor && onEdit != null)
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                      if (isAuthor && onDelete != null)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      if (!isAuthor && onReport != null)
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Text('Report'),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: () => onLikeToggled(comment.commentId),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          comment.isLikedBy(currentUserId) 
                              ? Icons.favorite 
                              : Icons.favorite_border,
                          size: 16,
                          color: comment.isLikedBy(currentUserId) 
                              ? Colors.red 
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          comment.likes.length.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                if (comment.isEdited) ...[
                  const Spacer(),
                  Text(
                    'Edited',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    // Simple date formatting
    return '${date.day}/${date.month}/${date.year}';
  }
}