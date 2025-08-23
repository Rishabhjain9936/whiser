

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:whisper/feature/firebase/repository.dart';


final AudioFireStoreControllerProvider = Provider<AudioFireStoreController>((ref) {
  final audioRes = ref.read(AudioFirestoreProvider);
  return AudioFireStoreController(audioFirestore: audioRes);
});

class AudioFireStoreController{

  final AudioFirestore audioFirestore;

  AudioFireStoreController({required this.audioFirestore});

  Future<Map<String, String>> getAddressFromLatLng(double latitude, double longitude) async {
    return await audioFirestore.getAddressFromLatLng(latitude, longitude);
  }


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

    await audioFirestore.uploadAudioFile(filePath: filePath, name: name, uid: uid, mode: mode, type: type, password: password,latitude: latitude,longitude: longitude,locationName: locationName,address: address,emotion: emotion
    );

  }

}