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

class MemberHome extends StatefulWidget {
  const MemberHome({super.key});

  @override
  State<MemberHome> createState() => _MemberHomeState();
}

class _MemberHomeState extends State<MemberHome> {
  int _currentIndex = 0;
  final _authService = AuthService();
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
      HomeTab(uid: uid, firestore: _firestore),
      MeetTab(uid: uid, firestore: _firestore),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.meeting_room), label: 'Meetings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// -------------------- HOME TAB --------------------
class HomeTab extends StatelessWidget {
  final String uid;
  final FirestoreService firestore;

  const HomeTab({super.key, required this.uid, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.streamUserDoc(uid),
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
                  Text('Error loading data', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }
          
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          final chapterId = userData['chapterId'] ?? '';
          final teamId = userData['teamId'] ?? '';

          if (chapterId.isEmpty || teamId.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(screenwidth * 0.04),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off,
                        size: screenwidth * 0.2,
                        color: Colors.grey),
                    SizedBox(height: screenheight * 0.02),
                    Text('You are not in any team yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(screenwidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  color: const Color(0xFF151A1E),
                  child: Padding(
                    padding: EdgeInsets.all(screenwidth * 0.04),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          name: userData['name'] ?? 'Member',
                          photoUrl: userData['photoUrl'],
                          radius: screenwidth * 0.08,
                        ),
                        SizedBox(width: screenwidth * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome back!',
                                  style: Theme.of(context).textTheme.bodySmall),
                              SizedBox(height: screenheight * 0.005),
                              Text(userData['name'] ?? 'Member',
                                  style: Theme.of(context).textTheme.titleLarge),
                              if (userData['semester'] != null && userData['semester'].isNotEmpty)
                                Text('Semester: ${userData['semester']}',
                                    style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenheight * 0.03),
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<List<QueryDocumentSnapshot>>(
                        future: firestore.getTeamMembers(
                            chapterId: chapterId, teamId: teamId),
                        builder: (context, memberSnapshot) {
                          if (memberSnapshot.connectionState == ConnectionState.waiting) {
                            return _StatCard(
                              title: 'Team Members',
                              value: '...',
                              icon: Icons.people,
                              color: const Color(0xFF19D99F),
                            );
                          }
                          final memberCount = memberSnapshot.hasData
                              ? memberSnapshot.data!.length
                              : 0;
                          return _StatCard(
                            title: 'Team Members',
                            value: memberCount.toString(),
                            icon: Icons.people,
                            color: const Color(0xFF19D99F),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenwidth * 0.03),
                    Expanded(
                      child: FutureBuilder<List<QueryDocumentSnapshot>>(
                        future: firestore.getMeetings(
                            chapterId: chapterId, teamId: teamId),
                        builder: (context, meetingSnapshot) {
                          if (meetingSnapshot.connectionState == ConnectionState.waiting) {
                            return _StatCard(
                              title: 'Meetings',
                              value: '...',
                              icon: Icons.meeting_room,
                              color: const Color(0xFF00B2FF),
                            );
                          }
                          final meetingCount = meetingSnapshot.hasData
                              ? meetingSnapshot.data!.length
                              : 0;
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
                ),
                SizedBox(height: screenheight * 0.03),
                Text('Team Members',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: screenheight * 0.02),
                FutureBuilder<List<QueryDocumentSnapshot>>(
                  future: firestore.getTeamMembers(
                      chapterId: chapterId, teamId: teamId),
                  builder: (context, teamSnapshot) {
                    if (teamSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (teamSnapshot.hasError) {
                      return Center(
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: screenwidth * 0.15, color: Colors.red),
                            SizedBox(height: screenheight * 0.02),
                            Text('Error loading members', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      );
                    }
                    
                    final members = teamSnapshot.data!;
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
                                Text('No team members yet (0 members)',
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
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member =
                            members[index].data() as Map<String, dynamic>;
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
          );
        },
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

// -------------------- MEET TAB --------------------
class MeetTab extends StatelessWidget {
  final String uid;
  final FirestoreService firestore;

  const MeetTab({
    super.key,
    required this.uid,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    final screenwidth = MediaQuery.of(context).size.width;
    final screenheight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.streamUserDoc(uid),
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
                  Text('Error loading meetings', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String chapterId = userData['chapterId'] ?? '';
          final String teamId = userData['teamId'] ?? '';

          if (chapterId.isEmpty || teamId.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(screenwidth * 0.04),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.meeting_room_outlined,
                        size: screenwidth * 0.2, color: Colors.grey),
                    SizedBox(height: screenheight * 0.02),
                    Text('No meetings available.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chapters')
                .doc(chapterId)
                .collection('teams')
                .doc(teamId)
                .collection('meetings')
                .orderBy('dateTime')
                .snapshots(),
            builder: (context, meetingSnap) {
              if (meetingSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (meetingSnap.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: screenwidth * 0.15, color: Colors.red),
                      SizedBox(height: screenheight * 0.02),
                      Text('Error loading meetings', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                );
              }

              final meetings = meetingSnap.data!.docs;

              if (meetings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(screenwidth * 0.04),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy,
                            size: screenwidth * 0.2, color: Colors.grey),
                        SizedBox(height: screenheight * 0.02),
                        Text('No meetings scheduled.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(screenwidth * 0.04),
                itemCount: meetings.length,
                itemBuilder: (context, index) {
                  final meeting =
                      meetings[index].data() as Map<String, dynamic>;
                  final meetingId = meetings[index].id;
                  final dateTime = meeting['dateTime'] as Timestamp;

                  return Card(
                    margin: EdgeInsets.only(bottom: screenheight * 0.01),
                    color: const Color(0xFF151A1E),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _isUpcoming(dateTime.toDate())
                            ? const Color(0xFF19D99F)
                            : Colors.grey,
                        child: Icon(Icons.meeting_room,
                            color: Colors.white, size: screenwidth * 0.05),
                      ),
                      title: Text(meeting['topic'] ?? 'No topic',
                          style: Theme.of(context).textTheme.headlineSmall),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: screenheight * 0.005),
                          Text(
                            DateFormat('MMM dd, yyyy - hh:mm a')
                                .format(dateTime.toDate()),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          SizedBox(height: screenheight * 0.005),
                          Text(
                            _isUpcoming(dateTime.toDate())
                                ? 'Upcoming'
                                : 'Past Meeting',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _isUpcoming(dateTime.toDate())
                                    ? const Color(0xFF19D99F)
                                    : Colors.grey),
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios,
                          color: const Color(0xFF19D99F),
                          size: screenwidth * 0.04),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF151A1E),
                            title: Text(meeting['topic'] ?? 'Meeting',
                                style: Theme.of(context).textTheme.titleLarge),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow('Topic',
                                    meeting['topic'] ?? 'No topic', context),
                                _InfoRow(
                                    'Date',
                                    DateFormat('MMMM dd, yyyy')
                                        .format(dateTime.toDate()),
                                    context),
                                _InfoRow(
                                    'Time',
                                    DateFormat('hh:mm a')
                                        .format(dateTime.toDate()),
                                    context),
                                _InfoRow('Status',
                                    _isUpcoming(dateTime.toDate())
                                        ? 'Upcoming'
                                        : 'Past',
                                    context),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close',
                                    style: TextStyle(color: Color(0xFF19D99F))),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  bool _isUpcoming(DateTime dateTime) {
    return dateTime.isAfter(DateTime.now());
  }
}

Widget _InfoRow(String label, String value, BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(value,
              style: Theme.of(context).textTheme.bodySmall),
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
                          name: userData['name'] ?? 'Member',
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
                  initialValue: userData['role'] ?? 'member',
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
                // Show semester in dashboard
                Card(
                  color: const Color(0xFF151A1E),
                  child: ListTile(
                    leading: const Icon(Icons.school, color: Color(0xFF19D99F)),
                    title: Text('Your Semester', style: Theme.of(context).textTheme.bodySmall),
                    subtitle: Text(
                      userData['semester'] != null && userData['semester'].toString().isNotEmpty
                          ? userData['semester']
                          : 'Not set. Click edit above.',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: widget.screenwidth * 0.04),
                    ),
                  ),
                ),
                SizedBox(height: widget.screenheight * 0.03),
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
