import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulsepages/screens/create_journal_page.dart';
import 'package:pulsepages/screens/journal_detail_page.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid ?? "guest";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Journals",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('journals')
                .where('userId', isEqualTo: userId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No journals found"));
          }

          final journals = snapshot.data!.docs;

          return ListView.builder(
            itemCount: journals.length,
            itemBuilder: (context, index) {
              final doc = journals[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['title']),
                subtitle: Text(data['timestamp']?.toDate()?.toString() ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => JournalDetailsPage(
                            title: data['title'],
                            contentJson: data['content'],
                          ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateJournalPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
