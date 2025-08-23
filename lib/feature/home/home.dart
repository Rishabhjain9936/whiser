import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:whisper/feature/explore/screen/explore.dart';
import 'package:whisper/feature/mic/Mic.dart';
import 'package:whisper/feature/profile/profile.dart';
import '../history/history.dart';
import '../home/service.dart';
import 'package:just_audio/just_audio.dart';


class Home extends ConsumerStatefulWidget {
  const Home({Key? key}) : super(key: key);
  static const routeName = "/home";

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  final Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController _mapController;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeStateProvider);

    // If still loading, show loader
    if (homeState.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If error occurred
    if (homeState.error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            homeState.error!,
            style: const TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    final currentLatLng = homeState.currentLatLng;


    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: currentLatLng ?? const LatLng(20.5937, 78.9629),
                  zoom: 15,
                ),

                markers: homeState.markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: (controller) {
                  if (!_controller.isCompleted) _controller.complete(controller);
                  _mapController = controller;
                },

              ),
              Positioned(top: 60, left: 15, right: 15, child: _buildSearchBar()),
              Positioned(
                bottom: 150,
                right: 15,
                child: FloatingActionButton(
                  onPressed: () => _goToCurrentLocation(currentLatLng),
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
          Explore(),
          AudioHistoryScreen(),
          ProfilePage(),
        ],
      ),
      floatingActionButton: currentLatLng == null
          ? FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.yellow),
                  SizedBox(width: 10),
                  Text("Warning")
                ],
              ),
              content: const Text(
                "Please wait to get your current Location",
                style: TextStyle(fontSize: 18),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Ok"),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.mic, size: 30),
        shape: const CircleBorder(),
      )
          : SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () {
            Mic().showBottomView(
              context,
              currentLatLng.longitude,
              currentLatLng.latitude,
              ref,
            );
          },
          child: const Icon(Icons.mic, size: 40),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Future<void> _goToCurrentLocation(LatLng? currentLatLng) async {
    if (currentLatLng == null) return;

    await _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(currentLatLng, 18),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
          ),
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: "Whisper -> Upload your soul",
              hintStyle: GoogleFonts.dangrek(),
              prefixIcon: const Icon(Icons.search, color: Colors.black87),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 9.0,
      color: Colors.lightBlueAccent.withOpacity(.6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, "Home", 0),
          _buildNavItem(Icons.explore, "Explore", 1),
          const SizedBox(width: 48),
          _buildNavItem(Icons.history, "Recent", 2),
          _buildNavItem(Icons.account_circle_rounded, "Profile", 3),
        ],
      ),
    );
  }


  void showAudioBottomSheet({
    required BuildContext context,
    required String audioUrl,
    required String userName,
    required String emotion,
    required String address,
    required double distance,
  }) {
    final _audioPlayer = AudioPlayer();
    bool isPlaying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$emotion $userName",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text("Address: $address"),
                    Text("Distance: ${distance.toStringAsFixed(2)} km"),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                          label: Text(isPlaying ? "Pause" : "Play"),
                          onPressed: () async {
                            if (isPlaying) {
                              await _audioPlayer.pause();
                            } else {
                              await _audioPlayer.setUrl(audioUrl);
                              await _audioPlayer.play();
                            }
                            setState(() {
                              isPlaying = !isPlaying;
                            });
                          },
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.stop),
                          label: const Text("Stop"),
                          onPressed: () async {
                            await _audioPlayer.stop();
                            setState(() {
                              isPlaying = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => _audioPlayer.dispose());
  }


  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.black : Colors.white),
          Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white)),
        ],
      ),
    );
  }
}
