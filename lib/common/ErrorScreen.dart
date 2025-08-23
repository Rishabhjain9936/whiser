

import 'package:flutter/cupertino.dart';

class ErrorScreen extends StatelessWidget{

  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Center(
      child: Text(error),
    );
  }

}