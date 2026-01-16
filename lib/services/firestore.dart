// lib/services/firestore.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------- User Management --------------------

  // Save a new user
  Future<void> saveUserData({
    required String uid,
    required String name,
    required String studentId,
    required String email,
    required String password,
    required String role,
    String? semester,
    String? photoUrl,
    String? chapterId,
    String? teamId,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'studentId': studentId,
      'email': email,
      'password': password,
      'role': role,
      'semester': semester ?? '',
      'photoUrl': photoUrl ?? '',
      'chapterId': chapterId ?? '',
      'teamId': teamId ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get single user doc by UID
  Future<DocumentSnapshot> getUserDoc(String uid) async {
    return await _db.collection('users').doc(uid).get();
  }

  // Stream user doc in real-time
  Stream<DocumentSnapshot> streamUserDoc(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Update editable fields of a user
  Future<void> updateUserData({
    required String uid,
    String? semester,
    String? photoUrl,
    String? chapterId,
    String? teamId,
    String? role,
  }) async {
    final Map<String, dynamic> data = {};
    if (semester != null) data['semester'] = semester;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (chapterId != null) data['chapterId'] = chapterId;
    if (teamId != null) data['teamId'] = teamId;
    if (role != null) data['role'] = role;

    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
    }
  }

  // Get user by email
  Future<DocumentSnapshot?> getUserByEmail(String email) async {
    final query = await _db.collection('users').where('email', isEqualTo: email).get();
    if (query.docs.isNotEmpty) return query.docs.first;
    return null;
  }

  // -------------------- Chapter Management --------------------

  // Create a new chapter
  Future<String> createChapter({
    required String name,
    required String chapterLeadId,
  }) async {
    final docRef = await _db.collection('chapters').add({
      'name': name,
      'chapterLeadId': chapterLeadId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id; // returns chapterId
  }

  // Get all chapters
  Future<List<QueryDocumentSnapshot>> getAllChapters() async {
    final snapshot = await _db.collection('chapters').get();
    return snapshot.docs;
  }

  // Delete a chapter (Super Admin only)
  Future<void> deleteChapter(String chapterId) async {
    // Delete all teams and their subcollections first
    final teams = await getTeams(chapterId);
    for (var team in teams) {
      await deleteTeam(chapterId: chapterId, teamId: team.id);
    }
    // Delete the chapter
    await _db.collection('chapters').doc(chapterId).delete();
  }

  // -------------------- Team Management --------------------

  // Create a team under a chapter
  Future<String> createTeam({
    required String chapterId,
    required String name,
    required String teamLeadId,
  }) async {
    final docRef = await _db
        .collection('chapters')
        .doc(chapterId)
        .collection('teams')
        .add({
      'name': name,
      'teamLeadId': teamLeadId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id; // returns teamId
  }

  // Get all teams under a chapter
  Future<List<QueryDocumentSnapshot>> getTeams(String chapterId) async {
    final snapshot =
        await _db.collection('chapters').doc(chapterId).collection('teams').get();
    return snapshot.docs;
  }

  // Delete a team (Chapter Lead only)
  Future<void> deleteTeam({
    required String chapterId,
    required String teamId,
  }) async {
    // Delete all members
    final members = await getTeamMembers(chapterId: chapterId, teamId: teamId);
    for (var member in members) {
      await removeMemberFromTeam(
        chapterId: chapterId,
        teamId: teamId,
        memberUid: member.id,
      );
    }
    // Delete all meetings and attendance
    final meetings = await getMeetings(chapterId: chapterId, teamId: teamId);
    for (var meeting in meetings) {
      await _db
          .collection('chapters')
          .doc(chapterId)
          .collection('teams')
          .doc(teamId)
          .collection('meetings')
          .doc(meeting.id)
          .delete();
    }
    // Delete the team
    await _db
        .collection('chapters')
        .doc(chapterId)
        .collection('teams')
        .doc(teamId)
        .delete();
  }

  // Add member to a team
  Future<void> addMemberToTeam({
    required String chapterId,
    required String teamId,
    required String memberUid,
  }) async {
    final userDoc = await _db.collection('users').doc(memberUid).get();
    if (!userDoc.exists) throw Exception("User does not exist");

    final userData = userDoc.data() as Map<String, dynamic>;

    // Update user's document with chapterId & teamId
    await updateUserData(uid: memberUid, chapterId: chapterId, teamId: teamId);

    // Add member to team subcollection
    await _db
        .collection('chapters')
        .doc(chapterId)
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(memberUid)
        .set({
      'name': userData['name'],
      'email': userData['email'],
      'studentId': userData['studentId'],
      'role': userData['role'],
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all members of a team
  Future<List<QueryDocumentSnapshot>> getTeamMembers({
    required String chapterId,
    required String teamId,
  }) async {
    final snapshot = await _db
        .collection('chapters')
        .doc(chapterId)
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .get();
    return snapshot.docs;
  }

  // Remove member from team
  Future<void> removeMemberFromTeam({
    required String chapterId,
    required String teamId,
    required String memberUid,
  }) async {
    // Remove from team members subcollection
    await _db
        .collection('chapters')
        .doc(chapterId)
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(memberUid)
        .delete();
    
    // Clear user's chapterId and teamId
    await updateUserData(
      uid: memberUid,
      chapterId: '',
      teamId: '',
    );
  }

  // Get all users (for dropdowns)
  Future<List<QueryDocumentSnapshot>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs;
  }

  // -------------------- Meeting Management --------------------

  // Schedule a meeting
  Future<String> scheduleMeeting({
    required String chapterId,
    required String teamId,
    required String topic,
    required DateTime dateTime,
    required String createdBy,
  }) async {
    final docRef = await _db
        .collection('chapters')
        .doc(chapterId)
        .collection('teams')
        .doc(teamId)
        .collection('meetings')
        .add({
      'topic': topic,
      'dateTime': Timestamp.fromDate(dateTime),
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id; // meetingId
  }

  // Get all meetings for a team
  Future<List<QueryDocumentSnapshot>> getMeetings({
    required String chapterId,
    required String teamId,
  }) async {
    final snapshot = await _db
        .collection('chapters')
        .doc(chapterId)
        .collection('teams')
        .doc(teamId)
        .collection('meetings')
        .orderBy('dateTime', descending: false)
        .get();
    return snapshot.docs;
  }

  // -------------------- Attendance --------------------

  // Mark attendance for a member in a meeting
  Future<void> markAttendance({
    required String chapterId,
    required String teamId,
    required String meetingId,
    required String memberUid,
    required String status, // Present / Absent / Late
  }) async {
    await _db
        .collection('chapters')
        .doc(chapterId)
        .collection('teams')
        .doc(teamId)
        .collection('meetings')
        .doc(meetingId)
        .collection('attendance')
        .doc(memberUid)
        .set({
      'status': status,
      'markedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get attendance for a meeting
  Future<List<QueryDocumentSnapshot>> getAttendance({
    required String chapterId,
    required String teamId,
    required String meetingId,
  }) async {
    final snapshot = await _db
        .collection('chapters')
        .doc(chapterId)
        .collection('teams')
        .doc(teamId)
        .collection('meetings')
        .doc(meetingId)
        .collection('attendance')
        .get();
    return snapshot.docs;
  }

  // -------------------- Additional Helpers --------------------

  // Get upcoming meetings for a member (by UID)
  Stream<QuerySnapshot> getUpcomingMeetings(String memberUid) {
    return _db
        .collectionGroup('meetings')
        .where('members', arrayContains: memberUid)
        .snapshots();
  }

  // Get meeting history for a member
  Stream<QuerySnapshot> getMeetingHistory(String memberUid) {
    return _db
        .collectionGroup('meetings')
        .where('members', arrayContains: memberUid)
        .orderBy('dateTime', descending: true)
        .snapshots();
  }
}
