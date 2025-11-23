import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'sub-pages/view_article_page.dart';
import 'sub-pages/upload_article.dart';
import 'sub-pages/notification_page.dart';

class DoctorArticles extends StatefulWidget {
  const DoctorArticles({super.key});

  @override
  State<DoctorArticles> createState() => _DoctorArticlesState();
}

class _DoctorArticlesState extends State<DoctorArticles> {
  List articles = [];
  List<bool> liked = [];
  List<bool> commented = [];
  List<TextEditingController> commentControllers = [];

  List topics = [];
  String? selectedTopic;

  TextEditingController searchController = TextEditingController();
  final Color selectedColor = const Color(0xFFB36CC6);

  @override
  void initState() {
    super.initState();
    fetchArticles();
    fetchTopics();
  }

  Future<void> fetchArticles({String? slug}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String url = 'https://janna-server.onrender.com/api/articles/by-like';
    if (slug != null && slug.isNotEmpty) {
      url = '$url?slug=$slug';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json', 'Authorization': '$token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        articles = data;
        liked = data.map<bool>((item) => item['user_liked'] == 1).toList();
        commented = List.generate(data.length, (index) => false);
        commentControllers = List.generate(
          data.length,
          (_) => TextEditingController(),
        );
      });
    } else {
      _showError('Failed to load articles: ${response.statusCode}');
    }
  }

  // ✅ Fetch available topics (slugs)
  Future<void> fetchTopics() async {
    final response = await http.get(
      Uri.parse('https://janna-server.onrender.com/api/articles/slugs/list'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        topics = data;
      });
    } else {
      _showError('Failed to load topics');
    }
  }

  // ✅ Search articles
  Future<void> searchArticles(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('https://janna-server.onrender.com/api/articles/by-like?q=$query'),
      headers: {'Content-Type': 'application/json', 'Authorization': '$token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        articles = data;
        liked = data.map<bool>((item) => item['user_liked'] == 1).toList();
        commented = List.generate(data.length, (index) => false);
        commentControllers = List.generate(
          data.length,
          (_) => TextEditingController(),
        );
      });
    } else {
      _showError('Failed to search articles: ${response.statusCode}');
    }
  }

  // ✅ Like/Unlike Article
  Future<void> toggleLike(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final articleId = articles[index]['article_id'];

    final response = await http.post(
      Uri.parse('https://janna-server.onrender.com/api/articles/like'),
      headers: {'Content-Type': 'application/json', 'Authorization': '$token'},
      body: jsonEncode({'article_id': articleId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        liked[index] = data['liked'];
        articles[index]['like_count'] =
            (articles[index]['like_count'] ?? 0) + (data['liked'] ? 1 : -1);
      });
    } else {
      _showError('Failed to like article');
    }
  }

  // ✅ Post comment
  Future<void> submitComment(int index) async {
    final comment = commentControllers[index].text.trim();
    if (comment.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final articleId = articles[index]['article_id'];

    final response = await http.post(
      Uri.parse('https://janna-server.onrender.com/api/articles/comment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'article_id': articleId, 'comment': comment}),
    );

    if (response.statusCode == 201) {
      setState(() {
        final currentCount = articles[index]['comment_count'] ?? 0;
        articles[index]['comment_count'] = currentCount + 1;
        commentControllers[index].clear();
        commented[index] = false;
      });
    } else {
      final body = jsonDecode(response.body);
      _showError(body['message'] ?? 'Failed to post comment');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    for (var controller in commentControllers) {
      controller.dispose();
    }
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Doctor Dashboard",
          style: TextStyle(
            fontFamily: 'Sahitya',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: selectedColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // // ✅ Search Bar
          // Padding(
          //   padding: const EdgeInsets.all(12.0),
          //   child: TextField(
          //     controller: searchController,
          //     decoration: InputDecoration(
          //       hintText: 'Search articles...',
          //       prefixIcon: const Icon(Icons.search),
          //       filled: true,
          //       fillColor: Colors.white,
          //       contentPadding: const EdgeInsets.symmetric(
          //         horizontal: 16,
          //         vertical: 0,
          //       ),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(30),
          //         borderSide: BorderSide.none,
          //       ),
          //       suffixIcon: IconButton(
          //         icon: const Icon(Icons.clear),
          //         onPressed: () {
          //           searchController.clear();
          //           fetchArticles(); // reset list
          //         },
          //       ),
          //     ),
          //     onSubmitted: (value) => searchArticles(value),
          //   ),
          // ),
          // ✅ Search Bar with Search Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 🔍 Search Text Field
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search articles...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          fetchArticles(); // reset list
                        },
                      ),
                    ),
                    onSubmitted: (value) => searchArticles(value),
                  ),
                ),

                const SizedBox(width: 8),

                // 🔘 Search Button
                ElevatedButton(
                  onPressed: () {
                    final query = searchController.text.trim();
                    searchArticles(query);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.search),
                ),
              ],
            ),
          ),

          // ✅ Topic Chips
          if (topics.isNotEmpty)
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  final isSelected = selectedTopic == topic['slug'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(topic['slug']),
                      selected: isSelected,
                      selectedColor: selectedColor.withOpacity(0.8),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedTopic = isSelected
                              ? null
                              : topic['slug']; // toggle
                        });
                        fetchArticles(slug: selectedTopic);
                      },
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // ✅ Article List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final article = articles[index];

                return GestureDetector(
                  onTap: () async {
                    final shouldRefresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ViewArticleScreen(articleId: article['article_id']),
                      ),
                    );
                    if (shouldRefresh == true) fetchArticles();
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  article['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                article['createdAt']?.substring(0, 10) ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Content
                          Text(
                            article['content'] ?? '',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 12),

                          // Likes & Comments info
                          Row(
                            children: [
                              Icon(
                                Icons.thumb_up,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${article['like_count'] ?? 0} Likes",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.comment,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${article['comment_count'] ?? 0} Comments",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          // Like / Comment buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: liked[index]
                                        ? selectedColor
                                        : Colors.grey[700],
                                  ),
                                  onPressed: () => toggleLike(index),
                                  icon: Icon(
                                    liked[index]
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_alt_outlined,
                                    color: liked[index]
                                        ? selectedColor
                                        : Colors.grey[700],
                                  ),
                                  label: const Text("Like"),
                                ),
                              ),
                              Expanded(
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: commented[index]
                                        ? selectedColor
                                        : Colors.grey[700],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      commented[index] = !commented[index];
                                    });
                                  },
                                  icon: Icon(
                                    Icons.comment_outlined,
                                    color: commented[index]
                                        ? selectedColor
                                        : Colors.grey[700],
                                  ),
                                  label: const Text("Comment"),
                                ),
                              ),
                            ],
                          ),

                          // Comment input
                          if (commented[index])
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: commentControllers[index],
                                      decoration: InputDecoration(
                                        hintText: 'Write a comment...',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        fillColor: Colors.grey[200],
                                        filled: true,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.send,
                                      color: selectedColor,
                                    ),
                                    onPressed: () => submitComment(index),
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
          ),
        ],
      ),

      // ✅ Floating Add Article Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddArticleScreen()),
          );
        },
        backgroundColor: selectedColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
