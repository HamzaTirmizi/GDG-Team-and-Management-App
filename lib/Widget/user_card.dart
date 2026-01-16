import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String? role;
  final String? semester;
  final String? photoUrl;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserCard({
    super.key,
    required this.name,
    required this.email,
    this.role,
    this.semester,
    this.photoUrl,
    this.onTap,
    this.trailing,
  });

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'super_admin':
        return Colors.red;
      case 'chapter_lead':
        return Colors.orange;
      case 'team_lead':
        return Colors.blue;
      default:
        return const Color(0xFF19D99F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    return Card(
      margin: EdgeInsets.only(bottom: screenheight * 0.01),
      color: const Color(0xFF151A1E),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: screenwidth * 0.065,
          backgroundColor: _getRoleColor(role),
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty && photoUrl!.startsWith('http')
              ? NetworkImage(photoUrl!)
              : null,
          child: photoUrl == null || photoUrl!.isEmpty || !photoUrl!.startsWith('http')
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenwidth * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenwidth * 0.035),
            ),
            if (role != null)
              Text(
                'Role: $role',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getRoleColor(role),
                      fontSize: screenwidth * 0.033,
                    ),
              ),
            if (semester != null && semester!.isNotEmpty)
              Text(
                'Semester: $semester',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenwidth * 0.033),
              ),
          ],
        ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios,
              color: const Color(0xFF19D99F),
              size: screenwidth * 0.04,
            ),
      ),
    );
  }
}
