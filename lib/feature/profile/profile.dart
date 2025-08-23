import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whisper/feature/auth/screen/login.dart';
import 'package:whisper/feature/auth/screen/userInformation.dart';
import 'package:whisper/feature/profile/profile_repo.dart';

/// FutureProvider to get general user data
final userDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return await repo.getUserData();
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider); // for profile pic & username
    final userDataAsync = ref.watch(userDataProvider);   // for name & email
    final repo = ref.read(userRepositoryProvider);



    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue.shade300,
        elevation: 2,
        leadingWidth: 100, // enough space for logo
        leading: Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Image.asset(
            'assets/images/birdLogo.png',
            height: double.infinity, // fill appBar height
            fit: BoxFit.contain,
          ),
        ),
        title: Align(
          alignment: Alignment.bottomLeft,
          child:  Text(
            "Profile",
            style: GoogleFonts.dangrek(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,

            ),
          ),
        ),
      ),
      body: profileAsync.when(
        data: (profileData) {
          if (profileData == null) {
            return const Center(child: Text("No profile data found"));
          }

          return userDataAsync.when(
            data: (userData) {
              if (userData == null) {
                return const Center(child: Text("No user data found"));
              }
              ref.read(userNameProvider.notifier).state=profileData["Usename"];
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.deepPurple.shade100,
                      backgroundImage: profileData["imageUrl"] != null &&
                          profileData["imageUrl"].isNotEmpty
                          ? NetworkImage(profileData["imageUrl"])
                          : null,
                      child: profileData["imageUrl"] == null ||
                          profileData["imageUrl"].isEmpty
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Username
                    Text(
                      "@${profileData["Usename"] ?? "unknown"}",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Name from getUserData()
                    Text(
                      userData['name'] ?? "No Name",
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),


                    Text(
                      userData["email"] ?? "No Email",
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 40),

                    // Sign Out Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                        ),
                        onPressed: () async {
                          await repo.signOut();

                          Navigator.pushReplacementNamed(context, LoginPage.routeName);

                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          "Sign Out",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text("Error: $e")),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
