import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String DEFAULT_API_URL = 'https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=e8387ca389e144e49d488b4200051396';


class Article {
  final String id;
  final String title;
  final String content;
  final String fullText;
  final String source;
  final String imageUrl;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.fullText,
    required this.source,
    required this.imageUrl,
  });

  factory Article.fromJson(Map<String, dynamic> json, int index, String sourceName) {
    final String contentPreview = (json['description'] as String?) ?? 'لا يوجد وصف متاح.';
    final String fullTextContent = (json['content'] as String?) ?? contentPreview;

    return Article(
      id: (json['url'] as String?) ?? 'id_${index}',
      title: (json['title'] as String?) ?? 'عنوان غير متوفر',
      content: contentPreview,
      fullText: fullTextContent * 4,
      source: (json['source']['name'] as String?) ?? sourceName,
      imageUrl: (json['urlToImage'] as String?) ?? 'https://placehold.co/600x400/aaaaaa/black?text=No+Image',
    );
  }
}


Future<List<Article>> fetchArticles(String apiUrl) async {
  if (apiUrl.isEmpty) {
    throw Exception('يجب إدخال رابط API صالح.');
  }

  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

    if (jsonResponse.containsKey('articles') && jsonResponse['articles'] is List) {
      final List<dynamic> jsonList = jsonResponse['articles'];

      String sourceName = 'News API';
      if (jsonResponse.containsKey('source') && jsonResponse['source'] is String) {
        sourceName = jsonResponse['source'];
      }

      return jsonList.asMap().entries.map((entry) {
        return Article.fromJson(entry.value, entry.key, sourceName);
      }).toList();
    } else {
      if (jsonResponse is List) {
        final List<dynamic> jsonList = jsonResponse as List;
        return jsonList.asMap().entries.map((entry) {
          return Article.fromJson(entry.value, entry.key, 'Cat API / List Source');
        }).toList();
      }
      throw Exception('لم يتم العثور على قائمة مقالات صالحة. تأكد من أن الـ API يعيد قائمة مباشرة أو ضمن مفتاح "articles".');
    }
  } else {
    throw Exception('فشل في جلب البيانات. الحالة: ${response.statusCode}');
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عارض API ديناميكي',
      localizationsDelegates: const [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const DynamicApiViewerScreen(),
      routes: {
        '/article_detail': (context) => const ArticleDetailScreen(),
      },
    );
  }
}


class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final article = ModalRoute.of(context)!.settings.arguments as Article;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(article.source),
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  article.imageUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'المصدر: ${article.source}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const Divider(height: 32),

              Text(
                article.fullText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class DynamicApiViewerScreen extends StatefulWidget {
  const DynamicApiViewerScreen({super.key});

  @override
  State<DynamicApiViewerScreen> createState() => _DynamicApiViewerScreenState();
}

class _DynamicApiViewerScreenState extends State<DynamicApiViewerScreen> {
  List<Article>? _articles;
  String? _errorMessage;
  bool _isLoading = false;
  final TextEditingController _urlController = TextEditingController(text: DEFAULT_API_URL);

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleLoadApi() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء إدخال رابط API.';
        _articles = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _articles = null;
    });

    try {
      final fetchedArticles = await fetchArticles(url);
      setState(() {
        _articles = fetchedArticles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في التحميل: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عارض API ديناميكي'),
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'أدخل رابط API',
                        hintText: 'مثال: https://yourapi.com/posts',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.link),
                        errorText: _errorMessage?.contains('إدخال رابط') == true ? _errorMessage : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleLoadApi,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.download),
                      label: Text(_isLoading ? 'تحميل...' : 'تحميل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _buildBodyContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_errorMessage != null && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              Text(
                '$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                'رسالة من المبرمج: إذا لم يكن الـ API هو NewsAPI، فقد تحتاج لتعديل Article.fromJson ليتناسب مع مفاتيح بياناتك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.orange, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.indigo));
    }

    if (_articles != null && _articles!.isNotEmpty) {
      return ListView.builder(
        itemCount: _articles!.length,
        itemBuilder: (context, index) {
          return ArticleCard(
            article: _articles![index],
            onTap: () {
              Navigator.pushNamed(
                context,
                '/article_detail',
                arguments: _articles![index],
              );
            },
          );
        },
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.api, color: Colors.indigo, size: 60),
          SizedBox(height: 10),
          Text(
            'أدخل رابط API واضغط تحميل لعرض البيانات.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// 6. Custom Widget: ArticleCard (بطاقة المقال)
// ------------------------------------------------------------------

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const ArticleCard({super.key, required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                article.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Text('فشل تحميل الصورة', style: TextStyle(color: Colors.red)),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    article.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article.source,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.indigo,
                        ),
                      ),

                      TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.arrow_forward_ios, size: 14),
                        label: const Text('اقرأ المزيد'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.deepOrange,
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
}


