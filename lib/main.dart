import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_developer_app/Screens/splashscreen.dart';
// ignore: unused_import
import 'package:google_developer_app/auth/auth_wrapper.dart';
import 'package:google_developer_app/services/firebase_options.dart';

import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E11),
        primaryColor: Color.fromARGB(255, 56, 73, 91),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF19D99F),
          secondary: Color(0xFF00B2FF),
          surface: Color(0xFF151A1E),
        ),
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.nunito(
            color: const Color.fromARGB(255, 232, 230, 230),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: screenwidth * 0.12,
          ),
          bodyMedium: GoogleFonts.smoochSans(
              color: const Color.fromARGB(255, 232, 230, 230),
              letterSpacing: 1,
              fontSize: screenwidth * 0.070,
              fontWeight: FontWeight.w600),
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontSize: screenwidth * 0.055,
          ),
          headlineSmall: TextStyle(
            color: Colors.white,
            fontSize: screenwidth * 0.045,
          ),
          bodySmall: TextStyle(
              fontSize: screenwidth * 0.040,
              color: Color(0xFF19D99F),
              fontWeight: FontWeight.w500),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0E11),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blueGrey),
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: Colors.blueGrey)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(
                color: Colors.blue.shade900,
                width: 2,
              )),
          hintStyle:
              TextStyle(fontSize: screenwidth * 0.040, color: Colors.grey),
        ),
      ),
      home: SplashScreen(),
      initialRoute: '/SplashScreen',
    
    );
  }
}
