

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whisper/feature/auth/repository/Auth.dart';

final AuthControllerProvider=Provider((ref){
  final repo=ref.read(authRepositoryProvider);
  return AuthController( authRepository: repo);
});

class AuthController{

  final AuthRepository authRepository;

  AuthController({required this.authRepository});

  Future<void> signUp(
      String email,
      String password,
      String username,
      BuildContext context,
      ) async {

      authRepository.signUp(email, password, username, context);


  }

  Future<void> loginRep(
      String email,
      String password,
      BuildContext context,
      ) async {

      authRepository.loginRep(email, password, context);
  }

  Future<void> storeUi(String file,String userName)async{
    authRepository.storeUi(file, userName);
  }




  }