import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulsepages/services/cloudinary_service.dart';

class JournalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<String>> uploadImages(List<File> images) async {
    List<String> imageUrls = [];

    for (var image in images) {
      try {
        String url = await CloudinaryService.uploadImage(image);
        imageUrls.add(url);
      } catch (e) {
        throw Exception('Failed to upload image: $e');
      }
    }

    return imageUrls;
  }

  Future<bool> addJournal(
    String title,
    String content,
    List<String> imageUrls,
  ) async {
    final userId = _auth.currentUser?.uid ?? "guest";

    if (title.isEmpty || content.isEmpty) return false;

    try {
      await _firestore.collection('journals').add({
        'userId': userId,
        'title': title,
        'content': content,
        'imageUrls': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<QuerySnapshot> getJournals() {
    final userId = _auth.currentUser?.uid ?? "guest";
    return _firestore
        .collection('journals')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }
}
