import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pulsepages/constants/constants.dart';
import 'edit_journal_page.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isRegenerating = false;
  String? _generatedJournalJson;
  late quill.QuillController _quillController;
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController.basic();
    _fetchJournalForSelectedDate();
  }

  Future<void> _fetchJournalForSelectedDate() async {
    setState(() {
      _isLoading = true;
      _generatedJournalJson = null;
      _quillController = quill.QuillController.basic();
      _imageUrls = [];
    });

    final userId = _auth.currentUser?.uid;
    final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      // Fetch journal for the selected date
      final journalSnapshot =
          await _firestore
              .collection('journals')
              .doc(userId)
              .collection(selectedDate)
              .doc('journal')
              .get();

      if (journalSnapshot.exists) {
        final journalData = journalSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _generatedJournalJson = journalData['content'];
          final decodedJson = jsonDecode(_generatedJournalJson!);
          _quillController = quill.QuillController(
            document: quill.Document.fromJson(decodedJson),
            selection: TextSelection.collapsed(offset: 0),
            readOnly: true,
          );
        });
      }

      // Fetch images for the selected date
      final eventsSnapshot =
          await _firestore
              .collection('events')
              .doc(userId)
              .collection(selectedDate)
              .get();

      final imageUrls =
          eventsSnapshot.docs
              .where((doc) => doc['imageUrl'] != null)
              .map((doc) => doc['imageUrl'] as String)
              .toList();

      setState(() {
        _imageUrls = imageUrls;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching journal or images')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Daily Journal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        leading: _buildMonthDropdown(),
        leadingWidth: 100,
        actions: [
          if (_generatedJournalJson != null)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditJournalPage(
                          title: "Edit Journal",
                          contentJson: _generatedJournalJson!,
                          onSave: (updatedContentJson) async {
                            // Save the updated content to Firestore
                            await _firestore
                                .collection('journals')
                                .doc(userId)
                                .collection(selectedDate)
                                .doc('journal')
                                .update({
                                  'content': updatedContentJson,
                                  'updatedAt': Timestamp.now(),
                                });

                            if (mounted) {
                              setState(() {
                                _generatedJournalJson = updatedContentJson;
                                _quillController = quill.QuillController(
                                  document: quill.Document.fromJson(
                                    jsonDecode(updatedContentJson),
                                  ),
                                  selection: TextSelection.collapsed(offset: 0),
                                  readOnly: true,
                                );
                              });
                            }
                          },
                        ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          // Calendar Bar
          _buildCalendarBar(),
          SizedBox(height: 20),
          // Journal Content or Generate Button
          Expanded(
            child:
                _isRegenerating
                    ? _buildLoadingState()
                    : _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _generatedJournalJson == null
                    ? _buildGenerateJournalButton()
                    : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Journal Content
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: quill.QuillEditor.basic(
                              controller: _quillController,
                            ),
                          ),
                          // Image Gallery (if images exist)
                          if (_imageUrls.isNotEmpty) _buildImageGallery(),
                          // Delete and Regenerate Buttons
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _deleteJournal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      "Delete Journal",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _regenerateJournal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      "Regenerate Journal",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(30, (index) {
          final date = DateTime.now().subtract(Duration(days: index));
          final isSelected = date.day == _selectedDate.day;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              _fetchJournalForSelectedDate();
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Padding(
      padding: EdgeInsets.only(left: 20),
      child: DropdownButton<String>(
        value: DateFormat('MMM').format(_selectedDate),
        onChanged: (String? newValue) {
          if (newValue != null) {
            final monthIndex = months.indexOf(newValue) + 1;
            final newDate = DateTime(
              _selectedDate.year,
              monthIndex,
              _selectedDate.day,
            );
            setState(() {
              _selectedDate = newDate;
            });
            _fetchJournalForSelectedDate();
          }
        },
        items:
            months.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(color: Colors.white)),
              );
            }).toList(),
        dropdownColor: Theme.of(context).primaryColor,
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
        underline: SizedBox(),
      ),
    );
  }

  Widget _buildGenerateJournalButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_isLoading && !_isRegenerating)
            Text(
              "No journal found for this day.",
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
          SizedBox(height: 20),
          _isLoading || _isRegenerating
              ? _buildLoadingState()
              : ElevatedButton(
                onPressed: _generateJournal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: Text(
                  "Generate Today's Journal",
                  style: TextStyle(color: Colors.white),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Generating your journal...",
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: _imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => Scaffold(
                        appBar: AppBar(
                          title: Text(
                            DateFormat('MMMM d, yyyy').format(_selectedDate),
                          ),
                        ),
                        body: PageView.builder(
                          itemCount: _imageUrls.length,
                          controller: PageController(initialPage: index),
                          itemBuilder: (context, fullscreenIndex) {
                            return PhotoView(
                              imageProvider: NetworkImage(
                                _imageUrls[fullscreenIndex],
                              ),
                            );
                          },
                        ),
                      ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: _imageUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildImageSkeleton(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  Future<void> _deleteJournal() async {
    final userId = _auth.currentUser?.uid;
    final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      await _firestore
          .collection('journals')
          .doc(userId)
          .collection(selectedDate)
          .doc('journal')
          .delete();

      if (mounted) {
        setState(() {
          _quillController = quill.QuillController.basic();
          _generatedJournalJson = null;
          _imageUrls.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Journal deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting journal')));
      }
    }
  }

  Future<void> _regenerateJournal() async {
    setState(() {
      _isRegenerating = true;
    });
    await _generateJournal();
    if (mounted) {
      setState(() {
        _isRegenerating = false;
      });
    }
  }

  Future<void> _generateJournal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final eventsSnapshot =
          await _firestore
              .collection('events')
              .doc(userId)
              .collection(selectedDate)
              .get();

      final events = eventsSnapshot.docs.map((doc) => doc.data()).toList();
      _imageUrls =
          events
              .where((event) => event['imageUrl'] != null)
              .map((event) => event['imageUrl'] as String)
              .toList();

      final eventSummaries = events
          .map((event) {
            return """
**Event Description:** ${event['description']}
**Caption:** ${event['caption'] ?? 'No Caption'}
**PlaceName:** ${event['placeName'] ?? 'No PlaceName'}
**Address:** ${event['placeAddress'] ?? 'No Address'}
""";
          })
          .join('\n\n');

      if (eventSummaries.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No events found to generate a journal.')),
          );
        }
        return;
      }

      const String apiUrl = "https://openrouter.ai/api/v1/chat/completions";
      const String apiKey = Constants.chatApiKey;

      final Map<String, dynamic> requestBody = {
        "model": "google/gemini-2.0-flash-lite-preview-02-05:free",
        "messages": [
          {
            "role": "user",
            "content": """
Generate a well-structured journal entry summarizing the following events for the day. Use rich text formatting (e.g., bold, italic, underline, strikethrough, headings, colors, lists, links) and organize the content into paragraphs. Include details about the events, emotions, and locations. Make it engaging and reflective.

**IMPORTANT: Use actual Unicode emoji characters only.** Examples: 😊 🌳 🍕 🇫🇷 ❤️
Do NOT use any emoji-like sequences that look like "ð«ð·" or other encoded/escaped forms. When including flag emojis like the French flag, write the actual character 🇫🇷 not a code.

**Events:**
$eventSummaries

**Output Format:**
Return the journal content as a JSON array compatible with Flutter Quill's Delta format. Example:
[
  {"insert": "Journal Title\\n", "attributes": {"header": 1, "color": "#007bff"}},
  {"insert": "Today was a great day! 😊\\n"},
  {"insert": "I visited ", "attributes": {"bold": true}},
  {"insert": "Central Park 🌳", "attributes": {"italic": true, "color": "#28a745"}},
  {"insert": " and had a wonderful time.\\n"},
  {"insert": "Here are some highlights:\\n"},
  {"insert": "• Ate delicious food 🍕 \\n", "attributes": {"list": "bullet"}},
  {"insert": "• Took a long walk 🚶‍♂️ \\n", "attributes": {"list": "bullet"}},
  {"insert": "• Met an old friend 👋 \\n", "attributes": {"list": "bullet"}},
  {"insert": "\\n"},
  {"insert": "Check out more about Central Park ", "attributes": {"italic": true}},
  {"insert": "here", "attributes": {"link": "https://en.wikipedia.org/wiki/Central_Park"}},
  {"insert": ".\\n"}
]

**Important:**
- Use ONLY actual Unicode emoji characters, not emoji codes or representations.
- Ensure all emojis are represented as their actual Unicode characters.
- Use proper spacing and punctuation.
- Don't use random dates or locations.
- If the placename or address mentioned as "No PlaceName" or "No Address" then don't add it in the journal.
- Use the provided events as the main content of the journal.
- Use the appropriate Quill Delta format for text attributes to make the journal engaging.
- Provide Reflections and Emotions about the events.
- Ensure the journal is well-structured and easy to read.
- Ensure at the end of the journal put a one line reflection about the day.
- Return only the JSON array. Do not include any additional text or explanations.
- Ensure the JSON is valid and properly formatted.
- Ensure the last line ends with a newline character (\\n).
""",
          },
        ],
        "temperature": 0.7,
        "max_tokens": 1000,
        "response_format": {"type": "json_object"},
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
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        var generatedJournalJson =
            responseData["choices"][0]["message"]["content"]?.trim() ??
            jsonEncode([
              {"insert": "No journal generated.\\n"},
            ]);

        if (generatedJournalJson.startsWith('```json\n')) {
          generatedJournalJson = generatedJournalJson.substring(8);
        }
        if (generatedJournalJson.endsWith('\n```')) {
          generatedJournalJson = generatedJournalJson.substring(
            0,
            generatedJournalJson.length - 4,
          );
        }

        generatedJournalJson = generatedJournalJson.trim();

        try {
          final parsedJson = jsonDecode(
            utf8.decode(utf8.encode(generatedJournalJson)),
          );

          if (parsedJson is! List) {
            throw FormatException(
              "Invalid JSON format: Expected a JSON array.",
            );
          }

          for (var item in parsedJson) {
            if (item.containsKey("insert") && item["insert"] is String) {}
          }

          if (parsedJson.isNotEmpty) {
            final lastLine = parsedJson.last["insert"] as String?;
            if (lastLine != null && !lastLine.endsWith('\n')) {
              parsedJson.last["insert"] = "$lastLine\n";
              generatedJournalJson = jsonEncode(parsedJson);
            }
          }

          final quillDocument = quill.Document.fromJson(parsedJson);

          if (mounted) {
            setState(() {
              _quillController = quill.QuillController(
                document: quillDocument,
                selection: TextSelection.collapsed(offset: 0),
                readOnly: true,
              );
              _generatedJournalJson = generatedJournalJson;
              _isLoading = false;
            });

            await _firestore
                .collection('journals')
                .doc(userId)
                .collection(selectedDate)
                .doc('journal')
                .set({
                  'content': generatedJournalJson,
                  'createdAt': Timestamp.now(),
                  'events': events.map((event) => event['entryId']).toList(),
                });
          }
        } catch (e) {
          final fallbackJson = jsonEncode([
            {"insert": "Journal entry with emoji issue. Please regenerate.\n"},
          ]);

          final quillDocument = quill.Document.fromJson(
            jsonDecode(fallbackJson),
          );

          if (mounted) {
            setState(() {
              _quillController = quill.QuillController(
                document: quillDocument,
                selection: TextSelection.collapsed(offset: 0),
                readOnly: true,
              );
              _generatedJournalJson = fallbackJson;
              _isLoading = false;
            });

            await _firestore
                .collection('journals')
                .doc(userId)
                .collection(selectedDate)
                .doc('journal')
                .set({
                  'content': fallbackJson,
                  'createdAt': Timestamp.now(),
                  'events': events.map((event) => event['entryId']).toList(),
                });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error with journal formatting. Please try regenerating.',
                ),
              ),
            );
          }
        }
      } else {
        throw Exception('Error generating journal: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating journal: $e')));
      }
    }
  }
}
