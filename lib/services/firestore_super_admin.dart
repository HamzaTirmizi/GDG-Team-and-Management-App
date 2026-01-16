// lib/services/firestore_super_admin.dart
import 'firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminService {
  final FirestoreService _firestoreService = FirestoreService();

  // Get all chapters
  Future<List<QueryDocumentSnapshot>> getAllChapters() async {
    return await _firestoreService.getAllChapters();
  }

  // Get all teams under a chapter
  Future<List<QueryDocumentSnapshot>> getTeamsForChapter(String chapterId) async {
    return await _firestoreService.getTeams(chapterId);
  }

  // Get all members of a team
  Future<List<QueryDocumentSnapshot>> getMembersForTeam(String chapterId, String teamId) async {
    return await _firestoreService.getTeamMembers(chapterId: chapterId, teamId: teamId);
  }

  // Get all meetings for a team
  Future<List<QueryDocumentSnapshot>> getMeetingsForTeam(String chapterId, String teamId) async {
    return await _firestoreService.getMeetings(chapterId: chapterId, teamId: teamId);
  }

  // Get attendance for a meeting
  Future<List<QueryDocumentSnapshot>> getAttendance(String chapterId, String teamId, String meetingId) async {
    return await _firestoreService.getAttendance(
        chapterId: chapterId, teamId: teamId, meetingId: meetingId);
  }
}
