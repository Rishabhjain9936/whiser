import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final CommonRepoProvider=Provider((ref)=>CommonRepo());

class CommonRepo {
  final ImagePicker _picker = ImagePicker();


  Future<String?> pickImage(bool fromCamera) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        return pickedFile.path;
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }



}
