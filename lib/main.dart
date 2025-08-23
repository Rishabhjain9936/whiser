import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'internet_checker.dart';
import 'feature/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(ProviderScope(child: Whisper()));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    InternetChecker.initialize();
  });

}

class Whisper extends StatelessWidget {


  @override
  Widget build(BuildContext context) {

    return Builder(
      builder: (ctx) {


        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          onGenerateRoute: (settings) => generateRoute(settings),
          title: 'Whisper',
          theme: ThemeData(
            primaryColor: Color(0xFF7C4DFF),
            scaffoldBackgroundColor: Color(0xFFF3E5F5),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.white,
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(color: Color(0xFF212121)),
              titleLarge: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7C4DFF),
              ),
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
