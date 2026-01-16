import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_developer_app/auth/auth_service.dart';
import 'package:google_developer_app/services/firestore.dart';
import 'package:google_developer_app/Widget/elevatedbutton.dart';
import 'package:google_developer_app/Widget/editable_profile_field.dart';
import 'package:google_developer_app/Widget/profile_avatar.dart';
import 'package:google_developer_app/Widget/user_card.dart';
import 'package:google_developer_app/Screens/loginscreen.dart';
import 'package:google_developer_app/services/storage_service.dart';
import 'package:intl/intl.dart';

class ChapterLeadHome extends StatefulWidget {
  const ChapterLeadHome({super.key});

  @override
  State<ChapterLeadHome> createState() => _ChapterLeadHomeState();
}

class _ChapterLeadHomeState extends State<ChapterLeadHome> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final _firestore = FirestoreService();
  late String uid;
  String? chapterId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) uid = user.uid;
    _loadChapterId();
  }

  Future<void> _loadChapterId() async {
    final userDoc = await _firestore.getUserDoc(uid);
    if (userDoc.exists) {
      setState(() {
        chapterId = userDoc['chapterId'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      DashboardTab(
          uid: uid,
          chapterId: chapterId,
          firestore: _firestore),
      TeamsTab(
          chapterId: chapterId,
          firestore: _firestore),
      MeetingsTab(
          chapterId: chapterId,
          firestore: _firestore),
      ProfileTab(
          uid: uid,
          firestore: _firestore,
          authService: _authService),
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
              icon: Icon(Icons.group_work), label: 'Teams'),
          BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room), label: 'Meetings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// -------------------- DASHBOARD TAB --------------------
class DashboardTab extends StatelessWidget {
  final String uid;
  final String? chapterId;
  final FirestoreService firestore;

  const DashboardTab({
    super.key,
    required this.uid,
    required this.chapterId,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    if (chapterId == null || chapterId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chapter Lead Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: screenwidth * 0.2, color: Colors.grey),
              SizedBox(height: screenheight * 0.02),
              Text('You are not assigned to any chapter yet.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chapter Lead Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenwidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter Info
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chapters')
                  .doc(chapterId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator()));
                }
                
                if (snapshot.hasError) {
                  return Card(
                    color: const Color(0xFF151A1E),
                    child: Padding(
                      padding: EdgeInsets.all(screenwidth * 0.04),
                      child: Text('Error loading chapter info',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  );
                }
                
                final chapter = snapshot.data!.data() as Map<String, dynamic>;
                return Card(
                  color: const Color(0xFF151A1E),
                  child: Padding(
                    padding: EdgeInsets.all(screenwidth * 0.04),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: screenwidth * 0.08,
                          backgroundColor: const Color(0xFF19D99F),
                          child: Text(
                            chapter['name']?[0]?.toString().toUpperCase() ?? 'C',
                            style: TextStyle(
                                fontSize: screenwidth * 0.06,
                                color: Colors.white),
                          ),
                        ),
                        SizedBox(width: screenwidth * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(chapter['name'] ?? 'Unknown Chapter',
                                  style: Theme.of(context).textTheme.titleLarge),
                              SizedBox(height: screenheight * 0.01),
                              Text('Chapter Lead',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: screenheight * 0.03),
            // Stats
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: firestore.getTeams(chapterId!),
              builder: (context, teamSnapshot) {
                if (teamSnapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Teams',
                          value: '...',
                          icon: Icons.group_work,
                          color: const Color(0xFF19D99F),
                        ),
                      ),
                      SizedBox(width: screenwidth * 0.03),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Members',
                          value: '...',
                          icon: Icons.people,
                          color: const Color(0xFF00B2FF),
                        ),
                      ),
                    ],
                  );
                }
                
                final teamCount = teamSnapshot.hasData ? teamSnapshot.data!.length : 0;
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Teams',
                        value: teamCount.toString(),
                        icon: Icons.group_work,
                        color: const Color(0xFF19D99F),
                      ),
                    ),
                    SizedBox(width: screenwidth * 0.03),
                    Expanded(
                      child: FutureBuilder<int>(
                        future: _getTotalMembers(chapterId!, firestore),
                        builder: (context, memberSnapshot) {
                          final memberCount = memberSnapshot.data ?? 0;
                          return _StatCard(
                            title: 'Total Members',
                            value: memberCount.toString(),
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
            Text('Recent Teams',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: screenheight * 0.02),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: firestore.getTeams(chapterId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Card(
                    color: const Color(0xFF151A1E),
                    child: Padding(
                      padding: EdgeInsets.all(screenwidth * 0.04),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: screenwidth * 0.15, color: Colors.red),
                            SizedBox(height: screenheight * 0.02),
                            Text('Error loading teams',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                final teams = snapshot.data!;
                if (teams.isEmpty) {
                  return Card(
                    color: const Color(0xFF151A1E),
                    child: Padding(
                      padding: EdgeInsets.all(screenwidth * 0.04),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.group_work_outlined, size: screenwidth * 0.15, color: Colors.grey),
                            SizedBox(height: screenheight * 0.02),
                            Text('No teams yet. Create one!',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: teams.length > 3 ? 3 : teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.only(bottom: screenheight * 0.01),
                      color: const Color(0xFF151A1E),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00B2FF),
                          child: const Icon(Icons.group_work, color: Colors.white),
                        ),
                        title: Text(team['name'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.headlineSmall),
                        subtitle: Text('Lead: ${team['teamLeadId'] ?? 'N/A'}',
                            style: Theme.of(context).textTheme.bodySmall),
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: const Color(0xFF19D99F),
                            size: screenwidth * 0.04),
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

  Future<int> _getTotalMembers(String chapterId, FirestoreService firestore) async {
    final teams = await firestore.getTeams(chapterId);
    int total = 0;
    for (var team in teams) {
      final members = await firestore.getTeamMembers(
          chapterId: chapterId, teamId: team.id);
      total += members.length;
    }
    return total;
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
            Text(title, style: Theme.of(context).textTheme.bodySmall),
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

// -------------------- TEAMS TAB --------------------
class TeamsTab extends StatefulWidget {
  final String? chapterId;
  final FirestoreService firestore;

  const TeamsTab({
    super.key,
    required this.chapterId,
    required this.firestore,
  });

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  final TextEditingController _teamNameController = TextEditingController();
  String? _selectedTeamLeadId;

  Future<void> _createTeam() async {
    if (widget.chapterId == null || widget.chapterId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chapter ID not found')));
      return;
    }

    if (_teamNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter team name')));
      return;
    }
    
    if (_selectedTeamLeadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a team lead. Team cannot be created without a team lead.')));
      return;
    }

    try {
      // Update user role to team_lead
      await widget.firestore.updateUserData(
        uid: _selectedTeamLeadId!,
        role: 'team_lead',
      );
      
      // Create team
      final teamId = await widget.firestore.createTeam(
        chapterId: widget.chapterId!,
        name: _teamNameController.text.trim(),
        teamLeadId: _selectedTeamLeadId!,
      );
      
      // Update user's chapterId and teamId
      await widget.firestore.updateUserData(
        uid: _selectedTeamLeadId!,
        chapterId: widget.chapterId!,
        teamId: teamId,
      );
      
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Team created successfully! Team lead assigned.')));
      _teamNameController.clear();
      setState(() {
        _selectedTeamLeadId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteTeam(String teamId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151A1E),
        title: const Text('Delete Team'),
        content: const Text('Are you sure you want to delete this team? This will also remove all members.'),
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
        await widget.firestore.deleteTeam(
          chapterId: widget.chapterId!,
          teamId: teamId,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Team deleted')));
        setState(() {});
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _addMemberToTeam(String teamId) async {
    String? selectedMemberId;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF151A1E),
          title: const Text('Add Member to Team'),
          content: FutureBuilder<List<QueryDocumentSnapshot>>(
            future: widget.firestore.getAllUsers(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              final users = userSnapshot.data ?? [];
              // Filter out users already in this team
              return FutureBuilder<List<QueryDocumentSnapshot>>(
                future: widget.firestore.getTeamMembers(
                  chapterId: widget.chapterId!,
                  teamId: teamId,
                ),
                builder: (context, teamMembersSnapshot) {
                  final teamMemberIds = teamMembersSnapshot.data?.map((m) => m.id).toList() ?? [];
                  final availableUsers = users.where((u) => !teamMemberIds.contains(u.id)).toList();
                  
                  if (availableUsers.isEmpty) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: Text('No available users to add')),
                    );
                  }
                  
                  return SizedBox(
                    height: 300,
                    width: double.maxFinite,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.03,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedMemberId,
                          hint: Text(
                            'Select Member',
                            style: Theme.of(context).inputDecorationTheme.hintStyle,
                          ),
                          isExpanded: true,
                          dropdownColor: const Color(0xFF151A1E),
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.040,
                            color: Colors.white,
                          ),
                          items: availableUsers.map((userDoc) {
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
                            setDialogState(() {
                              selectedMemberId = value;
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            AppBtn(
              onPressed: () async {
                if (widget.chapterId == null || selectedMemberId == null) {
                  Navigator.pop(context);
                  return;
                }
                try {
                  await widget.firestore.addMemberToTeam(
                    chapterId: widget.chapterId!,
                    teamId: teamId,
                    memberUid: selectedMemberId!,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Member added')));
                  setState(() {});
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              text: 'Add',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    if (widget.chapterId == null || widget.chapterId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Teams')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: screenwidth * 0.2, color: Colors.grey),
              SizedBox(height: screenheight * 0.02),
              Text('You are not assigned to any chapter yet.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teams'),
      ),
      body: Column(
        children: [
          // Create Team Form
          Card(
            margin: EdgeInsets.all(screenwidth * 0.04),
            color: const Color(0xFF151A1E),
            child: Padding(
              padding: EdgeInsets.all(screenwidth * 0.04),
              child: Column(
                children: [
                  TextField(
                    controller: _teamNameController,
                    style: TextStyle(fontSize: screenwidth * 0.040),
                    decoration: InputDecoration(
                      hintText: 'Enter team name',
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
                  // User Dropdown for Team Lead
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
                            value: _selectedTeamLeadId,
                            hint: Text(
                              'Select Team Lead',
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
                                _selectedTeamLeadId = value;
                                // Team lead selected
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
                      onPressed: _createTeam,
                      text: 'Create Team',
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Teams List
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: widget.firestore.getTeams(widget.chapterId!),
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
                        Text('Error loading teams',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                
                final teams = snapshot.data!;
                if (teams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_work_outlined, size: screenwidth * 0.2, color: Colors.grey),
                        SizedBox(height: screenheight * 0.02),
                        Text('No teams yet',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(screenwidth * 0.04),
                    itemCount: teams.length,
                    itemBuilder: (context, index) {
                      final team = teams[index].data() as Map<String, dynamic>;
                      final teamId = teams[index].id;
                      return _TeamDetailCardChapterLead(
                        team: team,
                        teamId: teamId,
                        chapterId: widget.chapterId!,
                        firestore: widget.firestore,
                        onDelete: () => _deleteTeam(teamId),
                        onAddMember: () => _addMemberToTeam(teamId),
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

// Detailed Team Card for Chapter Lead
class _TeamDetailCardChapterLead extends StatelessWidget {
  final Map<String, dynamic> team;
  final String teamId;
  final String chapterId;
  final FirestoreService firestore;
  final VoidCallback onDelete;
  final VoidCallback onAddMember;
  final double screenwidth;
  final double screenheight;

  const _TeamDetailCardChapterLead({
    required this.team,
    required this.teamId,
    required this.chapterId,
    required this.firestore,
    required this.onDelete,
    required this.onAddMember,
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
          backgroundColor: const Color(0xFF00B2FF),
          child: const Icon(Icons.group_work, color: Colors.white),
        ),
        title: Text(
          team['name'] ?? 'Unknown Team',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team ID: $teamId',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: screenwidth * 0.033),
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
                      fontSize: screenwidth * 0.033,
                    ),
                  );
                }
                return Text(
                  'No team lead appointed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontSize: screenwidth * 0.033,
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
          Padding(
            padding: EdgeInsets.all(screenwidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey.shade700),
                SizedBox(height: screenheight * 0.01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Team Members',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF00B2FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: onAddMember,
                      icon: const Icon(Icons.person_add, color: Color(0xFF19D99F)),
                    ),
                  ],
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
              
              if (memberSnapshot.hasError) {
                return Padding(
                  padding: EdgeInsets.all(screenwidth * 0.04),
                  child: Text(
                    'Error loading members',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              
              final members = memberSnapshot.data ?? [];
              
              if (members.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(screenwidth * 0.04),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: screenwidth * 0.1, color: Colors.grey),
                      SizedBox(height: screenheight * 0.01),
                      Text(
                        'No members yet (0 members)',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: members.map((member) {
                  final memberData = member.data() as Map<String, dynamic>;
                  return UserCard(
                    name: memberData['name'] ?? 'Unknown',
                    email: memberData['email'] ?? '',
                    role: memberData['role'],
                    semester: memberData['semester'],
                    photoUrl: memberData['photoUrl'],
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF151A1E),
                            title: const Text('Remove Member'),
                            content: Text('Are you sure you want to remove ${memberData['name'] ?? 'this member'} from the team?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Remove', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          try {
                            await firestore.removeMemberFromTeam(
                              chapterId: chapterId,
                              teamId: teamId,
                              memberUid: member.id,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Member removed successfully')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
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

// -------------------- MEETINGS TAB --------------------
class MeetingsTab extends StatelessWidget {
  final String? chapterId;
  final FirestoreService firestore;

  const MeetingsTab({
    super.key,
    required this.chapterId,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    if (chapterId == null || chapterId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meetings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.meeting_room_outlined, size: screenwidth * 0.2, color: Colors.grey),
              SizedBox(height: screenheight * 0.02),
              Text('You are not assigned to any chapter yet.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chapter Meetings'),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: firestore.getTeams(chapterId!),
        builder: (context, teamSnapshot) {
          if (teamSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (teamSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: screenwidth * 0.15, color: Colors.red),
                  SizedBox(height: screenheight * 0.02),
                  Text('Error loading teams',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          
          final teams = teamSnapshot.data!;
          if (teams.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_work_outlined, size: screenwidth * 0.2, color: Colors.grey),
                  SizedBox(height: screenheight * 0.02),
                  Text('No teams yet',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(screenwidth * 0.04),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index].data() as Map<String, dynamic>;
              final teamId = teams[index].id;
              return Card(
                margin: EdgeInsets.only(bottom: screenheight * 0.02),
                color: const Color(0xFF151A1E),
                child: ExpansionTile(
                  leading: const Icon(Icons.group_work,
                      color: Color(0xFF00B2FF)),
                  title: Text(team['name'] ?? 'Unknown Team',
                      style: Theme.of(context).textTheme.headlineSmall),
                  children: [
                    FutureBuilder<List<QueryDocumentSnapshot>>(
                      future: firestore.getMeetings(
                          chapterId: chapterId!, teamId: teamId),
                      builder: (context, meetingSnapshot) {
                        if (meetingSnapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          );
                        }
                        
                        if (meetingSnapshot.hasError) {
                          return Padding(
                            padding: EdgeInsets.all(screenwidth * 0.04),
                            child: Text('Error loading meetings',
                                style: Theme.of(context).textTheme.bodySmall),
                          );
                        }
                        
                        final meetings = meetingSnapshot.data!;
                        if (meetings.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.all(screenwidth * 0.04),
                            child: Text('No meetings scheduled',
                                style: Theme.of(context).textTheme.bodySmall),
                          );
                        }
                        return Column(
                          children: meetings.map((meeting) {
                            final meetingData =
                                meeting.data() as Map<String, dynamic>;
                            final dateTime = meetingData['dateTime'] as Timestamp;
                            return ListTile(
                              leading: const Icon(Icons.meeting_room,
                                  color: Color(0xFF19D99F)),
                              title: Text(meetingData['topic'] ?? 'No topic',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              subtitle: Text(
                                  DateFormat('MMM dd, yyyy - hh:mm a')
                                      .format(dateTime.toDate()),
                                  style: Theme.of(context).textTheme.bodySmall),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------- PROFILE TAB --------------------
class ProfileTab extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;
  final AuthService authService;

  const ProfileTab({
    super.key,
    required this.uid,
    required this.firestore,
    required this.authService,
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
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

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
                  Icon(Icons.error_outline, size: screenwidth * 0.15, color: Colors.red),
                  SizedBox(height: screenheight * 0.02),
                  Text('Error loading profile', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: EdgeInsets.all(screenwidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : ProfileAvatar(
                          name: userData['name'] ?? 'Chapter Lead',
                          photoUrl: userData['photoUrl'],
                          radius: screenwidth * 0.15,
                          showEditButton: true,
                          onEditPressed: _updateProfilePicture,
                        ),
                ),
                SizedBox(height: screenheight * 0.03),
                EditableProfileField(
                  title: 'Name',
                  initialValue: userData['name'] ?? 'N/A',
                  icon: Icons.person,
                  isEditable: false,
                  onSave: (value) {},
                ),
                SizedBox(height: screenheight * 0.02),
                EditableProfileField(
                  title: 'Email',
                  initialValue: userData['email'] ?? 'N/A',
                  icon: Icons.email,
                  isEditable: false,
                  onSave: (value) {},
                ),
                SizedBox(height: screenheight * 0.02),
                EditableProfileField(
                  title: 'Student ID',
                  initialValue: userData['studentId'] ?? 'N/A',
                  icon: Icons.badge,
                  isEditable: false,
                  onSave: (value) {},
                ),
                SizedBox(height: screenheight * 0.02),
                EditableProfileField(
                  title: 'Role',
                  initialValue: userData['role'] ?? 'N/A',
                  icon: Icons.admin_panel_settings,
                  isEditable: false,
                  onSave: (value) {},
                ),
                SizedBox(height: screenheight * 0.02),
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
                SizedBox(height: screenheight * 0.02),
                Card(
                  color: const Color(0xFF151A1E),
                  child: ListTile(
                    leading: const Icon(Icons.school, color: Color(0xFF19D99F)),
                    title: Text('Your Semester', style: Theme.of(context).textTheme.bodySmall),
                    subtitle: Text(
                      userData['semester'] != null && userData['semester'].toString().isNotEmpty
                          ? userData['semester']
                          : 'Not set',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: screenwidth * 0.04),
                    ),
                  ),
                ),
                SizedBox(height: screenheight * 0.04),
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
