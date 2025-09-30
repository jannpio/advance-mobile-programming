import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pioquinto_advmobprog/models/article_model.dart';
import 'package:pioquinto_advmobprog/screens/article_details_screen.dart';
import 'package:pioquinto_advmobprog/services/article_service.dart';
import 'package:pioquinto_advmobprog/widgets/article_dialog.dart';
import 'package:pioquinto_advmobprog/widgets/custom_text.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late Future<List<Article>> _futureArticles;
  List<Article> _allArticles = [];
  List<Article> _filteredArticles = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureArticles = _getAllArticles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Article>> _getAllArticles() async {
    final response = await ArticleService().getAllArticle();
    final articles = (response).map((e) => Article.fromJson(e)).toList();
    _allArticles = articles;
    _filteredArticles = articles;
    return articles;
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredArticles = _allArticles
          .where((article) =>
              article.title.toLowerCase().contains(query) ||
              article.content.contains(query))
          .toList();
    });
  }

  Future<void> _openAddArticleDialog() async {
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (ctx) {
        return ArticleFormDialog(
              title: "Add Article",
              onSubmit: (payload) async {
                final res = await ArticleService().createArticle(payload);
                final created = (res['article'] ?? res);
                final newArticle = Article.fromJson(created);

                setState(() {
                  _allArticles.insert(0, newArticle);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Article added.')),
                );

                return res;
              },
            );
          },
        );
      }

  Widget _statusChip(bool active) {
    return Chip(
      label: Text(active ? 'Active' : 'Inactive'),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: active ? Colors.green : Colors.grey),
    );
  }

  void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddArticleDialog, 
        icon: Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h,),

            //Search field here
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 14.sp),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search articles...",
                  hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: 10.h,),

            FutureBuilder <void>(
              future: _futureArticles, //_loadFuture
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SizedBox(
                    height: ScreenUtil().screenHeight * 0.6,
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CustomText(text: 'No Equipment article to display...',
                        color: Colors.black,),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: ScreenUtil().screenHeight * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircularProgressIndicator.adaptive(strokeWidth: 3.sp,),
                          SizedBox(height: 10.h,),
                          const CustomText(
                            text: 'Waiting for the equipment articles to display...',
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_filteredArticles.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(top: 20.h),
                    child: const Center(
                      child: CustomText(
                        text: 'No equipment articles to display...',
                        color: Colors.black,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  shrinkWrap: true,
                  itemCount: _filteredArticles.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                      final article = _filteredArticles[index]; {
                      final preview = article.content.isNotEmpty
                        ? article.content.first
                        : '';
                      return Card(
                        elevation: 1,
                        child: InkWell(
                          onTap: () async {
                            debugPrint('Tapped index $index: ${article.aid}');
                            final updated = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ArticleDetailsScreen(article: article),
                              ),
                            );

                            if (updated != null && updated is Article) {
                              setState(() {
                                final idx = _allArticles.indexWhere((a) => a.aid == updated.aid);
                                if (idx != -1) {
                                  _allArticles[idx] = updated;
                                }
                                _onSearchChanged();
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ScreenUtil().setWidth(15),
                              vertical: ScreenUtil().setHeight(15),
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: CustomText(
                                              text: article.title.isEmpty
                                                ? 'Untitled'
                                                : article.title,
                                              fontSize: 24.sp,
                                              fontWeight: FontWeight.bold,
                                              maxLines: 2,
                                              color: Colors.black,
                                            ),
                                          ),
                                          _statusChip(article.isActive),
                                        ],
                                      ),
                                      SizedBox(height: 4.h,),
                                      CustomText(
                                        text: article.name,
                                        fontSize: 13.sp,
                                        color: Colors.black,
                                      ),
                                      if (preview.isNotEmpty) ... [
                                        SizedBox(height: 6.h),
                                        CustomText(
                                          text: preview,
                                          fontSize: 12.sp,
                                          maxLines: 2,
                                          color: Colors.black,
                                        )
                                      ]
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  },
                );
              }
            )
          ],
        ),
      ),
    );
  }
}