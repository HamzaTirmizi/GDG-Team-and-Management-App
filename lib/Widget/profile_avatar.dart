import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;
  final VoidCallback? onEditPressed;
  final bool showEditButton;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    required this.radius,
    this.onEditPressed,
    this.showEditButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF19D99F),
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty && photoUrl!.startsWith('http')
              ? NetworkImage(photoUrl!)
              : null,
          child: photoUrl == null || photoUrl!.isEmpty || !photoUrl!.startsWith('http')
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: radius * 0.5,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (showEditButton && onEditPressed != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEditPressed,
              child: Container(
                padding: EdgeInsets.all(screenwidth * 0.02),
                decoration: BoxDecoration(
                  color: const Color(0xFF19D99F),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0B0E11),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: screenwidth * 0.045,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
