import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../../common/utils.dart';
import '../../main.dart';
import '../../modal/audio.dart';

// User location provider
final userLocationProvider = StateProvider<LatLng?>((ref) => null);
final UserDataProvider = StateProvider<List<AudioModel>?>((ref) => null);

// Nearby markers provider
final nearbyMarkersProvider = StreamProvider.family<Set<Marker>, LatLng>((ref, location) {
  return FirebaseFirestore.instance.collectionGroup('Audio').snapshots().asyncMap((snapshot) async {
    // Generate all markers in parallel
    final markers = await Future.wait(snapshot.docs.map((doc) async {
      final data = doc.data();
      final double? lat = (data['latitude'] as num?)?.toDouble();
      final double? lng = (data['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) return null;

      final distance = calculateDistanceKm(location.latitude, location.longitude, lat, lng);
      final emotion = data['emotion'] ?? "🎵";

      // Generate BitmapDescriptor from emoji
      final icon = await _emojiToBitmap(emotion, size: 120);

      return Marker(
        markerId: MarkerId(doc.id),
        icon: icon,
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: "$emotion ${data['name'] ?? 'Audio'}",
          snippet: "${distance.toStringAsFixed(2)} km away",
        ),
        onTap: () {
          final ctx = navigatorKey.currentState?.overlay?.context;
          if (ctx != null) {
            showAudioBottomSheet(
              context: ctx,
              audioUrl: data['downloadUrl'] ?? '',
              userName: data['name'] ?? 'Unknown',
              emotion: emotion,
              address: data['address'] ?? 'Unknown',
              distance: distance,
            );
          }
        },
      );
    }).toList());

    // Remove nulls and convert to Set
    return markers.whereType<Marker>().toSet();
  });
});

// Convert emoji to BitmapDescriptor
Future<BitmapDescriptor> _emojiToBitmap(String emoji, {int size = 80}) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = Colors.transparent;
  canvas.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), paint);

  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    text: TextSpan(text: emoji, style: TextStyle(fontSize: size.toDouble())),
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
  );

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = (await image.toByteData(format: ImageByteFormat.png))!.buffer.asUint8List();
  return BitmapDescriptor.fromBytes(bytes);
}

// Utility: calculate distance between two coordinates in km
double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371;
  final double dLat = (lat2 - lat1) * (pi / 180);
  final double dLon = (lon2 - lon1) * (pi / 180);
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
          sin(dLon / 2) * sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}



final AudioFirestoreProvider = Provider<AudioFirestore>((ref) {
  return AudioFirestore(StorageInstance: FirebaseStorage.instance);
});

class AudioFirestore {
  final FirebaseStorage StorageInstance;

  AudioFirestore({required this.StorageInstance});

  double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double degree) => degree * pi / 180;

  Future<void> uploadAudioFile({
    required String filePath,
    required String name,
    required String uid,
    required String mode,
    required String type,
    required String password,
    required double? latitude,
    required double? longitude,
    required String? address,
    required String? locationName,
    required String? emotion
  }) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist at $filePath');
      }

      final String fileName = path.basename(filePath);
      final String uniqueId = const Uuid().v4();
      final String storagePath = 'Whisper/audio/$uid/$uniqueId-$fileName';

      final ref = StorageInstance.ref().child(storagePath);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      final String docId = '$uniqueId-$uid';
      final audio = AudioModel(
        name: name,
        uid: uid,
        fileName: '$uniqueId-$fileName',
        downloadUrl: downloadUrl,
        dateTime: DateTime.now(),
        mode: mode,
        type: type,
        password: password,
        latitude: latitude,
        longitude: longitude,
        address: address,
        locationName: locationName,
        emotion: emotion
      );

      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('Whisper')
          .doc('own')
          .collection(uid)
          .doc(docId)
          .set(audio.toMap());

      await firestore.collection('Whisper').doc('public').collection('Audio').doc(docId).set(audio.toMap());

      print('✅ Audio uploaded and metadata saved successfully!');
    } catch (e) {
      print('❌ Error uploading audio: $e');
    }
  }

  Future<Map<String, String>> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
        String locationName = place.locality ?? place.name ?? 'Unknown';
        return {
          'address': address,
          'locationName': locationName,
        };
      } else {
        return {'address': 'Unknown address', 'locationName': 'Unknown'};
      }
    } catch (e) {
      print('❌ Error getting address: $e');
      return {'address': 'Error', 'locationName': 'Error'};
    }
  }
}

