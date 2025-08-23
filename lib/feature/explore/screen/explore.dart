import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import '../../../modal/audio.dart';
import '../../../widget/card.dart';
import '../repository/explore_repo.dart';

class Explore extends ConsumerStatefulWidget {
  const Explore({super.key});

  @override
  ConsumerState<Explore> createState() => _ExploreState();
}

class _ExploreState extends ConsumerState<Explore> {
  String _selectedStatus = "Nearby Me";
  double _rangeKm = 5;
  double? _userLat;
  double? _userLon;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingUrl;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await location.requestService();

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    if (serviceEnabled && permissionGranted == PermissionStatus.granted) {
      final userLocation = await location.getLocation();
      setState(() {
        _userLat = userLocation.latitude;
        _userLon = userLocation.longitude;
      });
    }
  }

  Future<void> _playAudio(AudioModel audio) async {
    if (_currentPlayingUrl == audio.downloadUrl) {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      return;
    }

    _currentPlayingUrl = audio.downloadUrl;

    // Cache audio locally
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${audio.fileName}');
    if (!file.existsSync()) {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        audio.downloadUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      await file.writeAsBytes(response.data!);
    }

    await _audioPlayer.setFilePath(file.path);
    await _audioPlayer.play();
    setState(() {});
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final audioListAsync = ref.watch(audioListProvider);

    return Scaffold(
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
            "Whisper",
            style: GoogleFonts.dangrek(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,

          ),
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _statusButton("Nearby Me"),
                const SizedBox(width: 10),
                _statusButton("Trending"),
              ],
            ),
          ),
          if (_selectedStatus == "Nearby Me")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Text(
                    "Search radius: ${_rangeKm.toStringAsFixed(1)} km",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Slider(
                    activeColor: Colors.lightBlue.shade700,
                    value: _rangeKm,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: "${_rangeKm.toStringAsFixed(1)} km",
                    onChanged: (val) => setState(() => _rangeKm = val),
                  ),
                ],
              ),
            ),
          Expanded(
            child: audioListAsync.when(
              data: (list) {
                List<AudioModel> filteredList = list;
                if (_selectedStatus == "Nearby Me" && _userLat != null && _userLon != null) {
                  filteredList = list.where((audio) {
                    final dist = ExploreRepository.calculateDistanceKm(
                        _userLat!, _userLon!, audio.latitude!, audio.longitude!);
                    return dist <= _rangeKm;
                  }).toList();
                }

                if (filteredList.isEmpty) {
                  return const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,size: 50,),
                      Text("No Audio",style: TextStyle(fontSize: 20),)
                    ],
                  ));
                }

                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (_, index) {
                    final audio = filteredList[index];
                    final distance = (_userLat != null && _userLon != null)
                        ? ExploreRepository.calculateDistanceKm(
                        _userLat!, _userLon!, audio.latitude!, audio.longitude!)
                        : null;

                    return AudioCard(
                      audio: audio,
                      distanceKm: distance,
                      audioPlayer: _audioPlayer,
                      currentPlayingUrl: _currentPlayingUrl,
                      onPlayPause: () => _playAudio(audio),
                      onUpdate: () => setState(() {}),
                      // Dynamic card color based on emotion

                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Expanded _statusButton(String title) {
    bool selected = _selectedStatus == title;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? Colors.lightBlue.shade700 : Colors.grey[300],
          foregroundColor: selected ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: selected ? 4 : 1,
        ),
        onPressed: () => setState(() => _selectedStatus = title),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
