import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_developer_app/Widget/elevatedbutton.dart';
import 'package:google_developer_app/Widget/editable_profile_field.dart';
import 'package:google_developer_app/Widget/profile_avatar.dart';
import 'package:google_developer_app/Widget/user_card.dart';
import 'package:google_developer_app/auth/auth_service.dart';
import 'package:google_developer_app/services/firestore.dart';
import 'package:google_developer_app/services/firestore_super_admin.dart';
import 'package:google_developer_app/services/storage_service.dart';
import 'package:google_developer_app/Screens/loginscreen.dart';

class SuperAdminHome extends StatefulWidget {
  const SuperAdminHome({super.key});

  @override
  State<SuperAdminHome> createState() => _SuperAdminHomeState();
}

class _SuperAdminHomeState extends State<SuperAdminHome> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final _superAdminService = SuperAdminService();
  final _firestore = FirestoreService();
  late String uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) uid = user.uid;
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    List<Widget> pages = [
      DashboardTab(
          uid: uid,
          superAdminService: _superAdminService,
          firestore: _firestore),
      ChaptersTab(
          superAdminService: _superAdminService, firestore: _firestore),
      UsersTab(firestore: _firestore),
      ProfileTab(
          uid: uid,
          firestore: _firestore,
          authService: _authService,
          screenwidth: screenwidth,
          screenheight: screenheight),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF151A1E),
        selectedItemColor: const Color(0xFF19D99F),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group), label: 'Chapters'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// -------------------- DASHBOARD TAB --------------------
class DashboardTab extends StatelessWidget {
  final String uid;
  final SuperAdminService superAdminService;
  final FirestoreService firestore;

  const DashboardTab({
    super.key,
    required this.uid,
    required this.superAdminService,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenwidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: superAdminService.getAllChapters(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final chapterCount = snapshot.hasData ? snapshot.data!.length : 0;
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Chapters',
                        value: chapterCount.toString(),
                        icon: Icons.group,
                        color: const Color(0xFF19D99F),
                      ),
                    ),
                    SizedBox(width: screenwidth * 0.03),
                    Expanded(
                      child: FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return _StatCard(
                              title: 'Total Users',
                              value: '...',
                              icon: Icons.people,
                              color: const Color(0xFF00B2FF),
                            );
                          }
                          final userCount =
                              userSnapshot.hasData ? userSnapshot.data!.docs.length : 0;
                          return _StatCard(
                            title: 'Total Users',
                            value: userCount.toString(),
                            icon: Icons.people,
                            color: const Color(0xFF00B2FF),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: screenheight * 0.03),
            Text('Recent Chapters',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: screenheight * 0.02),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: superAdminService.getAllChapters(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Check if there's an actual error (not just empty data)
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: screenwidth * 0.15, color: Colors.red),
                        SizedBox(height: screenheight * 0.02),
                        Text('Error loading chapters', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                
                // If we have data but it's empty, show empty state (not error)
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Card(
                    color: const Color(0xFF151A1E),
                    child: Padding(
                      padding: EdgeInsets.all(screenwidth * 0.04),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.group_off, size: screenwidth * 0.15, color: Colors.grey),
                            SizedBox(height: screenheight * 0.02),
                            Text('No chapters yet',
                          style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                final chapters = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = chapters[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.only(bottom: screenheight * 0.01),
                      color: const Color(0xFF151A1E),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF19D99F),
                          child: Text(
                            chapter['name']?[0]?.toString().toUpperCase() ?? 'C',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(chapter['name'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.headlineSmall),
                        subtitle: Text('Chapter Lead ID: ${chapter['chapterLeadId'] ?? 'N/A'}',
                            style: Theme.of(context).textTheme.bodySmall),
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: const Color(0xFF19D99F), size: screenwidth * 0.04),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    
    return Card(
      color: const Color(0xFF151A1E),
      child: Padding(
        padding: EdgeInsets.all(screenwidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: screenwidth * 0.08),
            SizedBox(height: screenwidth * 0.02),
            Text(title,
                style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: screenwidth * 0.01),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: screenwidth * 0.07, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// -------------------- CHAPTERS TAB --------------------
class ChaptersTab extends StatefulWidget {
  final SuperAdminService superAdminService;
  final FirestoreService firestore;

  const ChaptersTab({
    super.key,
    required this.superAdminService,
    required this.firestore,
  });

  @override
  State<ChaptersTab> createState() => _ChaptersTabState();
}

class _ChaptersTabState extends State<ChaptersTab> {
  final TextEditingController _chapterNameController = TextEditingController();
  String? _selectedChapterLeadId;

  Future<void> _createChapter() async {
    if (_chapterNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter chapter name')));
      return;
    }
    
    if (_selectedChapterLeadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a chapter lead. Chapter cannot be created without a chapter lead.')));
      return;
    }

    try {
      // Update user role to chapter_lead
      await widget.firestore.updateUserData(
        uid: _selectedChapterLeadId!,
        role: 'chapter_lead',
      );
      
      // Create chapter
      final chapterId = await widget.firestore.createChapter(
        name: _chapterNameController.text.trim(),
        chapterLeadId: _selectedChapterLeadId!,
      );
      
      // Update user's chapterId
      await widget.firestore.updateUserData(
        uid: _selectedChapterLeadId!,
        chapterId: chapterId,
      );
      
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chapter created successfully! Chapter lead assigned.')));
      _chapterNameController.clear();
      setState(() {
        _selectedChapterLeadId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteChapter(String chapterId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151A1E),
        title: const Text('Delete Chapter'),
        content: const Text('Are you sure you want to delete this chapter? This will also delete all teams and members.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.firestore.deleteChapter(chapterId);
        if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chapter deleted successfully')));
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Chapters'),
      ),
      body: Column(
        children: [
          // Create Chapter Form
          Card(
            margin: EdgeInsets.all(screenwidth * 0.04),
            color: const Color(0xFF151A1E),
            child: Padding(
              padding: EdgeInsets.all(screenwidth * 0.04),
                child: Column(
                  children: [
                    TextField(
                      controller: _chapterNameController,
                    style: TextStyle(fontSize: screenwidth * 0.040),
                      decoration: InputDecoration(
                        hintText: 'Enter chapter name',
                        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                        border: Theme.of(context).inputDecorationTheme.border,
                      focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                      enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: screenheight * 0.02,
                          horizontal: screenwidth * 0.03,
                        ),
                      ),
                    ),
                    SizedBox(height: screenheight * 0.02),
                  // User Dropdown for Chapter Lead
                  FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: widget.firestore.getAllUsers(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      
                      final users = userSnapshot.data ?? [];
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blueGrey),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenwidth * 0.03,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedChapterLeadId,
                            hint: Text(
                              'Select Chapter Lead',
                              style: Theme.of(context).inputDecorationTheme.hintStyle,
                            ),
                            isExpanded: true,
                            dropdownColor: const Color(0xFF151A1E),
                            style: TextStyle(
                              fontSize: screenwidth * 0.040,
                              color: Colors.white,
                            ),
                            items: users.map((userDoc) {
                              final user = userDoc.data() as Map<String, dynamic>;
                              final userId = userDoc.id;
                              final userName = user['name'] ?? 'Unknown';
                              final userEmail = user['email'] ?? '';
                              return DropdownMenuItem<String>(
                                value: userId,
                                child: Text('$userName ($userEmail)'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedChapterLeadId = value;
                                // Chapter lead selected
                              });
                            },
                          ),
                        ),
                      );
                    },
                    ),
                    SizedBox(height: screenheight * 0.02),
                    SizedBox(
                      width: double.infinity,
                      child: AppBtn(
                        onPressed: _createChapter,                      
                        text: 'Create Chapter',
                      ),
                    ),
                  ],
              ),
            ),
          ),
          // Chapters List
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: widget.superAdminService.getAllChapters(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: screenwidth * 0.15, color: Colors.red),
                        SizedBox(height: screenheight * 0.02),
                        Text('Error loading chapters', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                
                // Check for empty data (not an error)
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: screenwidth * 0.2, color: Colors.grey),
                        SizedBox(height: screenheight * 0.02),
                        Text('No chapters yet',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                
                final chapters = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(screenwidth * 0.04),
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter =
                          chapters[index].data() as Map<String, dynamic>;
                      final chapterId = chapters[index].id;
                      return _ChapterDetailCard(
                        chapter: chapter,
                        chapterId: chapterId,
                        firestore: widget.firestore,
                        superAdminService: widget.superAdminService,
                        onDelete: () => _deleteChapter(chapterId),
                        screenwidth: screenwidth,
                        screenheight: screenheight,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- USERS TAB --------------------
class UsersTab extends StatelessWidget {
  final FirestoreService firestore;

  const UsersTab({super.key, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // Check if there's an actual error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: screenwidth * 0.15, color: Colors.red),
                  SizedBox(height: screenheight * 0.02),
                  Text('Error: ${snapshot.error}', 
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }
          
          // If we have data but it's empty (no users at all)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: screenwidth * 0.2, color: Colors.grey),
                  SizedBox(height: screenheight * 0.02),
                  Text('No users yet',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          
          final users = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.all(screenwidth * 0.04),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              return UserCard(
                name: user['name'] ?? 'Unknown',
                email: user['email'] ?? '',
                role: user['role'] ?? 'member',
                semester: user['semester'] ?? '',
                photoUrl: user['photoUrl'],
                onTap: () {
                  _showUserRoleManagementDialog(context, userId, user, firestore);
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Detailed Chapter Card with Expandable View
class _ChapterDetailCard extends StatelessWidget {
  final Map<String, dynamic> chapter;
  final String chapterId;
  final FirestoreService firestore;
  final SuperAdminService superAdminService;
  final VoidCallback onDelete;
  final double screenwidth;
  final double screenheight;

  const _ChapterDetailCard({
    required this.chapter,
    required this.chapterId,
    required this.firestore,
    required this.superAdminService,
    required this.onDelete,
    required this.screenwidth,
    required this.screenheight,
  });

  @override
  Widget build(BuildContext context) {
              return Card(
                margin: EdgeInsets.only(bottom: screenheight * 0.01),
                color: const Color(0xFF151A1E),
      child: ExpansionTile(
                  leading: CircleAvatar(
          backgroundColor: const Color(0xFF19D99F),
                    child: Text(
            chapter['name']?[0]?.toString().toUpperCase() ?? 'C',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
        title: Text(
          chapter['name'] ?? 'Unknown Chapter',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            Text(
              'Chapter ID: $chapterId',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenwidth * 0.033),
            ),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(chapter['chapterLeadId'] ?? '')
                  .get(),
              builder: (context, leadSnapshot) {
                if (leadSnapshot.hasData && leadSnapshot.data!.exists) {
                  final leadData = leadSnapshot.data!.data() as Map<String, dynamic>;
                  return Text(
                    'Chapter Lead: ${leadData['name'] ?? 'Unknown'} (${leadData['email'] ?? 'N/A'})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF19D99F),
                      fontSize: screenwidth * 0.033,
                    ),
                  );
                }
                return Text(
                  'No chapter lead appointed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontSize: screenwidth * 0.033,
                  ),
                );
              },
            ),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: superAdminService.getTeamsForChapter(chapterId),
              builder: (context, teamSnapshot) {
                final teamCount = teamSnapshot.hasData ? teamSnapshot.data!.length : 0;
                return Text(
                  'Teams: $teamCount ${teamCount == 1 ? 'team' : 'teams'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenwidth * 0.033),
                );
              },
            ),
          ],
        ),
        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
            const Icon(Icons.expand_more, color: Color(0xFF19D99F)),
          ],
        ),
        children: [
          // Chapter Details Section
          Padding(
            padding: EdgeInsets.all(screenwidth * 0.04),
            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                Divider(color: Colors.grey.shade700),
                SizedBox(height: screenheight * 0.01),
                Text(
                  'Chapter Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF19D99F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenheight * 0.01),
                _InfoRow('Chapter Name', chapter['name'] ?? 'Unknown'),
                _InfoRow('Chapter ID', chapterId),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(chapter['chapterLeadId'] ?? '')
                      .get(),
                  builder: (context, leadSnapshot) {
                    if (leadSnapshot.hasData && leadSnapshot.data!.exists) {
                      final leadData = leadSnapshot.data!.data() as Map<String, dynamic>;
                      return Column(
                        children: [
                          _InfoRow('Chapter Lead Name', leadData['name'] ?? 'Unknown'),
                          _InfoRow('Chapter Lead Email', leadData['email'] ?? 'N/A'),
                          _InfoRow('Chapter Lead ID', chapter['chapterLeadId'] ?? 'N/A'),
                        ],
                      );
                    }
                    return _InfoRow('Chapter Lead', 'No chapter lead appointed');
                  },
                ),
                SizedBox(height: screenheight * 0.02),
                Divider(color: Colors.grey.shade700),
                SizedBox(height: screenheight * 0.01),
                Text(
                  'Teams in this Chapter',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF19D99F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenheight * 0.01),
              ],
            ),
          ),
          // Teams List
          FutureBuilder<List<QueryDocumentSnapshot>>(
            future: superAdminService.getTeamsForChapter(chapterId),
            builder: (context, teamSnapshot) {
              if (teamSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                );
              }
              
              if (teamSnapshot.hasError) {
                return Padding(
                  padding: EdgeInsets.all(screenwidth * 0.04),
                  child: Text(
                    'Error loading teams',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              
              final teams = teamSnapshot.data ?? [];
              
              if (teams.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(screenwidth * 0.04),
                  child: Column(
                    children: [
                      Icon(Icons.group_work_outlined, size: screenwidth * 0.1, color: Colors.grey),
                      SizedBox(height: screenheight * 0.01),
                      Text(
                        'No teams yet (0 teams)',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: teams.map((team) {
                  final teamData = team.data() as Map<String, dynamic>;
                  final teamId = team.id;
                  return _TeamDetailCard(
                    team: teamData,
                    teamId: teamId,
                    chapterId: chapterId,
                    firestore: firestore,
                    screenwidth: screenwidth,
                    screenheight: screenheight,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Detailed Team Card with Expandable View
class _TeamDetailCard extends StatelessWidget {
  final Map<String, dynamic> team;
  final String teamId;
  final String chapterId;
  final FirestoreService firestore;
  final double screenwidth;
  final double screenheight;

  const _TeamDetailCard({
    required this.team,
    required this.teamId,
    required this.chapterId,
    required this.firestore,
    required this.screenwidth,
    required this.screenheight,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: screenwidth * 0.04,
        vertical: screenheight * 0.005,
      ),
      color: const Color(0xFF1A1F26),
      child: ExpansionTile(
        leading: const Icon(Icons.group_work, color: Color(0xFF00B2FF)),
        title: Text(
          team['name'] ?? 'Unknown Team',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: screenwidth * 0.038),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team ID: $teamId',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenwidth * 0.030),
            ),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(team['teamLeadId'] ?? '')
                  .get(),
              builder: (context, leadSnapshot) {
                if (leadSnapshot.hasData && leadSnapshot.data!.exists) {
                  final leadData = leadSnapshot.data!.data() as Map<String, dynamic>;
                  return Text(
                    'Team Lead: ${leadData['name'] ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF00B2FF),
                      fontSize: screenwidth * 0.030,
                    ),
                  );
                }
                return Text(
                  'No team lead appointed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontSize: screenwidth * 0.030,
                ),
              );
            },
            ),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: firestore.getTeamMembers(chapterId: chapterId, teamId: teamId),
              builder: (context, memberSnapshot) {
                final memberCount = memberSnapshot.hasData ? memberSnapshot.data!.length : 0;
                return Text(
                  'Members: $memberCount ${memberCount == 1 ? 'member' : 'members'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenwidth * 0.030),
          );
        },
      ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(screenwidth * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey.shade700),
                SizedBox(height: screenheight * 0.01),
                Text(
                  'Team Details',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF00B2FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenheight * 0.01),
                _InfoRow('Team Name', team['name'] ?? 'Unknown'),
                _InfoRow('Team ID', teamId),
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(team['teamLeadId'] ?? '')
                      .get(),
                  builder: (context, leadSnapshot) {
                    if (leadSnapshot.hasData && leadSnapshot.data!.exists) {
                      final leadData = leadSnapshot.data!.data() as Map<String, dynamic>;
                      return Column(
                        children: [
                          _InfoRow('Team Lead Name', leadData['name'] ?? 'Unknown'),
                          _InfoRow('Team Lead Email', leadData['email'] ?? 'N/A'),
                          _InfoRow('Team Lead ID', team['teamLeadId'] ?? 'N/A'),
                        ],
                      );
                    }
                    return _InfoRow('Team Lead', 'No team lead appointed');
                  },
                ),
                SizedBox(height: screenheight * 0.01),
                Divider(color: Colors.grey.shade700),
                SizedBox(height: screenheight * 0.01),
                Text(
                  'Team Members',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF00B2FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenheight * 0.01),
              ],
            ),
          ),
          FutureBuilder<List<QueryDocumentSnapshot>>(
            future: firestore.getTeamMembers(chapterId: chapterId, teamId: teamId),
            builder: (context, memberSnapshot) {
              if (memberSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                );
              }
              
              final members = memberSnapshot.data ?? [];
              
              if (members.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(screenwidth * 0.04),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: screenwidth * 0.08, color: Colors.grey),
                      SizedBox(height: screenheight * 0.01),
                      Text(
                        'No members yet (0 members)',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: members.map((member) {
                  final memberData = member.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF19D99F),
                      backgroundImage: memberData['photoUrl'] != null && 
                          memberData['photoUrl'].toString().isNotEmpty &&
                          memberData['photoUrl'].toString().startsWith('http')
                          ? NetworkImage(memberData['photoUrl'])
                          : null,
                      child: memberData['photoUrl'] == null || 
                          memberData['photoUrl'].toString().isEmpty ||
                          !memberData['photoUrl'].toString().startsWith('http')
                          ? Text(
                              memberData['name']?[0]?.toString().toUpperCase() ?? 'M',
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(
                      memberData['name'] ?? 'Unknown',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memberData['email'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenwidth * 0.030),
                        ),
                        if (memberData['semester'] != null && memberData['semester'].toString().isNotEmpty)
                          Text(
                            'Semester: ${memberData['semester']}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenwidth * 0.028),
                          ),
                        Text(
                          'Member ID: ${member.id}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: screenwidth * 0.028,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _InfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF19D99F))),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// Role Management Dialog for Super Admin
void _showUserRoleManagementDialog(
  BuildContext context,
  String userId,
  Map<String, dynamic> user,
  FirestoreService firestore,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF151A1E),
      title: Text(user['name'] ?? 'User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Email', user['email'] ?? 'N/A'),
            _InfoRow('Student ID', user['studentId'] ?? 'N/A'),
            _InfoRow('Current Role', user['role'] ?? 'member'),
            _InfoRow('Semester', user['semester'] ?? 'N/A'),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Change Role:', style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF19D99F),
              fontSize: 16,
            )),
            const SizedBox(height: 12),
            // Make Chapter Lead Button
            SizedBox(
              width: double.infinity,
              child: AppBtn(
                text: 'Make Chapter Lead',
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await firestore.updateUserData(
                      uid: userId,
                      role: 'chapter_lead',
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User role updated to Chapter Lead')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // Make Team Lead Button
            SizedBox(
              width: double.infinity,
              child: AppBtn(
                text: 'Make Team Lead',
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await firestore.updateUserData(
                      uid: userId,
                      role: 'team_lead',
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User role updated to Team Lead')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // Make Member Button
            SizedBox(
              width: double.infinity,
              child: AppBtn(
                text: 'Make Member',
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await firestore.updateUserData(
                      uid: userId,
                      role: 'member',
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User role updated to Member')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Color(0xFF19D99F))),
        ),
      ],
    ),
  );
}

// -------------------- PROFILE TAB --------------------
class ProfileTab extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;
  final AuthService authService;
  final double screenwidth;
  final double screenheight;

  const ProfileTab({
    super.key,
    required this.uid,
    required this.firestore,
    required this.authService,
    required this.screenwidth,
    required this.screenheight,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;

  Future<void> _updateProfilePicture() async {
    final imageFile = await _storageService.showImageSourceDialog(context);
    if (imageFile == null || !mounted) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final downloadUrl = await _storageService.uploadProfilePicture(
        uid: widget.uid,
        imageFile: imageFile,
      );

      if (downloadUrl != null && mounted) {
        await widget.firestore.updateUserData(
          uid: widget.uid,
          photoUrl: downloadUrl,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image. Please try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: widget.firestore.streamUserDoc(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: widget.screenwidth * 0.15, color: Colors.red),
                  SizedBox(height: widget.screenheight * 0.02),
                  Text('Error loading profile', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: EdgeInsets.all(widget.screenwidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : ProfileAvatar(
                          name: userData['name'] ?? 'Admin',
                          photoUrl: userData['photoUrl'],
                    radius: widget.screenwidth * 0.15,
                          showEditButton: true,
                          onEditPressed: _updateProfilePicture,
                  ),
                ),
                SizedBox(height: widget.screenheight * 0.03),
                EditableProfileField(
                  title: 'Name',
                  initialValue: userData['name'] ?? 'N/A',
                  icon: Icons.person,
                  isEditable: false,
                  onSave: (value) {},
                ),
                SizedBox(height: widget.screenheight * 0.02),
                EditableProfileField(
                  title: 'Email',
                  initialValue: userData['email'] ?? 'N/A',
                  icon: Icons.email,
                  isEditable: false,
                  onSave: (value) {},
                ),
                SizedBox(height: widget.screenheight * 0.02),
                EditableProfileField(
                  title: 'Student ID',
                  initialValue: userData['studentId'] ?? 'N/A',
                  icon: Icons.badge,
                  isEditable: false,
                  onSave: (value) {},
                ),
                SizedBox(height: widget.screenheight * 0.02),
                EditableProfileField(
                  title: 'Role',
                  initialValue: userData['role'] ?? 'N/A',
                  icon: Icons.admin_panel_settings,
                  isEditable: false,
                  onSave: (value) {},
                ),
                SizedBox(height: widget.screenheight * 0.02),
                EditableProfileField(
                  title: 'Semester',
                  initialValue: userData['semester'] ?? '',
                  icon: Icons.school,
                  isEditable: true,
                  onSave: (value) async {
                    await widget.firestore.updateUserData(
                      uid: widget.uid,
                      semester: value,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Semester updated')),
                    );
                  },
                ),
                SizedBox(height: widget.screenheight * 0.02),
                // Show semester info in dashboard style
                Card(
                  color: const Color(0xFF151A1E),
                  child: ListTile(
                    leading: const Icon(Icons.info_outline, color: Color(0xFF19D99F)),
                    title: Text('Semester Info', style: Theme.of(context).textTheme.bodySmall),
                    subtitle: Text(
                      userData['semester'] != null && userData['semester'].toString().isNotEmpty
                          ? 'Current Semester: ${userData['semester']}'
                          : 'No semester set. Click edit icon above to add.',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: widget.screenwidth * 0.035),
                    ),
                  ),
                ),
                SizedBox(height: widget.screenheight * 0.04),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: 'Sign Out',
                    onPressed: () async {
                      await widget.authService.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const Loginscreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
