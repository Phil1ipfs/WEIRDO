// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart'; // ✅ added for clickable link

// class ViewArticleScreen extends StatefulWidget {
//   final int articleId;

//   const ViewArticleScreen({super.key, required this.articleId});

//   @override
//   State<ViewArticleScreen> createState() => _ViewArticleScreenState();
// }

// class _ViewArticleScreenState extends State<ViewArticleScreen> {
//   Map<String, dynamic>? article;
//   bool isLoading = true;
//   String? error;
//   final TextEditingController commentController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     fetchArticle();
//   }

//   Future<void> fetchArticle() async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final response = await http.get(
//         Uri.parse('https://janna-server.onrender.com/api/articles/${widget.articleId}'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Cache-Control': 'no-cache',
//         },
//       );

//       if (response.statusCode == 200 || response.statusCode == 304) {
//         setState(() {
//           article = json.decode(response.body);
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           error = 'Failed to load article';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         error = 'Something went wrong: $e';
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> deleteComment(String commentId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');

//     final response = await http.delete(
//       Uri.parse('https://janna-server.onrender.com/api/articles/comment/$commentId'),
//       headers: {'Authorization': '$token'},
//     );

//     if (response.statusCode == 200) {
//       setState(() {
//         article!['comments'] = (article!['comments'] as List)
//             .where((c) => c['comment_id'].toString() != commentId)
//             .toList();
//       });
//     } else {
//       final body = jsonDecode(response.body);
//       _showError(body['message'] ?? 'Failed to delete comment');
//     }
//   }

//   String formatDate(String? dateStr) {
//     if (dateStr == null) return '';
//     try {
//       final dt = DateTime.parse(dateStr);
//       return DateFormat('MMMM dd, yyyy – hh:mm a').format(dt);
//     } catch (e) {
//       return '';
//     }
//   }

//   Future<void> submitComment() async {
//     final comment = commentController.text.trim();
//     if (comment.isEmpty) return;

//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');

//     if (token == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('User not logged in')));
//       return;
//     }

//     try {
//       final response = await http.post(
//         Uri.parse('https://janna-server.onrender.com/api/articles/comment'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode({'article_id': widget.articleId, 'comment': comment}),
//       );

//       if (response.statusCode == 201) {
//         commentController.clear();
//         await fetchArticle();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Comment posted successfully!')),
//         );
//       } else {
//         final body = jsonDecode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(body['message'] ?? 'Failed to post comment')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error submitting comment: $e')));
//     }
//   }

//   void _showError(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ✅ open external link
//   Future<void> _openSourceLink(String url) async {
//     final uri = Uri.tryParse(url);
//     if (uri != null && await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Invalid or unreachable link')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9F9F9),
//       appBar: AppBar(
//         title: const Text(
//           'Article Details',
//           style: TextStyle(
//             fontFamily: 'Sahitya',
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFFB36CC6),
//         elevation: 1,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : error != null
//           ? Center(
//               child: Text(
//                 error!,
//                 style: const TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 16,
//                   color: Color(0xFFB36CC6),
//                 ),
//               ),
//             )
//           : article == null
//           ? const Center(
//               child: Text(
//                 'No data available.',
//                 style: TextStyle(fontFamily: 'Poppins'),
//               ),
//             )
//           : SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                     borderRadius: const BorderRadius.only(
//                       bottomLeft: Radius.circular(12),
//                       bottomRight: Radius.circular(12),
//                     ),
//                     child: Image.asset(
//                       'assets/images/banner.png',
//                       height: 200,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           article!['title'] ?? 'Untitled',
//                           style: const TextStyle(
//                             fontFamily: 'Poppins',
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           children: [
//                             const Icon(
//                               Icons.access_time,
//                               size: 16,
//                               color: Colors.grey,
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               formatDate(article!['updatedAt']),
//                               style: const TextStyle(
//                                 fontFamily: 'Poppins',
//                                 fontSize: 13,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.shade200,
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                               child: Text(
//                                 article!['status'] ?? 'Unknown',
//                                 style: const TextStyle(
//                                   fontFamily: 'Poppins',
//                                   fontSize: 12,
//                                   fontStyle: FontStyle.italic,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           article!['content'] ?? '',
//                           style: const TextStyle(
//                             fontFamily: 'Sahitya',
//                             fontSize: 17,
//                             height: 1.7,
//                             color: Colors.black87,
//                           ),
//                         ),

//                         // ✅ Display source link if available
//                         if (article!['link'] != null &&
//                             article!['link'].toString().isNotEmpty)
//                           Padding(
//                             padding: const EdgeInsets.only(
//                               top: 16.0,
//                               bottom: 8,
//                             ),
//                             child: GestureDetector(
//                               onTap: () => _openSourceLink(article!['link']),
//                               child: Text(
//                                 "Source: ${article!['link']}",
//                                 style: const TextStyle(
//                                   fontFamily: 'Poppins',
//                                   color: Color(0xFFB36CC6),
//                                   decoration: TextDecoration.underline,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ),
//                           ),

//                         const SizedBox(height: 30),
//                         const Text(
//                           'Comments',
//                           style: TextStyle(
//                             fontFamily: 'Poppins',
//                             fontWeight: FontWeight.w600,
//                             fontSize: 18,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         ...(article!['comments'] as List<dynamic>).map((
//                           comment,
//                         ) {
//                           final name = (comment['fullName'] ?? 'Unknown User')
//                               .toString();
//                           return GestureDetector(
//                             onLongPress: () async {
//                               final confirm = await showDialog<bool>(
//                                 context: context,
//                                 builder: (context) => AlertDialog(
//                                   title: const Text("Delete Comment"),
//                                   content: const Text(
//                                     "Are you sure you want to delete this comment?",
//                                   ),
//                                   actions: [
//                                     TextButton(
//                                       child: const Text("Cancel"),
//                                       onPressed: () =>
//                                           Navigator.of(context).pop(false),
//                                     ),
//                                     TextButton(
//                                       child: const Text(
//                                         "Delete",
//                                         style: TextStyle(color: Colors.red),
//                                       ),
//                                       onPressed: () =>
//                                           Navigator.of(context).pop(true),
//                                     ),
//                                   ],
//                                 ),
//                               );

//                               if (confirm == true) {
//                                 await deleteComment(
//                                   comment['comment_id'].toString(),
//                                 );
//                               }
//                             },
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 vertical: 10.0,
//                               ),
//                               child: Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Icon(
//                                     Icons.account_circle,
//                                     size: 32,
//                                     color: Colors.grey,
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           name,
//                                           style: const TextStyle(
//                                             fontWeight: FontWeight.w600,
//                                             fontFamily: 'Poppins',
//                                             fontSize: 15,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           comment['content'] ?? '',
//                                           style: const TextStyle(
//                                             fontFamily: 'Poppins',
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           formatDate(comment['createdAt']),
//                                           style: const TextStyle(
//                                             fontSize: 12,
//                                             color: Colors.grey,
//                                             fontFamily: 'Poppins',
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                         const SizedBox(height: 20),
//                         const Text(
//                           'Add a Comment',
//                           style: TextStyle(
//                             fontFamily: 'Poppins',
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         TextField(
//                           controller: commentController,
//                           maxLines: 3,
//                           decoration: const InputDecoration(
//                             hintText: 'Write your comment here...',
//                             border: OutlineInputBorder(),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         ElevatedButton(
//                           onPressed: submitComment,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Color(0xFFB36CC6),
//                           ),
//                           child: const Text('Submit'),
//                         ),
//                         const SizedBox(height: 40),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewArticleScreen extends StatefulWidget {
  final int articleId;

  const ViewArticleScreen({super.key, required this.articleId});

  @override
  State<ViewArticleScreen> createState() => _ViewArticleScreenState();
}

class _ViewArticleScreenState extends State<ViewArticleScreen> {
  Map<String, dynamic>? article;
  bool isLoading = true;
  String? error;
  final TextEditingController commentController = TextEditingController();

  // Reply state
  int? _replyingToCommentId;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchArticle();
  }

  Future<void> fetchArticle() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://janna-server.onrender.com/api/articles/${widget.articleId}'),
        headers: {
          'Content-Type': 'application/json',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 304) {
        setState(() {
          article = json.decode(response.body);
          isLoading = false;
          error = null;
        });

        // ✅ Optional success snackbar (only for manual refresh)
        if (ScaffoldMessenger.of(context).mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article refreshed successfully!')),
          );
        }
      } else {
        setState(() {
          error = 'Failed to load article';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Something went wrong: $e';
        isLoading = false;
      });
    }
  }

  Future<void> deleteComment(String commentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('https://janna-server.onrender.com/api/articles/comment/$commentId'),
      headers: {'Authorization': '$token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        article!['comments'] = (article!['comments'] as List)
            .where((c) => c['comment_id'].toString() != commentId)
            .toList();
      });
    } else {
      final body = jsonDecode(response.body);
      _showError(body['message'] ?? 'Failed to delete comment');
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMMM dd, yyyy – hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  Future<void> submitComment() async {
    final comment = commentController.text.trim();
    if (comment.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://janna-server.onrender.com/api/articles/comment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'article_id': widget.articleId, 'comment': comment}),
      );

      if (response.statusCode == 201) {
        commentController.clear();
        await fetchArticle();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment posted successfully!')),
          );
        }
      } else {
        final body = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['message'] ?? 'Failed to post comment')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting comment: $e')));
      }
    }
  }

  Future<void> submitReply(int parentId) async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
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
          'comment': reply,
          'parent_id': parentId,
        }),
      );

      if (response.statusCode == 201) {
        _replyController.clear();
        setState(() => _replyingToCommentId = null);
        await fetchArticle();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reply posted successfully!')),
          );
        }
      } else {
        final body = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['message'] ?? 'Failed to post reply')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting reply: $e')),
        );
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSourceLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or unreachable link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Article Details',
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFFB36CC6),
        foregroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Text(
                error!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Color(0xFFB36CC6),
                ),
              ),
            )
          : article == null
          ? const Center(
              child: Text(
                'No data available.',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchArticle,
              color: const Color(0xFFB36CC6),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/banner.png',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article!['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatDate(article!['updatedAt']),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  article!['status'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            article!['content'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Sahitya',
                              fontSize: 17,
                              height: 1.7,
                              color: Colors.black87,
                            ),
                          ),
                          if (article!['link'] != null &&
                              article!['link'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16.0,
                                bottom: 8,
                              ),
                              child: GestureDetector(
                                onTap: () => _openSourceLink(article!['link']),
                                child: Text(
                                  "Source: ${article!['link']}",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFFB36CC6),
                                    decoration: TextDecoration.underline,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 30),
                          const Text(
                            'Comments',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...(article!['comments'] as List<dynamic>).map((
                            comment,
                          ) {
                            final name = (comment['fullName'] ?? 'Unknown User')
                                .toString();
                            final commentId = comment['comment_id'] as int;
                            final replies = (comment['replies'] as List<dynamic>?) ?? [];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onLongPress: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Delete Comment"),
                                        content: const Text(
                                          "Are you sure you want to delete this comment?",
                                        ),
                                        actions: [
                                          TextButton(
                                            child: const Text("Cancel"),
                                            onPressed: () =>
                                                Navigator.of(context).pop(false),
                                          ),
                                          TextButton(
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(color: Colors.red),
                                            ),
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await deleteComment(
                                        comment['comment_id'].toString(),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.account_circle,
                                          size: 32,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment['content'] ?? '',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Text(
                                                    formatDate(comment['createdAt']),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _replyingToCommentId = commentId;
                                                      });
                                                    },
                                                    child: const Text(
                                                      'Reply',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Color(0xFFB36CC6),
                                                        fontWeight: FontWeight.w600,
                                                        fontFamily: 'Poppins',
                                                      ),
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
                                ),

                                // Show reply input if this comment is being replied to
                                if (_replyingToCommentId == commentId) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(left: 42, top: 8, bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: _replyController,
                                          maxLines: 2,
                                          decoration: const InputDecoration(
                                            hintText: 'Write your reply...',
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.all(8),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _replyingToCommentId = null;
                                                  _replyController.clear();
                                                });
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () => submitReply(commentId),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFB36CC6),
                                              ),
                                              child: const Text(
                                                'Post Reply',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Display replies
                                ...replies.map((reply) {
                                  final replyName = (reply['fullName'] ?? 'Unknown User').toString();
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 42, top: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.subdirectory_arrow_right,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.account_circle,
                                          size: 28,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                replyName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                reply['content'] ?? '',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                formatDate(reply['createdAt']),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            );
                          }),
                          const SizedBox(height: 20),
                          const Text(
                            'Add a Comment',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: commentController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Write your comment here...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: submitComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFB36CC6),
                            ),
                            child: const Text('Submit'),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
