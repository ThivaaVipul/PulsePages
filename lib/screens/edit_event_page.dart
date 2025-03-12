// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:pulsepages/services/cloudinary_service.dart';

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
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _descriptionController;
  late TextEditingController _captionController;
  late TextEditingController _placeNameController;
  late TextEditingController _placeAddressController;

  File? _newImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.eventData['description'],
    );
    _captionController = TextEditingController(
      text: widget.eventData['caption'],
    );
    _placeNameController = TextEditingController(
      text: widget.eventData['placeName'] ?? '',
    );
    _placeAddressController = TextEditingController(
      text: widget.eventData['placeAddress'] ?? '',
    );
  }

  Future<void> _captureImageFromCamera() async {
    PermissionStatus cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _newImage = File(pickedFile.path);
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to take photos'),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _newImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Choose an option",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: const Text("Take a photo"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _captureImageFromCamera();
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.photo_library,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: const Text("Choose from gallery"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteImageFromCloudinary(String imageUrl) async {
    try {
      await CloudinaryService.deleteImage(imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> updateEvent() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      String? imageUrl = widget.eventData['imageUrl'];

      if (_newImage != null) {
        if (imageUrl != null) {
          await _deleteImageFromCloudinary(imageUrl);
        }

        imageUrl = await CloudinaryService.uploadImage(_newImage!);
      }

      await _firestore
          .collection('events')
          .doc(userId)
          .collection(todayDate)
          .doc(widget.docId)
          .update({
            'description': _descriptionController.text,
            'caption': _captionController.text,
            'placeName': _placeNameController.text,
            'placeAddress': _placeAddressController.text,
            'imageUrl': imageUrl,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context);
      }
    }
  }

  Future<void> deleteEvent() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      if (widget.eventData['imageUrl'] != null) {
        await _deleteImageFromCloudinary(widget.eventData['imageUrl']);
      }

      await _firestore
          .collection('events')
          .doc(userId)
          .collection(todayDate)
          .doc(widget.docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context);
      }
    }
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
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: Center(
                child: PhotoView(
                  imageProvider:
                      imageUrl.startsWith('http')
                          ? NetworkImage(imageUrl)
                          : FileImage(File(imageUrl)) as ImageProvider,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
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
        title: const Text(
          "Edit Event",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Edit Your Event",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

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
                const SizedBox(height: 16),

                // Event Caption
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
                const SizedBox(height: 16),

                // Place Name
                TextField(
                  controller: _placeNameController,
                  decoration: InputDecoration(
                    labelText: "Place Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Place Address
                TextField(
                  controller: _placeAddressController,
                  decoration: InputDecoration(
                    labelText: "Place Address",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Image Section
                if (widget.eventData['imageUrl'] != null || _newImage != null)
                  Column(
                    children: [
                      GestureDetector(
                        onTap:
                            () => _showFullImage(
                              _newImage != null
                                  ? _newImage!.path
                                  : widget.eventData['imageUrl'],
                            ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              _newImage != null
                                  ? Image.file(
                                    _newImage!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                  : Image.network(
                                    widget.eventData['imageUrl'],
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _showImageSourceOptions,
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Center(
                            child: Text(
                              'Change Image',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _showImageSourceOptions,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Tap to add an image",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Save and Delete Buttons
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: deleteEvent,
                            icon: const Icon(Icons.delete, color: Colors.white),
                            label: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: updateEvent,
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text(
                              "Save",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }
}
