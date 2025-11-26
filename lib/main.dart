import 'package:flutter/material.dart';
import 'package:gdg_app/Screens/loginscreen.dart';
import 'package:gdg_app/Screens/splashscreen.dart';

final ThemeData gdgDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0B0E11), 
  primaryColor: const Color(0xFF19D99F), 
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF19D99F), 
    secondary: Color(0xFF00B2FF),
    surface: Color(0xFF151A1E), 
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
    titleLarge: TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    ),
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
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF151A1E), 
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF232A30)),
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF232A30)),
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF19D99F), width: 2),
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    hintStyle: TextStyle(color: Color(0xFF6E6E6E)),
  ),
);


void main(){
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: gdgDarkTheme,
      home: SplashScreen(),
      initialRoute: '/SplashScreen',
      routes: {
        '/SplashScreen':(context) => SplashScreen(),
        '/login':(context) => Loginscreen()
      },
    );
  }
}