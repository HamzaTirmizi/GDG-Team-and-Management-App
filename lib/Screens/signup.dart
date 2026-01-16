import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_developer_app/Screens/credential_page.dart';
import 'package:google_developer_app/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_developer_app/Screens/loginscreen.dart';
import 'package:google_developer_app/Widget/elevatedbutton.dart';
import 'package:google_developer_app/Widget/squaretile.dart';
import 'package:google_developer_app/auth/auth_wrapper.dart';

class Signup extends StatefulWidget {

  const Signup({super.key});
  @override
  State<Signup> createState() => _Signup();

}

class _Signup extends State<Signup> {
  final AuthService authService = AuthService();
  bool _obscureText = true;
  final FocusNode _focusNode = FocusNode();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final studentIdController = TextEditingController();
  bool loading = false;

  Future<void> _handleSignup() async {
  if (nameController.text.trim().isEmpty ||
      studentIdController.text.trim().isEmpty ||
      emailController.text.trim().isEmpty ||
      passwordController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill all fields')),
    );
    return;
  }

  setState(() => loading = true);

  try {
    final user = await authService.signUpWithEmail(
      name: nameController.text.trim(),
      studentId: studentIdController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => RoleRedirect(uid: user.uid)),
      );
    }
  } on FirebaseAuthException catch (e) {
    String message = '';
    if (e.code == 'email-already-in-use') {
      message = 'This email is already registered.';
    } else if (e.code == 'weak-password') {
      message = 'Password is too weak.';
    } else {
      message = e.message ?? 'Signup failed';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Signup failed: $e')));
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
      body: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: screenheight*0.065,
            ),
            Padding(
              padding: EdgeInsets.only(left: screenwidth*0.1,top: screenheight*0.003,
                       bottom: screenheight*0.03
               ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sign Up",
                   style: Theme.of(context).textTheme.bodyLarge
                   ),  
                    SizedBox(height: screenheight*0.01,),
                   Text("Welcome to Google Developer Group",
                   style: Theme.of(context).textTheme.headlineSmall
                   ),                
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
    child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: screenheight * 0.03,
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
                  //Name
                  TextField(
                    controller: nameController,
                    style: TextStyle(fontSize: screenwidth * 0.040), // responsive
                    decoration: InputDecoration(
                      hintText: "Name",
                      hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                      border: Theme.of(context).inputDecorationTheme.border,
                      focusedBorder:
                          Theme.of(context).inputDecorationTheme.focusedBorder,
                      enabledBorder:
                          Theme.of(context).inputDecorationTheme.enabledBorder,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenheight * 0.02,
                        horizontal: screenwidth * 0.03,
                      ), // prevents big height
                    ),
                  ),
                  SizedBox(height: screenheight * 0.015),
                  //student id
                  TextField(
                    controller: studentIdController,
                    style: TextStyle(fontSize: screenwidth * 0.040), // responsive
                    decoration: InputDecoration(
                      hintText: "Student ID",
                      hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                      border: Theme.of(context).inputDecorationTheme.border,
                      focusedBorder:
                          Theme.of(context).inputDecorationTheme.focusedBorder,
                      enabledBorder:
                          Theme.of(context).inputDecorationTheme.enabledBorder,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenheight * 0.02,
                        horizontal: screenwidth * 0.03,
                      ), // prevents big height
                    ),
                  ),
                  SizedBox(height: screenheight * 0.015),
                  // Email TextField
                  TextField(
                    controller: emailController,
                    style: TextStyle(fontSize: screenwidth * 0.040), // responsive
                    decoration: InputDecoration(
                      hintText: "Email",
                      hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                      border: Theme.of(context).inputDecorationTheme.border,
                      focusedBorder:
                          Theme.of(context).inputDecorationTheme.focusedBorder,
                      enabledBorder:
                          Theme.of(context).inputDecorationTheme.enabledBorder,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenheight * 0.02,
                        horizontal: screenwidth * 0.03,
                      ), // prevents big height
                    ),
                  ),
                  SizedBox(height: screenheight * 0.015),
                  // Password TextField
                  TextField(
                    controller: passwordController,
                    focusNode: _focusNode,
                    obscureText: _obscureText,
                    style: TextStyle(fontSize: screenwidth * 0.040), // responsive                    
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: Theme.of(context).inputDecorationTheme.border,
                      focusedBorder:
                          Theme.of(context).inputDecorationTheme.focusedBorder,
                      enabledBorder:
                          Theme.of(context).inputDecorationTheme.enabledBorder,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenheight * 0.02,
                        horizontal: screenwidth * 0.03,
                      ),
                      suffixIcon: IconButton(
                      icon: Icon(
                _obscureText ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
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
                  SizedBox(height: screenheight*0.04,), 
                  SizedBox(child: GradientButton(onPressed: _handleSignup,text: "Sign Up",)),
                  SizedBox(height: screenheight*0.04,),
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
                  SizedBox(height: screenheight*0.04,), 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTile(image: "assets/images/googlelogo.png", onPressed: _handleGoogleSignIn),
                      SizedBox(width: screenwidth*0.06,),
                      SquareTile(image: "assets/images/outlooklogo.png", onPressed: (){}),                   
                    ],
                  ),
                  SizedBox(height: screenheight*0.02,),
                  Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    ' Already have\'n account',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    Loginscreen()));
                                      },
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                        ),
                                      ))
                ],
              ),]
            ),)
          ],
        ),
      ),
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}