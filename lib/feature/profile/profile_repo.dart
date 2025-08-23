import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getUserProfile();
});

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore
        .collection("Whisper")
        .doc("UserInformation")
        .collection("data")
        .doc(uid)
        .get();

    return doc.data();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore
        .collection("Whisper")
        .doc("User")
        .collection("data")
        .doc(uid)
        .get();

    return doc.data();
  }

  /// Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
