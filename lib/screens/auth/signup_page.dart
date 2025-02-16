// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pulsepages/screens/home_page.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(message)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _signUpWithEmailPassword() async {
    if (usernameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      _showToast("Please fill all fields", isError: true);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showToast("Passwords do not match", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final User? user = userCredential.user;

      if (user != null) {
        // Store user details in Firestore
        await _firestore.collection("users").doc(user.uid).set({
          "username": usernameController.text.trim(),
          "email": user.email,
          "uid": user.uid,
          "createdAt": FieldValue.serverTimestamp(),
        });

        _showToast("Signup successful!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showToast(_getFriendlyErrorMessage(e.code), isError: true);
    } catch (e) {
      _showToast("Something went wrong. Try again!", isError: true);
    }

    setState(() => isLoading = false);
  }

  String _getFriendlyErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return "Email is already in use. Try logging in.";
      case 'invalid-email':
        return "Invalid email address.";
      case 'weak-password':
        return "Password is too weak. Try a stronger one.";
      case 'operation-not-allowed':
        return "Sign up is not allowed at the moment.";
      default:
        return "Signup failed. Please try again.";
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _showToast("Google sign-in cancelled", isError: true);
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        final userDoc =
            await _firestore.collection("users").doc(user.uid).get();

        if (!userDoc.exists) {
          await _firestore.collection("users").doc(user.uid).set({
            "username": googleUser.displayName ?? "Unknown User",
            "email": user.email,
            "uid": user.uid,
            "createdAt": FieldValue.serverTimestamp(),
          });
        }

        _showToast("Google sign-in successful!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      _showToast("Google sign-in failed: ${e.toString()}", isError: true);
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/sign_up.jpg', height: 220),
                Text(
                  "Welcome to Pulse Pages!",
                  style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[600],
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: "Username",
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.amber),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.amberAccent,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    hintText: "Enter your username",
                    hintStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 10.0,
                    ),
                  ),
                  style: TextStyle(color: Colors.black87, fontSize: 16.0),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.amber),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.amberAccent,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    hintText: "Enter your email",
                    hintStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 10.0,
                    ),
                  ),
                  style: TextStyle(color: Colors.black87, fontSize: 16.0),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.amber),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.amberAccent,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    hintText: "Enter your password",
                    hintStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 10.0,
                    ),
                  ),
                  style: TextStyle(color: Colors.black87, fontSize: 16.0),
                  obscureText: true,
                ),
                SizedBox(height: 15),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.amber),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.amberAccent,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    hintText: "Confirm your password",
                    hintStyle: TextStyle(color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 10.0,
                    ),
                  ),
                  style: TextStyle(color: Colors.black87, fontSize: 16.0),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                isLoading
                    ? CircularProgressIndicator()
                    : Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 80,
                              vertical: 12,
                            ),
                          ),
                          onPressed:
                              isLoading ? null : _signUpWithEmailPassword,
                          child:
                              isLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    "Sign up",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                    ),
                                  ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(thickness: 1, color: Colors.grey),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text("or"),
                            ),
                            Expanded(
                              child: Divider(thickness: 1, color: Colors.grey),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                          ),
                          icon: Image.asset(
                            'assets/google_icon.png',
                            height: 24,
                          ),
                          onPressed: _signInWithGoogle,
                          label: Text("Continue with Google"),
                        ),
                      ],
                    ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.black),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
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
