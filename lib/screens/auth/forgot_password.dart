// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password reset link sent to your email."),
          backgroundColor: Colors.green,
        ),
      );

      emailController.clear();

      // Navigate back to the login page
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/forgot_password.jpg', height: 250),
              SizedBox(height: 20),
              Text(
                "Forgot Password?",
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[600],
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Enter your email to receive a password reset link.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 20),
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
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 90, vertical: 12),
                ),
                onPressed: _isLoading ? null : _resetPassword,
                child:
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                          "Send Reset Link",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 20,
                          ),
                        ),
              ),
              SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Back to Login",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
