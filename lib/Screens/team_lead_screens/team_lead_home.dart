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

class TeamLeadHome extends StatefulWidget {
  const TeamLeadHome({super.key});

  @override
  State<TeamLeadHome> createState() => _TeamLeadHomeState();
}

class _TeamLeadHomeState extends State<TeamLeadHome> {
  int _currentIndex = 0;
  final _authService = AuthService();
  final _firestore = FirestoreService();
  late String uid;
  String? chapterId;
  String? teamId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) uid = user.uid;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userDoc = await _firestore.getUserDoc(uid);
    if (userDoc.exists) {
      setState(() {
        chapterId = userDoc['chapterId'];
        teamId = userDoc['teamId'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      DashboardTab(
          uid: uid,
          chapterId: chapterId,
          teamId: teamId,
          firestore: _firestore),
      MembersTab(
          chapterId: chapterId,
          teamId: teamId,
          firestore: _firestore),
      MeetingsTab(
          chapterId: chapterId,
          teamId: teamId,
          firestore: _firestore,
          uid: uid),
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
              icon: Icon(Icons.people), label: 'Members'),
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
  final String? teamId;
  final FirestoreService firestore;

  const DashboardTab({
    super.key,
    required this.uid,
    required this.chapterId,
    required this.teamId,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    if (chapterId == null || teamId == null || chapterId!.isEmpty || teamId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Lead Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: screenwidth * 0.2, color: Colors.grey),
              SizedBox(height: screenheight * 0.02),
              Text('You are not assigned to any team yet.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Lead Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenwidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team Info
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('chapters')
                  .doc(chapterId)
                  .collection('teams')
                  .doc(teamId)
                  .get(),
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
                      child: Text('Error loading team info',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  );
                }
                
                final team = snapshot.data!.data() as Map<String, dynamic>;
                return Card(
                  color: const Color(0xFF151A1E),
                  child: Padding(
                    padding: EdgeInsets.all(screenwidth * 0.04),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: screenwidth * 0.08,
                          backgroundColor: const Color(0xFF00B2FF),
                          child: const Icon(Icons.group_work, color: Colors.white),
                        ),
                        SizedBox(width: screenwidth * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(team['name'] ?? 'Unknown Team',
                                  style: Theme.of(context).textTheme.titleLarge),
                              SizedBox(height: screenheight * 0.01),
                              Text('Team Lead',
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
              future: firestore.getTeamMembers(chapterId: chapterId!, teamId: teamId!),
              builder: (context, memberSnapshot) {
                if (memberSnapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Team Members',
                          value: '...',
                          icon: Icons.people,
                          color: const Color(0xFF19D99F),
                        ),
                      ),
                      SizedBox(width: screenwidth * 0.03),
                      Expanded(
                        child: _StatCard(
                          title: 'Meetings',
                          value: '...',
                          icon: Icons.meeting_room,
                          color: const Color(0xFF00B2FF),
                        ),
                      ),
                    ],
                  );
                }
                
                final memberCount = memberSnapshot.hasData ? memberSnapshot.data!.length : 0;
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Team Members',
                        value: memberCount.toString(),
                        icon: Icons.people,
                        color: const Color(0xFF19D99F),
                      ),
                    ),
                    SizedBox(width: screenwidth * 0.03),
                    Expanded(
                      child: FutureBuilder<List<QueryDocumentSnapshot>>(
                        future: firestore.getMeetings(chapterId: chapterId!, teamId: teamId!),
                        builder: (context, meetingSnapshot) {
                          final meetingCount = meetingSnapshot.hasData ? meetingSnapshot.data!.length : 0;
                          return _StatCard(
                            title: 'Meetings',
                            value: meetingCount.toString(),
                            icon: Icons.meeting_room,
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
            Text('Recent Members',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: screenheight * 0.02),
            FutureBuilder<List<QueryDocumentSnapshot>>(
              future: firestore.getTeamMembers(chapterId: chapterId!, teamId: teamId!),
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
                            Text('Error loading members',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                final members = snapshot.data!;
                if (members.isEmpty) {
                  return Card(
                    color: const Color(0xFF151A1E),
                    child: Padding(
                      padding: EdgeInsets.all(screenwidth * 0.04),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: screenwidth * 0.15, color: Colors.grey),
                            SizedBox(height: screenheight * 0.02),
                            Text('No members yet',
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
                  itemCount: members.length > 3 ? 3 : members.length,
                  itemBuilder: (context, index) {
                    final member = members[index].data() as Map<String, dynamic>;
                    return UserCard(
                      name: member['name'] ?? 'Unknown',
                      email: member['email'] ?? '',
                      role: member['role'],
                      semester: member['semester'],
                      photoUrl: member['photoUrl'],
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

// -------------------- MEMBERS TAB --------------------
class MembersTab extends StatefulWidget {
  final String? chapterId;
  final String? teamId;
  final FirestoreService firestore;

  const MembersTab({
    super.key,
    required this.chapterId,
    required this.teamId,
    required this.firestore,
  });

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  String? _selectedMemberId;

  Future<void> _addMember() async {
    if (widget.chapterId == null ||
        widget.teamId == null ||
        _selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a member')));
      return;
    }

    try {
      await widget.firestore.addMemberToTeam(
        chapterId: widget.chapterId!,
        teamId: widget.teamId!,
        memberUid: _selectedMemberId!,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Member added')));
      setState(() {
        _selectedMemberId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    if (widget.chapterId == null || widget.teamId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Members')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_off, size: screenwidth * 0.2, color: Colors.grey),
              SizedBox(height: screenheight * 0.02),
              Text('You are not assigned to any team yet.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
      ),
      body: Column(
        children: [
          // Add Member Form
          Card(
            margin: EdgeInsets.all(screenwidth * 0.04),
            color: const Color(0xFF151A1E),
            child: Padding(
              padding: EdgeInsets.all(screenwidth * 0.04),
              child: Column(
                children: [
                  // User Dropdown for Member
                  FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: widget.firestore.getAllUsers(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      
                      final users = userSnapshot.data ?? [];
                      // Filter out users already in this team
                      return FutureBuilder<List<QueryDocumentSnapshot>>(
                        future: widget.firestore.getTeamMembers(
                          chapterId: widget.chapterId!,
                          teamId: widget.teamId!,
                        ),
                        builder: (context, teamMembersSnapshot) {
                          final teamMemberIds = teamMembersSnapshot.data?.map((m) => m.id).toList() ?? [];
                          final availableUsers = users.where((u) => !teamMemberIds.contains(u.id)).toList();
                          
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
                                value: _selectedMemberId,
                                hint: Text(
                                  availableUsers.isEmpty ? 'No available users' : 'Select Member',
                                  style: Theme.of(context).inputDecorationTheme.hintStyle,
                                ),
                                isExpanded: true,
                                dropdownColor: const Color(0xFF151A1E),
                                style: TextStyle(
                                  fontSize: screenwidth * 0.040,
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
                                onChanged: availableUsers.isEmpty ? null : (value) {
                                  setState(() {
                                    _selectedMemberId = value;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: screenheight * 0.02),
                  SizedBox(
                    width: double.infinity,
                    child: AppBtn(
                      onPressed: _addMember,
                      text: 'Add Member',
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Members List
          Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot>>(
              future: widget.firestore.getTeamMembers(
                  chapterId: widget.chapterId!, teamId: widget.teamId!),
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
                        Text('Error loading members',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                
                final members = snapshot.data!;
                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: screenwidth * 0.2, color: Colors.grey),
                        SizedBox(height: screenheight * 0.02),
                        Text('No members yet (0 members)',
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
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member =
                          members[index].data() as Map<String, dynamic>;
                      final memberUid = members[index].id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF19D99F),
                          backgroundImage: member['photoUrl'] != null && member['photoUrl'].toString().isNotEmpty
                              ? NetworkImage(member['photoUrl'])
                              : null,
                          child: member['photoUrl'] == null || member['photoUrl'].toString().isEmpty
                              ? Text(
                                  member['name']?[0]?.toString().toUpperCase() ?? 'M',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(member['name'] ?? 'Unknown',
                            style: Theme.of(context).textTheme.headlineSmall),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(member['email'] ?? '',
                                style: Theme.of(context).textTheme.bodySmall),
                            if (member['semester'] != null && member['semester'].toString().isNotEmpty)
                              Text('Semester: ${member['semester']}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: MediaQuery.of(context).size.width * 0.033)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () async {
                            try {
                              await widget.firestore.removeMemberFromTeam(
                                chapterId: widget.chapterId!,
                                teamId: widget.teamId!,
                                memberUid: memberUid,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Member removed successfully')),
                              );
                              setState(() {});
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                        ),
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

// -------------------- MEETINGS TAB --------------------
class MeetingsTab extends StatefulWidget {
  final String? chapterId;
  final String? teamId;
  final FirestoreService firestore;
  final String uid;

  const MeetingsTab({
    super.key,
    required this.chapterId,
    required this.teamId,
    required this.firestore,
    required this.uid,
  });

  @override
  State<MeetingsTab> createState() => _MeetingsTabState();
}

class _MeetingsTabState extends State<MeetingsTab> {
  final TextEditingController _topicController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _scheduleMeeting() async {
    if (widget.chapterId == null ||
        widget.teamId == null ||
        _topicController.text.trim().isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      await widget.firestore.scheduleMeeting(
        chapterId: widget.chapterId!,
        teamId: widget.teamId!,
        topic: _topicController.text.trim(),
        dateTime: _selectedDate!,
        createdBy: widget.uid,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Meeting scheduled')));
      _topicController.clear();
      setState(() {
        _selectedDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _markAttendance(
      String meetingId, String memberUid, String status) async {
    if (widget.chapterId == null || widget.teamId == null) return;

    try {
      await widget.firestore.markAttendance(
        chapterId: widget.chapterId!,
        teamId: widget.teamId!,
        meetingId: meetingId,
        memberUid: memberUid,
        status: status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Marked as $status')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    if (widget.chapterId == null || widget.teamId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meetings')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.meeting_room_outlined, size: screenwidth * 0.2, color: Colors.grey),
              SizedBox(height: screenheight * 0.02),
              Text('You are not assigned to any team yet.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Meetings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF151A1E),
                  title: const Text('Schedule Meeting'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _topicController,
                        style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.040),
                        decoration: InputDecoration(
                          hintText: 'Enter meeting topic',
                          hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                          border: Theme.of(context).inputDecorationTheme.border,
                          focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
                          enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: MediaQuery.of(context).size.height * 0.02,
                            horizontal: MediaQuery.of(context).size.width * 0.03,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppBtn(
                        onPressed: _selectDate,
                        text: _selectedDate == null
                            ? 'Select Date & Time'
                            : DateFormat('MMM dd, yyyy - hh:mm a')
                                .format(_selectedDate!),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                    ),
                    AppBtn(
                      onPressed: () {
                        Navigator.pop(context);
                        _scheduleMeeting();
                      },
                      text: 'Schedule',
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chapters')
            .doc(widget.chapterId)
            .collection('teams')
            .doc(widget.teamId)
            .collection('meetings')
            .orderBy('dateTime')
            .snapshots(),
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
                  Text('Error loading meetings',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          
          final meetings = snapshot.data!.docs;
          if (meetings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: screenwidth * 0.2, color: Colors.grey),
                  SizedBox(height: screenheight * 0.02),
                  Text('No meetings scheduled',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(screenwidth * 0.04),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index].data() as Map<String, dynamic>;
              final meetingId = meetings[index].id;
              final dateTime = meeting['dateTime'] as Timestamp;
              return Card(
                margin: EdgeInsets.only(bottom: screenheight * 0.01),
                color: const Color(0xFF151A1E),
                child: ExpansionTile(
                  leading: const Icon(Icons.meeting_room,
                      color: Color(0xFF19D99F)),
                  title: Text(meeting['topic'] ?? 'No topic',
                      style: Theme.of(context).textTheme.headlineSmall),
                  subtitle: Text(
                      DateFormat('MMM dd, yyyy - hh:mm a')
                          .format(dateTime.toDate()),
                      style: Theme.of(context).textTheme.bodySmall),
                  children: [
                    FutureBuilder<List<QueryDocumentSnapshot>>(
                      future: widget.firestore.getTeamMembers(
                          chapterId: widget.chapterId!, teamId: widget.teamId!),
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
                            child: Text('Error loading members',
                                style: Theme.of(context).textTheme.bodyMedium),
                          );
                        }
                        
                        final members = memberSnapshot.data!;
                        if (members.isEmpty) {
                          return Padding(
                            padding: EdgeInsets.all(screenwidth * 0.04),
                            child: Text('No members in this team',
                                style: Theme.of(context).textTheme.bodyMedium),
                          );
                        }
                        
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Mark Attendance',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ),
                            ...members.map((member) {
                              final memberData =
                                  member.data() as Map<String, dynamic>;
                              final memberUid = member.id;
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('chapters')
                                    .doc(widget.chapterId)
                                    .collection('teams')
                                    .doc(widget.teamId)
                                    .collection('meetings')
                                    .doc(meetingId)
                                    .collection('attendance')
                                    .doc(memberUid)
                                    .get(),
                                builder: (context, attendanceSnapshot) {
                                  final attendanceData =
                                      attendanceSnapshot.data?.data() as Map<String, dynamic>?;
                                  final status = attendanceData?['status'] ?? 'Not Marked';
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: status == 'Present'
                                          ? Colors.green
                                          : status == 'Absent'
                                              ? Colors.red
                                              : status == 'Late'
                                                  ? Colors.orange
                                                  : Colors.grey,
                                      child: Text(
                                        memberData['name']?[0]?.toString().toUpperCase() ?? 'M',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(memberData['name'] ?? 'Unknown',
                                        style: Theme.of(context).textTheme.bodySmall),
                                    subtitle: Text('Status: $status',
                                        style: Theme.of(context).textTheme.bodySmall),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check, color: Colors.green),
                                          onPressed: () => _markAttendance(
                                              meetingId, memberUid, 'Present'),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () => _markAttendance(
                                              meetingId, memberUid, 'Absent'),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.schedule, color: Colors.orange),
                                          onPressed: () => _markAttendance(
                                              meetingId, memberUid, 'Late'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ],
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
                          name: userData['name'] ?? 'Team Lead',
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
