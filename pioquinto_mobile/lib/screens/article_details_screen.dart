import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pioquinto_advmobprog/models/article_model.dart';
import 'package:pioquinto_advmobprog/services/article_service.dart';
import 'package:pioquinto_advmobprog/widgets/custom_text.dart';

class ArticleDetailsScreen extends StatefulWidget {
  final Article article;
  const ArticleDetailsScreen({super.key, required this.article});
  
  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  List<Article> _allArticles = [];
  List<Article> _filteredArticles = [];

  final formKey = GlobalKey<FormState>();
  bool isSaving = false;
  bool isActive = true;  
  bool isEditing = false;

  late TextEditingController titleController;
  late TextEditingController authorController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.article.title);
    authorController = TextEditingController(text: widget.article.name);
    contentController = TextEditingController(
      text: widget.article.content.join("\n"),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    contentController.dispose();
    super.dispose();
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
      appBar: AppBar(
        elevation: 0,
        title: CustomText(
          text: widget.article.title.isEmpty
            ? 'Untitled'
            : widget.article.title,
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          maxLines: 2,
          color: Colors.black,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.cancel : Icons.edit),
            onPressed: () {
              setState(() {
                // toggle view/edit
                isEditing = !isEditing;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEditing ? _buildEditForm() : _buildDetailView(),
      ),
    );
  }



  Widget _buildDetailView () {
    return SingleChildScrollView(
      child: Column(
        children: [
          Placeholder(
            fallbackHeight: 200.h,
            fallbackWidth: double.infinity,
          ),
          SizedBox(height: 20.h,),
          Container(
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
                              text: widget.article.title.isEmpty
                                ? 'Untitled'
                                : widget.article.title,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              maxLines: 2,
                              color: Colors.black,
                            ),
                          ),
                          _statusChip(widget.article.isActive),
                        ],
                      ),
                      SizedBox(height: 4.h,),
                      CustomText(
                        text: widget.article.name,
                        fontSize: 20.sp,
                        //fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Colors.black,
                      ),
                      if (widget.article.content.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.article.content.map((item) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 4.h), // spacing between bullets
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "• ",
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  Expanded(
                                    child: CustomText(
                                      text: item,
                                      fontSize: 14.sp,
                                      maxLines: 2,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ]
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm () {
    return StatefulBuilder(
      builder: (ctx, setLocalState) {
        List<String> _toList(String raw) {
          return raw
          .split(RegExp(r'[\n,]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
        }

    Future<void> save() async {
      if (isSaving) return;
      if (!formKey.currentState!.validate()) return;
      showLoadingDialog(context, 'Updating article...');

      setLocalState(() {
        isSaving = true;
      } );
      try {
        final payLoad = {
          'title': titleController.text.trim(),
          'name': authorController.text.trim(),
          'content': _toList(contentController.text.trim()),
          'isActive': isActive,
        };

        final Map res = await ArticleService().updateArticle(widget.article.aid, payLoad);

        // Adjust depending on your API's response shape
        final created = (res['article'] ?? res);
        final newArticle = Article.fromJson(created);

        setState(() {
          _allArticles.insert(0, newArticle);
          _filteredArticles; // keep current query applied
        });


        if (ctx.mounted) Navigator.of(ctx).pop();
        if(mounted) {
          Navigator.of(context).pop(newArticle); // return the article
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article updated.')),
          );
        }
      } catch (e) {
        setLocalState(() => isSaving = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update: $e')),
            );
          }
        }
      } //
        return Column(
          children: [ 
            Placeholder(
                fallbackHeight: 200.h,
                fallbackWidth: double.infinity,
              ),
            SizedBox(height: 20.h,),
            Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: 12.h,),
                    TextFormField(
                      controller: authorController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Author / Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    SizedBox(height: 12.h,),
                    TextFormField(
                      controller: contentController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Content (one item per line or comma-separated)',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) {
                        final items = v == null
                          ? []
                          : v 
                              .trim()
                              .split(RegExp(r'[\n,]'))
                              .where((s) => s.trim().isNotEmpty)
                              .toList();
                          return items.isEmpty
                            ? 'At least one content item'
                            : null;
                      }
                    ),
                    SizedBox(height: 8.h,),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      value: isActive,
                      onChanged: (val) => setLocalState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity, // take full width
              child: ElevatedButton.icon(
                icon: Icon(Icons.save), 
                onPressed: () {
                  save();
                }, 
                label: Text('Save'),
                style: ButtonStyle(),
              ),
            ),
            SizedBox(
              width: double.infinity, // take full width
              child: ElevatedButton.icon(
              icon: Icon(Icons.cancel), 
                onPressed: () {
                  setState(() {
                    // toggle view/edit
                    isEditing = !isEditing;
                  });
                }, 
                label: Text('Cancel'),
                style: ButtonStyle(),
              ),
            ),
            Text('Tip: Separate multiple content items using new lines or commas.')
          ]
        );
      },
    );
  }
}