import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whisper/common/commonRepo.dart';
import 'package:whisper/feature/auth/screen/login.dart';

import '../../home/home.dart';


final userNameProvider=StateProvider<String>((ref)=>'');

class UserInformation extends ConsumerStatefulWidget {
  static const routeName = "/user-information";

  final String uid; // UID passed from SignUp

  const UserInformation({Key? key, required this.uid}) : super(key: key);

  @override
  ConsumerState<UserInformation> createState() => _UserInformationState();
}

class _UserInformationState extends ConsumerState<UserInformation> {
  final TextEditingController _usernameController = TextEditingController();
  String? localFile; // Local path of picked image
  String? imageUrl;  // Firebase Storage URL

  // Pick image from gallery/camera
  Future<void> pickImage() async {
    final f = await ref.read(CommonRepoProvider).pickImage(false);
    if (f != null) {
      setState(() {
        localFile = f;
      });
    }
  }

  // Upload username and image using passed UID
  Future<void> uploadUserInfo() async {
    final userName = _usernameController.text.trim();
    if (userName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username cannot be empty!")),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Upload image if selected
      if (localFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child('Whisper/UserImage/${widget.uid}');
        await storageRef.putFile(File(localFile!));
        imageUrl = await storageRef.getDownloadURL();
      }

      // Save username + imageUrl to Firestore
      await FirebaseFirestore.instance
          .collection('Whisper')
          .doc('UserInformation')
          .collection('data')
          .doc(widget.uid)
          .set({
        'Usename': userName,
        'imageUrl': imageUrl ?? '',
      }, SetOptions(merge: true));

      ref.read(userNameProvider.notifier).state = userName!;

      Navigator.of(context).pop(); // close loading

      ref.read(userNameProvider.notifier).state=userName;
      Navigator.pushReplacementNamed(context, Home.routeName);

    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider avatar;
    if (localFile != null) {
      avatar = FileImage(File(localFile!));
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = NetworkImage(imageUrl!);
    } else {
      avatar = const AssetImage('assets/images/user.png');
    }

    return Scaffold(
      appBar: AppBar(title: const Text("User Information")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(radius: 60, backgroundColor: Colors.grey[300], backgroundImage: avatar),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadUserInfo,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
