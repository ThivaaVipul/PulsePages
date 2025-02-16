import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pulsepages/screens/auth/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await auth.signOut();
              Navigator.pushReplacement(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Center(child: Text("Welcome to Home Page!")),
    );
  }
}
