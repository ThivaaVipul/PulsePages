import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class EditEventPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final String docId;

  const EditEventPage({
    super.key,
    required this.eventData,
    required this.docId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TextEditingController _descriptionController;
  late TextEditingController _captionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.eventData['description'],
    );
    _captionController = TextEditingController(
      text: widget.eventData['caption'],
    );
  }

  void updateEvent() {
    final userId = _auth.currentUser?.uid;
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _firestore
        .collection('events')
        .doc(userId)
        .collection(todayDate)
        .doc(widget.docId)
        .update({
          'description': _descriptionController.text,
          'caption': _captionController.text,
        });

    Navigator.pop(context);
  }

  void deleteEvent() {
    final userId = _auth.currentUser?.uid;
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    _firestore
        .collection('events')
        .doc(userId)
        .collection(todayDate)
        .doc(widget.docId)
        .delete();

    Navigator.pop(context);
  }

  void _showFullImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  backgroundDecoration: BoxDecoration(color: Colors.black),
                ),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Edit Event",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Your Event",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Event Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),

              TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  labelText: "Event Caption",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 5,
              ),
              SizedBox(height: 16),

              if (widget.eventData['imageUrl'] != null)
                GestureDetector(
                  onTap: () => _showFullImage(widget.eventData['imageUrl']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.eventData['imageUrl'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              Spacer(),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: deleteEvent,
                      icon: Icon(Icons.delete, color: Colors.white),
                      label: Text(
                        "Delete",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: updateEvent,
                      icon: Icon(Icons.save, color: Colors.white),
                      label: Text(
                        "Save",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
