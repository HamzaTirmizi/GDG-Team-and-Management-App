import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  final String image;
  final VoidCallback onPressed;

  const SquareTile({
    super.key,
    required this.image,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;
    return InkWell(
        onTap: onPressed,        
        child: Container(
          width: screenwidth*0.14,
          height: screenheight*0.06,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image:
                  DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
                  
                  ),
        ),
  );
  }
}
