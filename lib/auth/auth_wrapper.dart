import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_developer_app/Screens/chapter_lead_screens/chapter_lead_home.dart';
import 'package:google_developer_app/Screens/loginscreen.dart';
import 'package:google_developer_app/Screens/member_screens/member_home.dart';
import 'package:google_developer_app/Screens/super_admin_screens/super_admin_home.dart';
import 'package:google_developer_app/Screens/team_lead_screens/team_lead_home.dart';
import '../services/firestore.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // If not logged in → direct go to LoginScreen
    if (user == null) {
      return const Loginscreen();
    }

    // If logged in → go to role-based home directly
    return RoleRedirect(uid: user.uid);
  }
}


class RoleRedirect extends StatefulWidget {
  final String uid;
  const RoleRedirect({super.key, required this.uid});

  @override
  State<RoleRedirect> createState() => _RoleRedirectState();
}

class _RoleRedirectState extends State<RoleRedirect> {

  @override
  void initState() {
    super.initState();
    _redirectUser();
  }

  Future<void> _redirectUser() async {
    final firestore = FirestoreService();
    final userDoc = await firestore.getUserDoc(widget.uid);

    if (!userDoc.exists) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const Loginscreen()), // or RemainingCredential for first-time Google users
  );
  return;
}


    final role = userDoc['role'];

    Widget screen;

    if (role == 'super_admin') {
      screen = const SuperAdminHome();
    } else if (role == 'chapter_lead') {
      screen = const ChapterLeadHome();
    } else if (role == 'team_lead') {
      screen = const TeamLeadHome();
    } else {
      screen = const MemberHome();
    }

    // Run navigation AFTER build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
