import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_developer_app/Screens/credential_page.dart';
import 'package:google_developer_app/Screens/signup.dart';
import 'package:google_developer_app/Widget/elevatedbutton.dart';
import 'package:google_developer_app/Widget/squaretile.dart';
import 'package:google_developer_app/auth/auth_service.dart';
import 'package:google_developer_app/auth/auth_wrapper.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final AuthService authService = AuthService();
  bool _obscureText = true;
  final FocusNode _focusNode = FocusNode();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

Future<void> _handleLogin() async {
  setState(() => loading = true);

  try {
    final user = await authService.loginWithEmail(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoleRedirect(uid: user.uid) ),
      );
    }
  } on FirebaseAuthException catch (e) {
    // Better error handling
    String message = '';
    if (e.code == 'user-not-found') {
      message = 'No account found with this email.';
    } else if (e.code == 'wrong-password') {
      message = 'Incorrect password.';
    } else {
      message = e.message ?? 'Login failed.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Login failed: $e')));
  } finally {
    if (mounted) setState(() => loading = false);
  }
}

  Future<void> _handleGoogleSignIn() async {
  setState(() => loading = true);

  try {
    final user = await authService.startGoogleSignIn();
    if (user == null) return; // User canceled

    final doc = await authService.getUserDoc(user.uid);

    if (!doc.exists) {
      // First-time Google user → navigate to student ID collection page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RemainingCredential()),
      );
    } else {
      // Existing user → navigate to homepage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoleRedirect(uid: user.uid)),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
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
                    Text("Login", style: Theme.of(context).textTheme.bodyLarge),
                    SizedBox(
                      height: screenheight * 0.01,
                    ),
                    Text("Welcome Back",
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
                              SizedBox(height: screenheight * 0.01),
                              // Email TextField
                              TextField(
                                controller: emailController,
                                style: TextStyle(
                                    fontSize:
                                        screenwidth * 0.040), // responsive
                                decoration: InputDecoration(
                                  hintText: "Email",
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
                                  ), // prevents big height
                                ),
                              ),
                              SizedBox(height: screenheight * 0.02),
                              // Password TextField
                              TextField(
                                controller: passwordController,
                                focusNode: _focusNode,
                                obscureText: _obscureText,
                                style: TextStyle(
                                    fontSize:
                                        screenwidth * 0.040), // responsive
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: TextStyle(color: Colors.grey),
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
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? CupertinoIcons.eye_slash_fill
                                          : CupertinoIcons.eye_fill,
                                      color: _focusNode.hasFocus
                                          ? Colors.blue.shade900
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.only(left: screenwidth * 0.4),
                                  child: TextButton(
                                    onPressed: () {
                                      // TODO: Implement forgot password
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Forgot password feature coming soon')),
                                      );
                                    },
                                    child: const Text('Forgot Password')),
                              ),
                              SizedBox(
                                height: screenheight * 0.03,
                              ),
                              SizedBox(
                                  child: GradientButton(
                                onPressed: _handleLogin,
                                text: "Login",
                              )),
                              SizedBox(
                                height: screenheight * 0.05,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Color(0xFF19D99F),
                                      thickness: 1.5,
                                    ),
                                  ),
                                  SizedBox(
                                    width: screenwidth * 0.02,
                                  ),
                                  Text(
                                    'Or Continue with',
                                    style: TextStyle(
                                        fontSize: screenheight * 0.025,
                                        color: Color(0xFF19D99F),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(
                                    width: screenwidth * 0.02,
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Color(0xFF19D99F),
                                      thickness: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: screenheight * 0.05,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SquareTile(
                                      image: "assets/images/googlelogo.png",
                                      onPressed: _handleGoogleSignIn),
                                  SizedBox(
                                    width: screenwidth * 0.06,
                                  ),
                                  SquareTile(
                                      image: "assets/images/outlooklogo.png",
                                      onPressed: () {}),
                                ],
                              ),
                              SizedBox(
                                height: screenheight * 0.04,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Dont have\'n an account',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    Signup()));
                                      },
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                        ),
                                      ))
                                ],
                              )
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
}
