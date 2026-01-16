import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const GradientButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    return Container(
      width: screenwidth,
      height: screenheight*0.060,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF19D99F), Color(0xFF00B2FF)], 
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: screenwidth*0.055,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),                 
        ),
      ),
    );
  }
}

class AppBtn extends StatelessWidget {
   
  final String text;
  final VoidCallback onPressed;
  const AppBtn({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    return Container(
      width: screenwidth,
      height: screenheight*0.060,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 168, 228, 100), 
        borderRadius: BorderRadius.circular(14),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: screenwidth*0.055,
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),                 
        ),
      ),
    );
  }
}
