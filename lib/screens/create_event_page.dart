// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulsepages/constants/constants.dart';
import 'package:pulsepages/services/cloudinary_service.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _storeLocation = true;
  String _description = '';
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isRequestingPermission = false;
  String? _placeName;
  String? _placeAddress;

  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    if (_storeLocation && !_isRequestingPermission) {
      setState(() {
        _isRequestingPermission = true;
      });

      try {
        PermissionStatus status = await Permission.location.request();

        if (status.isGranted) {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          setState(() {
            _currentPosition = position;
          });

          await _fetchPlaceDetails(position);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permission is required')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error requesting location permission: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isRequestingPermission = false;
          });
        }
      }
    }
  }

  Future<void> _fetchPlaceDetails(Position position) async {
    final String url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final address = data['address'];

      final String? placeName = data['display_name'];

      final String? cityName =
          address['city'] ??
          address['town'] ??
          address['village'] ??
          address['county'];

      final String? road = address['road'];

      setState(() {
        _placeAddress = placeName;
        _placeName =
            road != null && road.isNotEmpty ? '$road, $cityName' : cityName;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
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
          _image = File(pickedFile.path);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission is required to take photos')),
      );
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose an option",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
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
                  title: Text("Take a photo"),
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
                  title: Text("Choose from gallery"),
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

  Map<String, dynamic> _positionToMap(Position? position) {
    if (position == null) return {};

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': position.timestamp.toIso8601String(),
      'accuracy': position.accuracy,
      'altitude': position.altitude,
      'heading': position.heading,
      'speed': position.speed,
      'speedAccuracy': position.speedAccuracy,
    };
  }

  Future<String> _generateCaptionFromImage(File image) async {
    final uri = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${Constants.geminiApiKey}",
    );

    final base64Image = base64Encode(image.readAsBytesSync());

    final request = http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Provide a **detailed and single** description of this image as you are the one journaling the events on your day and {$_description} this is your description. Do not list multiple options. Describe the main subject in a **concise yet informative** manner.',
              },
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
              },
            ],
          },
        ],
      }),
    );

    final response = await request;
    final responseBody = response.body;
    final decodedResponse = jsonDecode(responseBody);

    if (response.statusCode == 200 &&
        decodedResponse['candidates'] != null &&
        decodedResponse['candidates'].isNotEmpty &&
        decodedResponse['candidates'][0]['content']['parts'] != null &&
        decodedResponse['candidates'][0]['content']['parts'].isNotEmpty) {
      String generatedDescription =
          decodedResponse['candidates'][0]['content']['parts'][0]['text'];

      return generatedDescription.split('\n').first.trim();
    } else {
      throw Exception('Error generating caption: $decodedResponse');
    }
  }

  Future<String> _generateCaptionFromDescription(String description) async {
    const String apiUrl = "https://openrouter.ai/api/v1/chat/completions";
    const String apiKey = Constants.chatApiKey;

    final Map<String, dynamic> requestBody = {
      "model": "google/gemini-2.0-flash-lite-preview-02-05:free",
      "messages": [
        {
          "role": "user",
          "content":
              _storeLocation
                  ? """
        Generate a single, well-structured caption based on the following event description and location. 
        The caption should be engaging, vivid, and descriptive, yet concise. 
        Avoid multiple options or formatting styles—return only **one** refined caption.
        Avoid adding random date and location details.

        **Event Description:** "$description"
        **Event Location:** "$_placeName"

        Ensure the response is natural, human-like, and under 50 words as you are writing your daily journal.
        """
                  : """
        Generate a single, well-structured caption based on the following event description. 
        The caption should be engaging, vivid, and descriptive, yet concise. 
        Avoid multiple options or formatting styles—return only **one** refined caption.
        Avoid adding random date and location details.

        **Event Description:** "$description"

        Ensure the response is natural, human-like, and under 50 words as you are writing your daily journal.
        """,
        },
      ],
      "temperature": 0.7,
      "max_tokens": 100,
    };

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData["choices"][0]["message"]["content"]?.trim() ??
          "No caption generated";
    } else {
      throw Exception('Error generating caption: ${response.body}');
    }
  }

  Future<void> _submitEvent() async {
    FocusScope.of(context).unfocus();

    if (_description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Description is required')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      String caption;

      if (_image != null) {
        imageUrl = await CloudinaryService.uploadImage(_image!);
        caption = await _generateCaptionFromImage(_image!);
      } else {
        caption = await _generateCaptionFromDescription(_description);
      }

      final userId = _auth.currentUser?.uid ?? "guest";
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final eventData = {
        'description': _description,
        'imageUrl': imageUrl,
        'caption': caption,
        'timestamp': Timestamp.now(),
        'location': _storeLocation ? _positionToMap(_currentPosition) : null,
        'placeName': _placeName,
        'placeAddress': _placeAddress,
      };

      await _firestore
          .collection('events')
          .doc(userId)
          .collection(todayDate)
          .add(eventData);

      setState(() {
        _description = '';
        _descriptionController.clear();
        _image = null;
        _storeLocation = true;
        _isLoading = false;
        _placeName = null;
        _placeAddress = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event created successfully!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating event'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create Event",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Event Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _description = value;
                  });
                },
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _showImageSourceOptions,
                child:
                    _image == null
                        ? Container(
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
                              SizedBox(height: 10),
                              Text(
                                "Tap to add a photo",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                        : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _image!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: InkWell(
                                onTap: _showImageSourceOptions,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _storeLocation,
                    onChanged: (value) {
                      setState(() {
                        _storeLocation = value ?? true;
                        if (_storeLocation) {
                          _getLocation();
                        }
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  Text("Store Location"),
                ],
              ),
              SizedBox(height: 20),
              _isLoading
                  ? SpinKitFadingCircle(
                    color: Theme.of(context).primaryColor,
                    size: 50.0,
                  )
                  : ElevatedButton(
                    onPressed: _submitEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: Text(
                      "Create Event",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
