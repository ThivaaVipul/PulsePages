import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class EditJournalPage extends StatefulWidget {
  final String title;
  final String contentJson;
  final Function(String updatedContentJson) onSave;

  const EditJournalPage({
    super.key,
    required this.title,
    required this.contentJson,
    required this.onSave,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EditJournalPageState createState() => _EditJournalPageState();
}

class _EditJournalPageState extends State<EditJournalPage> {
  late quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = quill.QuillController(
      document: quill.Document.fromJson(jsonDecode(widget.contentJson)),
      selection: TextSelection.collapsed(offset: 0),
      readOnly: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _saveJournal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quill Toolbar
            quill.QuillSimpleToolbar(
              controller: _controller,
              config: const quill.QuillSimpleToolbarConfig(
                toolbarRunSpacing: 1,
                showLink: false,
                showSearchButton: false,
                showClearFormat: false,
                multiRowsDisplay: true,
              ),
            ),
            // Quill Editor
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: quill.QuillEditor.basic(
                  controller: _controller,
                  config: const quill.QuillEditorConfig(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveJournal() {
    final updatedContentJson = jsonEncode(
      _controller.document.toDelta().toJson(),
    );
    widget.onSave(updatedContentJson);
    Navigator.pop(context);
  }
}
