import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../modal/audio.dart';

class ExploreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all audios for real-time updates
  Stream<List<AudioModel>> getAllAudios() {
    return _firestore
        .collection('Whisper')
        .doc('public')
        .collection('Audio')
        .snapshots()
        .map((snap) => snap.docs.map((d) => AudioModel.fromMap(d.data())).toList());
  }

  /// Stream single audio document for real-time likes/comments
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamAudio(String fileName) {
    return _firestore
        .collection('Whisper')
        .doc('public')
        .collection('Audio')
        .where('fileName', isEqualTo: fileName)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.first);
  }

  /// Toggle like (transaction)
  Future<void> toggleLike(String fileName, bool isLiked) async {
    final query = await _firestore
        .collection('Whisper')
        .doc('public')
        .collection('Audio')
        .where('fileName', isEqualTo: fileName)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return;
    final ref = query.docs.first.reference;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      int currentLikes = (snap['likes'] ?? 0) as int;
      int updated = isLiked ? currentLikes + 1 : currentLikes - 1;
      if (updated < 0) updated = 0;
      tx.update(ref, {'likes': updated});
    });
  }

  /// Add comment
  Future<void> addComment(String fileName, Map<String, String> comment) async {
    final query = await _firestore
        .collection('Whisper')
        .doc('public')
        .collection('Audio')
        .where('fileName', isEqualTo: fileName)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return;

    await query.docs.first.reference.update({
      'comments': FieldValue.arrayUnion([comment])
    });
  }

  Future<void> deleteComment(String fileName, String username, String commentText) async {
    try {
      final query = await _firestore
          .collection('Whisper')
          .doc('public')
          .collection('Audio')
          .where('fileName', isEqualTo: fileName)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('No document found for fileName: $fileName');
        return;
      }

      final docRef = query.docs.first.reference;

      // This must exactly match what's stored
      final commentMap = {username: commentText};

      await docRef.update({
        'comments': FieldValue.arrayRemove([commentMap]),
      });

      print('Comment deleted successfully.');
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }


  Future<void> editComment(String fileName, Map<String, String> oldComment, Map<String, String> newComment) async {
    final query = await _firestore
        .collection('Whisper')
        .doc('public')
        .collection('Audio')
        .where('fileName', isEqualTo: fileName)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    final doc = query.docs.first.reference;

    await doc.update({
      'comments': FieldValue.arrayRemove([oldComment]),
    });

    await doc.update({
      'comments': FieldValue.arrayUnion([newComment]),
    });
  }




  /// Calculate distance between two coordinates
  static double calculateDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _degToRad(double deg) => deg * pi / 180;
}

/// Providers
final exploreRepositoryProvider = Provider((ref) => ExploreRepository());

final audioListProvider = StreamProvider<List<AudioModel>>((ref) {
  return ref.watch(exploreRepositoryProvider).getAllAudios();
});
