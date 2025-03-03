import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class JournalDetailsPage extends StatelessWidget {
  final String title;
  final String contentJson;

  const JournalDetailsPage({
    super.key,
    required this.title,
    required this.contentJson,
  });

  @override
  Widget build(BuildContext context) {
    final quill.Document document = quill.Document.fromJson(
      jsonDecode(contentJson),
    );

    final quill.QuillController controller = quill.QuillController(
      document: document,
      selection: TextSelection.collapsed(offset: 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            quill.QuillSimpleToolbar(
              controller: controller,
              config: const quill.QuillSimpleToolbarConfig(
                toolbarRunSpacing: 1,
                showLink: false,
                showSearchButton: false,
                showClearFormat: false,
                multiRowsDisplay: false,
              ),
            ),
            Expanded(
              child: quill.QuillEditor.basic(
                controller: controller,
                config: const quill.QuillEditorConfig(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
