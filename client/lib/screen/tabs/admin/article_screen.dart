import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'sub-pages/upload_article.dart';
import 'sub-pages/view_article_page.dart';
import 'sub-pages/notification_page.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  List<dynamic> _articles = [];
  List<dynamic> _filteredArticles = [];

  bool _isLoading = true;
  String _statusFilter = 'All';
  String _keyword = '';
  DateTime? _selectedDate;

  final _statusOptions = ['All', 'Published', 'Draft'];
  static const themeColor = Color(0xFFB36CC6);

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    try {
      final res = await http.get(
        Uri.parse('https://janna-server.onrender.com/api/articles'),
      );
      if (res.statusCode == 200) {
        final List<dynamic> articles = json.decode(res.body);
        setState(() {
          _articles = articles;
          _filteredArticles = articles;
          _isLoading = false;
        });
      } else {
        print("Failed to load articles: ${res.body}");
      }
    } catch (e) {
      print("Error fetching articles: $e");
    }
  }

  Future<void> getArticleById(BuildContext context, int id) async {
    try {
      final res = await http.get(
        Uri.parse('https://janna-server.onrender.com/api/articles/$id'),
      );
      if (res.statusCode == 200) {
        final article = json.decode(res.body);
        print("Article by ID ($id): $article");

        // ✅ Navigate to the ViewArticleScreen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewArticleScreen(articleId: id),
          ),
        );
      } else {
        print("Failed to get article: ${res.body}");
      }
    } catch (e) {
      print("Error getting article by ID: $e");
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredArticles = _articles.where((article) {
        final title = article['title']?.toLowerCase() ?? '';
        final content = article['content']?.toLowerCase() ?? '';
        final status = article['status'] ?? '';
        final createdAt = article['createdAt'];

        final matchKeyword =
            _keyword.isEmpty ||
            title.contains(_keyword.toLowerCase()) ||
            content.contains(_keyword.toLowerCase());

        final matchStatus =
            _statusFilter.toLowerCase() == 'all' ||
            status.toLowerCase() == _statusFilter.toLowerCase();

        final matchDate =
            _selectedDate == null ||
            (createdAt != null &&
                DateFormat('yyyy-MM-dd').format(DateTime.parse(createdAt)) ==
                    DateFormat('yyyy-MM-dd').format(_selectedDate!));

        return matchKeyword && matchStatus && matchDate;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _keyword = '';
      _selectedDate = null;
      _statusFilter = 'All';
    });
    _applyFilters();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Articles",
          style: TextStyle(
            fontFamily: 'Sahitya', // ✅ Custom font
            fontWeight: FontWeight.w700, // ✅ Bold weight
            fontSize: 22, // optional, looks better for title
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(
          0xFFB36CC6,
        ), // ✅ same as your footer tabs color
        foregroundColor: Colors.white, // for title and icons
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          _keyword = value;
                          _applyFilters();
                        },
                        decoration: const InputDecoration(
                          hintText: 'Search by keyword...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: _resetFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Filter by date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? DateFormat('MMMM d, y').format(_selectedDate!)
                                : 'Select date',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        items: _statusOptions
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        style: const TextStyle(color: Colors.black87),
                        onChanged: (value) {
                          setState(() => _statusFilter = value!);
                          _applyFilters();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Filter by status',
                          prefixIcon: Icon(Icons.filter_alt),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredArticles.isEmpty
                ? const Center(
                    child: Text(
                      "No articles found",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredArticles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final article = _filteredArticles[index];
                      return GestureDetector(
                        onTap: () {
                          final id = article['article_id'];
                          if (id != null) {
                            getArticleById(context, id);
                          } else {
                            print("Article ID is null for article: $article");
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                article['excerpt'] ?? 'No excerpt available.',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (article['content'] != null)
                                Text(
                                  article['content'],
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Status: ${article['status'] ?? 'Unknown'}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.comment,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${article['comment_count'] ?? 0}",
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(
                                        Icons.favorite,
                                        size: 16,
                                        color: const Color(0xFFB36CC6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${article['like_count'] ?? 0}",
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddArticleScreen()),
          );
        },
        backgroundColor: themeColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
