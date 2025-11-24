# Comment Replies Implementation Guide

## Changes Needed in view_article_page.dart (all 3 versions)

### 1. Add State Variables

Add these to the State class:

```dart
int? _replyingToCommentId;
String? _replyingToUsername;
final TextEditingController _replyController = TextEditingController();
```

### 2. Update submitComment Method

Replace the existing `submitComment` method with this version that supports replies:

```dart
Future<void> submitComment({int? parentId}) async {
  final controller = parentId != null ? _replyController : commentController;
  final comment = controller.text.trim();
  if (comment.isEmpty) return;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) {
    _showError('Please login to comment');
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('https://janna-server.onrender.com/api/articles/comment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'article_id': widget.articleId,
        'comment': comment,
        if (parentId != null) 'parent_id': parentId,
      }),
    );

    if (response.statusCode == 201) {
      controller.clear();
      setState(() {
        _replyingToCommentId = null;
        _replyingToUsername = null;
      });
      fetchArticle();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parentId != null ? 'Reply posted!' : 'Comment posted successfully!')),
      );
    } else {
      final body = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['message'] ?? 'Failed to post comment')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error submitting comment: $e')),
    );
  }
}
```

### 3. Add Reply UI Widget

Add this method to build the reply input box:

```dart
Widget _buildReplyBox(int parentId, String username) {
  return Container(
    margin: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFB36CC6)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Replying to $username',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFB36CC6),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                setState(() {
                  _replyingToCommentId = null;
                  _replyingToUsername = null;
                  _replyController.clear();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _replyController,
          decoration: const InputDecoration(
            hintText: 'Write your reply...',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => submitComment(parentId: parentId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB36CC6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Post Reply'),
          ),
        ),
      ],
    ),
  );
}
```

### 4. Update Comment Display

Replace the comment display section with this recursive rendering:

```dart
Widget _buildCommentTree(List<dynamic> comments, {int? parentId, double leftPadding = 0}) {
  final filteredComments = comments.where((c) {
    final commentParentId = c['parent_id'];
    return (parentId == null && commentParentId == null) ||
           (commentParentId != null && commentParentId == parentId);
  }).toList();

  return Column(
    children: filteredComments.map((comment) {
      final commentId = comment['comment_id'];
      final username = (comment['fullName'] ?? 'Unknown User').toString();
      final isOwnComment = comment['user_id'] == userId;

      // Get replies for this comment
      final replies = comments.where((c) => c['parent_id'] == commentId).toList();

      return Container(
        margin: EdgeInsets.only(left: leftPadding, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment card
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: comment['profile_picture'] != null
                      ? NetworkImage('https://janna-server.onrender.com${comment['profile_picture']}')
                      : null,
                  child: comment['profile_picture'] == null
                      ? Text(username.substring(0, 1).toUpperCase())
                      : null,
                ),
                title: Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(comment['content']),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDate(comment['createdAt']),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        // Reply button
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _replyingToCommentId = commentId;
                              _replyingToUsername = username;
                            });
                          },
                          icon: const Icon(Icons.reply, size: 16),
                          label: const Text('Reply'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: isOwnComment
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(commentId.toString()),
                      )
                    : null,
              ),
            ),

            // Reply input box (if replying to this comment)
            if (_replyingToCommentId == commentId)
              _buildReplyBox(commentId, username),

            // Nested replies
            if (replies.isNotEmpty)
              _buildCommentTree(comments, parentId: commentId, leftPadding: leftPadding + 24),
          ],
        ),
      );
    }).toList(),
  );
}

// Helper method to format dates
String _formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  } catch (e) {
    return dateStr;
  }
}
```

### 5. Update the Comment Section in Build Method

Replace the existing comment section with:

```dart
// Comments Section
if (article!['comments'] != null && (article!['comments'] as List).isNotEmpty) ...[
  const Text(
    'Comments',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
  const SizedBox(height: 12),
  _buildCommentTree(article!['comments'] as List),
] else ...[
  const Text('No comments yet. Be the first to comment!'),
],
```

## Files to Update

Apply these changes to all 3 view_article_page.dart files:
1. `client/lib/screen/tabs/client/sub-pages/view_article_page.dart`
2. `client/lib/screen/tabs/doctor/sub-pages/view_article_page.dart`
3. `client/lib/screen/tabs/admin/sub-pages/view_article_page.dart`

## Testing

1. Login as any user
2. Navigate to an article
3. Post a comment
4. Click "Reply" on any comment
5. Submit a reply
6. Verify nested comment display

## Backend Support

The backend already fully supports comment replies:
- POST /api/articles/comment with `parent_id` field
- Comment model has `parent_id` foreign key
- Notifications sent for replies
