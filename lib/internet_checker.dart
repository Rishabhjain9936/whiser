import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class InternetChecker {
  static StreamSubscription<ConnectivityResult>? _subscription;
  static bool _isShowing = false;

  static void initialize() {
    _subscription?.cancel();

    _checkAndListen();
  }

  static void _checkAndListen() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Initial check
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      _showBanner(context);
    }

    // Listen to changes
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      if (result == ConnectivityResult.none) {
        if (!_isShowing) _showBanner(ctx);
      } else {
        if (_isShowing) {
          ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
          _isShowing = false;
        }
      }
    });
  }

  static void _showBanner(BuildContext context) {
    _isShowing = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No Internet Connection'),
        duration: Duration(days: 1), // keep it until connectivity returns
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
