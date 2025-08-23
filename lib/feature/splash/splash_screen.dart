import 'dart:async';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whisper/feature/auth/screen/singUp.dart';
import '../../internet_checker.dart';
import '../auth/screen/login.dart';
import '../home/home.dart';
import '../home/service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // The logic to initialize the app remains the same
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initApp();
    });
  }

  Future<void> _initApp() async {
    final homeNotifier = ref.read(homeStateProvider.notifier);

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult != ConnectivityResult.none;

    if (!hasInternet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No internet connection. Some features may not work."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    await homeNotifier.initialize();

    // InternetChecker.initialize(context);

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is signed in
      Navigator.pushReplacementNamed(context, Home.routeName);
    } else {
      // User not signed in
      Navigator.pushReplacementNamed(context, Signup.routeName);
    }
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Use AnimatedBuilder to optimize the rotating circles
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _rotatingHalfCircle(200, Colors.white.withOpacity(0.8), _controller.value * 2 * math.pi),
                    _rotatingHalfCircle(230, Colors.white.withOpacity(0.5), -_controller.value * 2 * math.pi),
                    _rotatingHalfCircle(260, Colors.white, _controller.value * 2 * math.pi),
                  ],
                );
              },
            ),

            // Logo + App Name
            Column(
              mainAxisSize: MainAxisSize.min, // tightly wrap content
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Wrap image in SizedBox and ClipRect to remove any intrinsic padding
                SizedBox(
                  width: 120,
                  height: 120,
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Image.asset('assets/images/birdLogo.png'),
                    ),
                  ),
                ),
                Text(
                  "Whisper",
                  style: GoogleFonts.dangrek(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rotatingHalfCircle(double size, Color color, double angle) {
    return Transform.rotate(
      angle: angle,
      child: CustomPaint(
        size: Size(size, size),
        painter: HalfCirclePainter(color),
      ),
    );
  }
}

class HalfCirclePainter extends CustomPainter {
  final Color color;
  HalfCirclePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), 0, math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}