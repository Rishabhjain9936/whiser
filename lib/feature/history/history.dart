import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'history_repository.dart';

class AudioHistoryScreen extends ConsumerStatefulWidget {
  const AudioHistoryScreen({super.key});

  @override
  ConsumerState<AudioHistoryScreen> createState() => _AudioHistoryScreenState();
}

class _AudioHistoryScreenState extends ConsumerState<AudioHistoryScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();

    // Reset when audio completes
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playingId = null;
        });
      }
    });
  }

  Future<void> _playPause(String id, String url, String fileName) async {
    final repo = ref.read(audioRepositoryProvider);
    final localPath = p.join(await repo.getAppAudioPath(), fileName);
    final localFile = File(localPath);

    try {
      if (_playingId == id) {
        if (_player.playing) {
          await _player.pause();
        } else {
          await _player.play();
        }
      } else {
        await _player.stop();

        if (await localFile.exists()) {
          await _player.setFilePath(localFile.path);
        } else {
          await _player.setUrl(url);
        }

        setState(() {
          _playingId = id;
        });
        await _player.play();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error playing audio: $e")),
      );
    }
  }

  Future<void> _deleteAudio(Map<String, dynamic> audio) async {
    final repo = ref.read(audioRepositoryProvider);
    final fileName = audio["fileName"] as String;
    final docId = audio["id"] as String;
    final uid = audio["uid"] as String;

    try {
      await repo.deleteAudio(docId: docId, fileName: fileName, uid: uid);

      if (_playingId == docId) {
        await _player.stop();
        setState(() {
          _playingId = null;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Audio deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioAsync = ref.watch(audioHistoryProvider);

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
          "My history",
          style: GoogleFonts.dangrek(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
      body: audioAsync.when(
        data: (audios) {
          if (audios.isEmpty) {
            return const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history,size: 50,),
                Text("No history found",style: TextStyle(fontSize: 20),)
              ],
            ));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: audios.length,
            itemBuilder: (context, index) {
              final audio = audios[index];
              final isCurrent = _playingId == audio["id"];

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white70,
                    child: Text(
                      audio["emotion"] ?? "🎵",
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    audio["name"] ?? "Unknown",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audio["address"] ?? "Unknown location",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '@ ${audio["type"]}' ?? "",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ StreamBuilder keeps button synced
                      StreamBuilder<PlayerState>(
                        stream: _player.playerStateStream,
                        builder: (context, snapshot) {
                          final state = snapshot.data;
                          final playing = state?.playing ?? false;
                          final completed =
                              state?.processingState == ProcessingState.completed;

                          IconData icon;
                          if (isCurrent) {
                            if (completed) {
                              icon = Icons.replay_circle_filled;
                            } else if (playing) {
                              icon = Icons.pause_circle;
                            } else {
                              icon = Icons.play_circle;
                            }
                          } else {
                            icon = Icons.play_circle;
                          }

                          return IconButton(
                            icon: Icon(icon,
                                color: Colors.lightBlueAccent, size: 32),
                            onPressed: () => _playPause(
                              audio["id"],
                              audio["downloadUrl"],
                              audio["fileName"],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAudio(audio),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
