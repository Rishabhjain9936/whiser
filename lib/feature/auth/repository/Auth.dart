import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whisper/feature/home/home.dart';

import '../screen/userInformation.dart';

final authRepositoryProvider = Provider(
      (ref) => AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
        firebaseStorage: FirebaseStorage.instance
  ),
);

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  AuthRepository({required this.auth, required this.firestore,required this.firebaseStorage});

  /// Sign Up with Email, Password, and Username
  Future<void> signUp(
      String email,
      String password,
      String name,
      BuildContext context,
      ) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user UID
      String uid = userCredential.user!.uid;

      // Store additional details in Firestore
      await firestore.collection('Whisper').doc('User').collection('data').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,

        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacementNamed(
        context,
        UserInformation.routeName,
        arguments: uid,
      );


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign up failed')),
      );
    }
  }

  /// Login with Email & Password
  Future<void> loginRep(
      String email,
      String password,
      BuildContext context,
      ) async {
    try {
      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Navigator.pushReplacementNamed(context, Home.routeName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful!')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    }
  }

  Future<void> storeUi(String file,String userName)async{


    try {
      final uid = auth.currentUser!.uid;
      final String storagePath = 'Whisper/UserImage/$uid';



      final ref = firebaseStorage.ref().child(storagePath);
      await ref.putFile(File(file));

      final downloadUrl = await ref.getDownloadURL();

      await firestore.collection('Whisper').doc('UserInformation').collection(
          'data').doc(uid).set({
        'Usename': userName,
        'imageUrl': downloadUrl,
      }, SetOptions(merge: true));

    } catch(e){
      print(e.toString());
    }

  }

}
