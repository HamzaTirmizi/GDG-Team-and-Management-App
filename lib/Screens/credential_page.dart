import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_developer_app/auth/auth_service.dart';
import 'package:google_developer_app/auth/auth_wrapper.dart';
import 'package:google_developer_app/Widget/elevatedbutton.dart';

class RemainingCredential extends StatefulWidget {
  const RemainingCredential({super.key});

  @override
  State<RemainingCredential> createState() => _RemainingCredentialState();
}

class _RemainingCredentialState extends State<RemainingCredential> {
  final TextEditingController studentIdController = TextEditingController();
  bool loading = false;
  final AuthService authService = AuthService();

  Future<void> _submitStudentId() async {
    final studentId = studentIdController.text.trim();

    if (studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Student ID")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // Complete first-time Google sign-in by saving student ID in Firestore
      final user = await authService.completeGoogleSignIn(studentId: studentId);

      if (user != null) {
        // Navigate to homepage
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RoleRedirect(uid: user.uid)),
        );
      } else {
        throw Exception("User not found after Google Sign-In.");
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Firebase error: ${e.message}")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: screenheight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: screenheight * 0.098,
              ),
              Padding(
                padding: EdgeInsets.only(
                    left: screenwidth * 0.1,
                    top: screenheight * 0.002,
                    bottom: screenheight * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Complete Profile",
                        style: Theme.of(context).textTheme.bodyLarge),
                    SizedBox(
                      height: screenheight * 0.01,
                    ),
                    Text("Enter your Student ID",
                        style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      colors: [
                        Color.fromARGB(255, 26, 31, 39),
                        Color.fromARGB(255, 20, 24, 32),
                        Color.fromARGB(255, 20, 24, 30),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      topRight: Radius.circular(60),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: screenheight * 0.04,
                      horizontal: screenwidth * 0.04,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: screenheight * 0.015,
                            horizontal: screenwidth * 0.04,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: screenheight * 0.05),
                              // Student ID TextField
                              TextField(
                                controller: studentIdController,
                                style: TextStyle(
                                    fontSize: screenwidth * 0.040),
                                decoration: InputDecoration(
                                  hintText: "Student ID",
                                  hintStyle: Theme.of(context)
                                      .inputDecorationTheme
                                      .hintStyle,
                                  border: Theme.of(context)
                                      .inputDecorationTheme
                                      .border,
                                  focusedBorder: Theme.of(context)
                                      .inputDecorationTheme
                                      .focusedBorder,
                                  enabledBorder: Theme.of(context)
                                      .inputDecorationTheme
                                      .enabledBorder,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: screenheight * 0.02,
                                    horizontal: screenwidth * 0.03,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: screenheight * 0.05,
                              ),
                              loading
                                  ? CircularProgressIndicator(
                                      color: Color(0xFF19D99F),
                                    )
                                  : SizedBox(
                                      child: GradientButton(
                                        onPressed: _submitStudentId,
                                        text: "Continue",
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    studentIdController.dispose();
    super.dispose();
  }
}
