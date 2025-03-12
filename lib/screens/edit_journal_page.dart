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
  bool _isSaving = false;

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
            onPressed: _isSaving ? null : _saveJournal,
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
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
          if (_isSaving)
            Container(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Saving journal...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveJournal() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isSaving = true;
    });

    try {
      await Future.delayed(Duration(seconds: 2));

      final updatedContentJson = jsonEncode(
        _controller.document.toDelta().toJson(),
      );

      widget.onSave(updatedContentJson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Journal saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save journal. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
