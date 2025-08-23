import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Repository Provider
final audioRepositoryProvider = Provider<HistoryRepository>((ref) => HistoryRepository());

/// Audio History Stream Provider
final audioHistoryProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(audioRepositoryProvider).fetchAudioHistory();
});

class HistoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<Map<String, dynamic>>> fetchAudioHistory() {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return _firestore
        .collection("Whisper")
        .doc("own")
        .collection(uid) // fetch only this user's collection
        .orderBy("dateTime", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      return {
        "id": doc.id,
        ...doc.data(),
      };
    }).toList());
  }



  /// Delete audio from local storage, Firestore own & public, and Firebase Storage
  Future<void> deleteAudio({
    required String docId,
    required String fileName,
    required String uid,
  }) async {
    try {
      // 1. Delete from Firestore - user's own collection
      await _firestore
          .collection("Whisper")
          .doc("own")
          .collection(uid)
          .doc(docId)
          .delete();

      // 2. Delete from Firestore - public collection (ignore if not exists)
      final publicDocRef = _firestore.collection("Whisper").doc("public").collection("Audio").doc(docId);
      final publicDoc = await publicDocRef.get();
      if (publicDoc.exists) {
        await publicDocRef.delete();
      }

      // 3. Delete from Firebase Storage
      final storageRef = _storage.ref("Whisper/audio/$uid/$fileName");
      final storageFileExists = await storageRef.getMetadata().then((_) => true).catchError((_) => false);
      if (storageFileExists) {
        await storageRef.delete();
      }

      // 4. Delete from local storage
      final localDir = await getAppAudioPath();
      final localFile = File(p.join(localDir, fileName));
      if (await localFile.exists()) {
        await localFile.delete();
      }
    } catch (e) {
      throw Exception("Delete failed: $e");
    }
  }

  /// Get app local audio folder (public)
  Future<String> getAppAudioPath() async {
    final dir = await getApplicationDocumentsDirectory(); // permanent storage
    final pathDir = p.join(dir.path, 'Whisper/audio');
    final folder = Directory(pathDir);
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder.path;
  }

  /// Fetch all audio files from local storage
  Future<List<File>> fetchLocalAudioFiles() async {
    final dir = await getAppAudioPath();
    final folder = Directory(dir);
    if (!await folder.exists()) return [];
    return folder
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.m4a')) // only audio
        .toList();
  }
}
