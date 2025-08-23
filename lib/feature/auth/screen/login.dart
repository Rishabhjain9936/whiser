import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whisper/feature/auth/controller/controller.dart';
import 'package:whisper/feature/auth/screen/singUp.dart';
import 'package:whisper/feature/auth/screen/userInformation.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  static const routeName = "/login-screen";

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool isLoad=false;
  String? username;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _togglePassword() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _login(String email, String password, BuildContext context, WidgetRef ref) {
    if (_formKey.currentState!.validate()) {
      ref.read(AuthControllerProvider).loginRep(email, password, context);
    }
  }

  Future<void> getUserName() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final name = await FirebaseFirestore.instance
        .collection('Whisper')
        .doc('UserInformation')
        .collection('data')
        .doc(uid)
        .get();

    username = name['Usename'] ?? 'anonymous';
    ref.read(userNameProvider.notifier).state=username!;
  }

@override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getUserName();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  "Welcome Back!",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.lightBlueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Login to continue",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          labelText: 'Email',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: _togglePassword,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Forgot password logic
                          },
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                     isLoad==true ? Align(
                        alignment: Alignment.center,
                        child: CircularProgressIndicator()
                      ):SizedBox(),
                      const SizedBox(height: 20),
                      // Login button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async{
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
                          else {
                            setState(() {
                              isLoad=true;
                            });
                            _login(_emailController.text.trim(),
                                _passwordController.text.trim(), context, ref);
                          }
                        },
                        child: Text(
                          "Login",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?",
                              style: GoogleFonts.poppins()),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(
                                  context, Signup.routeName);
                            },
                            child: const Text("Sign Up"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

    );
  }
}
