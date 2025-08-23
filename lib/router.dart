

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'common/ErrorScreen.dart';
import 'feature/auth/screen/login.dart';
import 'feature/auth/screen/singUp.dart';
import 'feature/auth/screen/userInformation.dart';
import 'feature/home/home.dart';

Route<dynamic> generateRoute(RouteSettings settings){

  switch (settings.name){
    case LoginPage.routeName:
      return MaterialPageRoute(builder: (context)=>LoginPage());

    case Signup.routeName:
          return MaterialPageRoute(builder: (context)=>Signup());

    case Home.routeName:
      return MaterialPageRoute(builder: (context)=>Home());

    case UserInformation.routeName:
      final uid=settings.arguments as String;
      return MaterialPageRoute(builder: (context)=>UserInformation(uid: uid,));


    default:
      return MaterialPageRoute(builder: (context)=>const Scaffold(
        body: ErrorScreen(error: 'this page doesn\'t exist'),
      ));

  }

}