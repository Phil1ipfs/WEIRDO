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

//         // ✅ Show snackbar only if user performed a refresh
//         if (ScaffoldMessenger.of(context).mounted) {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text('Article refreshed!')));
//         }
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

//   Future<void> _confirmDeleteArticle() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Article'),
//         content: const Text('Are you sure you want to delete this article?'),
//         actions: [
//           TextButton(
//             child: const Text('Cancel'),
//             onPressed: () => Navigator.of(context).pop(false),
//           ),
//           TextButton(
//             child: const Text('Delete', style: TextStyle(color: Colors.red)),
//             onPressed: () => Navigator.of(context).pop(true),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       await _deleteArticle();
//     }
//   }

//   Future<void> _deleteArticle() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');

//       if (token == null) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('User not logged in')));
//         return;
//       }

//       final response = await http.delete(
//         Uri.parse('https://janna-server.onrender.com/api/articles/${widget.articleId}'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Article deleted successfully!')),
//         );
//         Navigator.pop(context);
//       } else {
//         final body = jsonDecode(response.body);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(body['message'] ?? 'Failed to delete article'),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error deleting article: $e')));
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
//           : RefreshIndicator(
//               onRefresh: fetchArticle, // ✅ Pull-to-refresh reload
//               color: const Color(0xFFB36CC6),
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ClipRRect(
//                       borderRadius: const BorderRadius.only(
//                         bottomLeft: Radius.circular(12),
//                         bottomRight: Radius.circular(12),
//                       ),
//                       child: Image.asset(
//                         'assets/images/banner.png',
//                         height: 200,
//                         width: double.infinity,
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             article!['title'] ?? 'Untitled',
//                             style: const TextStyle(
//                               fontFamily: 'Poppins',
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Row(
//                             children: [
//                               const Icon(
//                                 Icons.access_time,
//                                 size: 16,
//                                 color: Colors.grey,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 formatDate(article!['updatedAt']),
//                                 style: const TextStyle(
//                                   fontFamily: 'Poppins',
//                                   fontSize: 13,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey.shade200,
//                                   borderRadius: BorderRadius.circular(6),
//                                 ),
//                                 child: Text(
//                                   article!['status'] ?? 'Unknown',
//                                   style: const TextStyle(
//                                     fontFamily: 'Poppins',
//                                     fontSize: 12,
//                                     fontStyle: FontStyle.italic,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 10),
//                           Text(
//                             article!['content'] ?? '',
//                             style: const TextStyle(
//                               fontFamily: 'Sahitya',
//                               fontSize: 17,
//                               height: 1.7,
//                               color: Colors.black87,
//                             ),
//                           ),

//                           // ✅ Display source link if available
//                           if (article!['link'] != null &&
//                               article!['link'].toString().isNotEmpty)
//                             Padding(
//                               padding: const EdgeInsets.only(
//                                 top: 16.0,
//                                 bottom: 8,
//                               ),
//                               child: GestureDetector(
//                                 onTap: () => _openSourceLink(article!['link']),
//                                 child: Text(
//                                   "Source: ${article!['link']}",
//                                   style: const TextStyle(
//                                     fontFamily: 'Poppins',
//                                     color: Color(0xFFB36CC6),
//                                     decoration: TextDecoration.underline,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ),
//                             ),

//                           const SizedBox(height: 30),
//                           const Text(
//                             'Comments',
//                             style: TextStyle(
//                               fontFamily: 'Poppins',
//                               fontWeight: FontWeight.w600,
//                               fontSize: 18,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           ...(article!['comments'] as List<dynamic>).map((
//                             comment,
//                           ) {
//                             final name = (comment['fullName'] ?? 'Unknown User')
//                                 .toString();
//                             return GestureDetector(
//                               onLongPress: () async {
//                                 final confirm = await showDialog<bool>(
//                                   context: context,
//                                   builder: (context) => AlertDialog(
//                                     title: const Text("Delete Comment"),
//                                     content: const Text(
//                                       "Are you sure you want to delete this comment?",
//                                     ),
//                                     actions: [
//                                       TextButton(
//                                         child: const Text("Cancel"),
//                                         onPressed: () =>
//                                             Navigator.of(context).pop(false),
//                                       ),
//                                       TextButton(
//                                         child: const Text(
//                                           "Delete",
//                                           style: TextStyle(color: Colors.red),
//                                         ),
//                                         onPressed: () =>
//                                             Navigator.of(context).pop(true),
//                                       ),
//                                     ],
//                                   ),
//                                 );

//                                 if (confirm == true) {
//                                   await deleteComment(
//                                     comment['comment_id'].toString(),
//                                   );
//                                 }
//                               },
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 10.0,
//                                 ),
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Icon(
//                                       Icons.account_circle,
//                                       size: 32,
//                                       color: Colors.grey,
//                                     ),
//                                     const SizedBox(width: 10),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             name,
//                                             style: const TextStyle(
//                                               fontWeight: FontWeight.w600,
//                                               fontFamily: 'Poppins',
//                                               fontSize: 15,
//                                             ),
//                                           ),
//                                           const SizedBox(height: 4),
//                                           Text(
//                                             comment['content'] ?? '',
//                                             style: const TextStyle(
//                                               fontFamily: 'Poppins',
//                                             ),
//                                           ),
//                                           const SizedBox(height: 4),
//                                           Text(
//                                             formatDate(comment['createdAt']),
//                                             style: const TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.grey,
//                                               fontFamily: 'Poppins',
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                           const SizedBox(height: 20),
//                           const Text(
//                             'Add a Comment',
//                             style: TextStyle(
//                               fontFamily: 'Poppins',
//                               fontWeight: FontWeight.w600,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           TextField(
//                             controller: commentController,
//                             maxLines: 3,
//                             decoration: const InputDecoration(
//                               hintText: 'Write your comment here...',
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           ElevatedButton(
//                             onPressed: submitComment,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Color(0xFFB36CC6),
//                             ),
//                             child: const Text('Submit'),
//                           ),
//                           const SizedBox(height: 40),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
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
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Article refreshed!')));
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
    } catch (e) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted successfully!')),
        );
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message'] ?? 'Failed to post comment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting comment: $e')));
    }
  }

  Future<void> _confirmDeleteArticle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: const Text('Are you sure you want to delete this article?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteArticle();
    }
  }

  Future<void> _deleteArticle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        return;
      }

      final response = await http.delete(
        Uri.parse('https://janna-server.onrender.com/api/articles/${widget.articleId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article deleted successfully!')),
        );
        Navigator.pop(context);
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Failed to delete article'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting article: $e')));
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
            color: Colors.white,
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
              displacement: 40,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
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
                                padding: const EdgeInsets.only(top: 16.0),
                                child: GestureDetector(
                                  onTap: () =>
                                      _openSourceLink(article!['link']),
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
                              final name =
                                  (comment['fullName'] ?? 'Unknown User')
                                      .toString();
                              return GestureDetector(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            Text(
                                              formatDate(comment['createdAt']),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
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
                    ),
                  );
                },
              ),
            ),
    );
  }
}
