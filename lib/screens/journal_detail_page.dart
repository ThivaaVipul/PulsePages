import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:photo_view/photo_view.dart';

class JournalDetailsPage extends StatelessWidget {
  final String title;
  final String contentJson;
  final List<String> imageUrls;

  const JournalDetailsPage({
    super.key,
    required this.title,
    required this.contentJson,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    final quill.Document document = quill.Document.fromJson(
      jsonDecode(contentJson),
    );

    final quill.QuillController controller = quill.QuillController(
      document: document,
      selection: TextSelection.collapsed(offset: 0),
      readOnly: true,
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
            if (imageUrls.isNotEmpty)
              Container(
                height: 200,
                margin: EdgeInsets.symmetric(vertical: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 16 : 8,
                        right: index == imageUrls.length - 1 ? 16 : 8,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => Scaffold(
                                    appBar: AppBar(
                                      title: Text('Image ${index + 1}'),
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                    ),
                                    body: PhotoView(
                                      imageProvider: NetworkImage(
                                        imageUrls[index],
                                      ),
                                      minScale:
                                          PhotoViewComputedScale.contained,
                                      maxScale:
                                          PhotoViewComputedScale.covered * 2,
                                    ),
                                  ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrls[index],
                            width: 300,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
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
                  controller: controller,
                  config: const quill.QuillEditorConfig(),
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  quill.QuillSimpleToolbar(
                    controller: controller,
                    config: const quill.QuillSimpleToolbarConfig(
                      toolbarRunSpacing: 1,
                      showLink: false,
                      showSearchButton: false,
                      showClearFormat: false,
                      multiRowsDisplay: true,
                    ),
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
