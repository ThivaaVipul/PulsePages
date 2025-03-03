import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:pulsepages/services/journal_service.dart';

class CreateJournalPage extends StatefulWidget {
  const CreateJournalPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreateJournalPageState createState() => _CreateJournalPageState();
}

class _CreateJournalPageState extends State<CreateJournalPage> {
  final quill.QuillController _controller = quill.QuillController.basic();
  final TextEditingController _titleController = TextEditingController();
  final JournalService _journalService = JournalService();
  List<File> _selectedImages = [];

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    setState(() {
      _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
    });
  }

  Future<void> _saveJournal() async {
    final title = _titleController.text.trim();
    final content = jsonEncode(_controller.document.toDelta().toJson());

    if (title.isEmpty || content.isEmpty) return;

    List<String> imageUrls = await _journalService.uploadImages(
      _selectedImages,
    );

    bool success = await _journalService.addJournal(title, content, imageUrls);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Journal saved!')));
      _titleController.clear();
      setState(() {
        _controller.document = quill.Document();
        _selectedImages.clear();
      });
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save journal.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create Journal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),

            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add_a_photo),
                  onPressed: _pickImages,
                ),
                Text("Add Images"),
              ],
            ),
            SizedBox(height: 10),

            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImages[index],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 16),

            Expanded(
              child: quill.QuillEditor.basic(
                controller: _controller,
                config: const quill.QuillEditorConfig(),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: quill.QuillSimpleToolbar(
          controller: _controller,
          config: const quill.QuillSimpleToolbarConfig(
            toolbarRunSpacing: 1,
            showLink: false,
            showSearchButton: false,
            showClearFormat: false,
            multiRowsDisplay: false,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _saveJournal,
        child: Icon(Icons.save),
      ),
    );
  }
}
