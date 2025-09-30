import 'package:flutter/material.dart';

class ArticleFormDialog extends StatefulWidget {
  final String title;
  final String? initialTitle;
  final String? initialAuthor;
  final List<String>? initialContent;
  final bool initialActive;
  final Future<Map> Function(Map<String, dynamic>) onSubmit;

  const ArticleFormDialog({
    super.key,
    required this.title,
    this.initialTitle,
    this.initialAuthor,
    this.initialContent,
    this.initialActive = true,
    required this.onSubmit,
  });

  @override
  State<ArticleFormDialog> createState() => _ArticleFormDialogState();
}

class _ArticleFormDialogState extends State<ArticleFormDialog> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController authorController;
  late TextEditingController contentController;
  bool isSaving = false;
  late bool isActive;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle ?? "");
    authorController = TextEditingController(text: widget.initialAuthor ?? "");
    contentController = TextEditingController(
      text: widget.initialContent?.join("\n") ?? "",
    );
    isActive = widget.initialActive;
  }

  List<String> _toList(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
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

  Future<void> save() async {
    if (isSaving) return;
    if (!formKey.currentState!.validate()) return;

    showLoadingDialog(context, "${widget.title}...");

    setState(() => isSaving = true);
    try {
      final payload = {
        'title': titleController.text.trim(),
        'name': authorController.text.trim(),
        'content': _toList(contentController.text.trim()),
        'isActive': isActive,
      };

      final Map res = await widget.onSubmit(payload);

      if (mounted) Navigator.of(context).pop(); // close loading
      if (mounted) Navigator.of(context).pop(res); // close dialog & return data
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: contentController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText:
                      'Content (one item per line or comma-separated)',
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
                  return items.isEmpty ? 'At least one content item' : null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          onPressed: save,
          label: const Text('Save'),
        ),
      ],
    );
  }
}