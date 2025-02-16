// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulsepages/screens/auth/signup_page.dart';
import 'package:pulsepages/screens/home_page.dart';
import 'forgot_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text(message)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _signInWithEmailPassword() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showToast("Please fill all fields", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      if (userCredential.user != null) {
        _showToast("Login successful!");
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

      if (userCredential.user != null) {
        _showToast("Google sign-in successful!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      _showToast("Google sign-in failed. Try again!", isError: true);
    }

    setState(() => isLoading = false);
  }

  String _getFriendlyErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return "No account found with this email.";
      case 'wrong-password':
        return "Incorrect password. Try again.";
      case 'invalid-email':
        return "Invalid email format.";
      case 'user-disabled':
        return "This account has been disabled.";
      default:
        return "Login failed. Please check your credentials.";
    }
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
              children: [
                Image.asset('assets/login.jpg', height: 250),
                SizedBox(height: 20),
                Text(
                  "Welcome Back!",
                  style: GoogleFonts.roboto(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[600],
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.amberAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.amberAccent,
                        width: 2.0,
                      ),
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
                    prefixIcon: Icon(Icons.lock, color: Colors.amberAccent),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.amberAccent,
                        width: 2.0,
                      ),
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
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.amber),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 90, vertical: 12),
                  ),
                  onPressed: isLoading ? null : _signInWithEmailPassword,
                  child:
                      isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                            "Login",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                            ),
                          ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("or"),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  icon: Image.asset('assets/google_icon.png', height: 24),
                  onPressed: isLoading ? null : _signInWithGoogle,
                  label: Text("Continue with Google"),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.black),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
                        );
                      },
                      child: Text(
                        "Sign up",
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
