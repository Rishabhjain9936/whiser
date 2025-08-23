import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;
import 'package:whisper/feature/firebase/controller.dart';

class Mic {
  showBottomView(BuildContext context, double long, double lat, WidgetRef ref) async {
    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => ProviderScope(child: RecordBottomSheet(long: long, lat: lat)),
    );
  }
}

class RecordBottomSheet extends ConsumerStatefulWidget {
  final double long;
  final double lat;

  const RecordBottomSheet({required this.long, required this.lat, Key? key}) : super(key: key);

  @override
  ConsumerState<RecordBottomSheet> createState() => _RecordBottomSheetState();
}

class _RecordBottomSheetState extends ConsumerState<RecordBottomSheet> {
  int _seconds = 0;
  Timer? _timer;
  bool isRecording = true;
  final record = AudioRecorder();
  String? tempPath;
  String visibility = 'Public';
  String userType = 'User';
  final TextEditingController titleController = TextEditingController();
  final TextEditingController passowrdController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    titleController.dispose();
    passowrdController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final micPermission = await Permission.microphone.request();
    await Permission.storage.request();
    if (!micPermission.isGranted) return;

    final tempDir = await getTemporaryDirectory();
    tempPath = p.join(tempDir.path, 'temp.m4a');

    await record.start(const RecordConfig(), path: tempPath!);
    _startTimer();
  }

  Future<void> stopRecording() async {
    await record.stop();
    _pauseTimer();

    if (tempPath != null) {
      if (!mounted) return;
      final parent = context;
      final parentRef = ref;
      if (parent.mounted) showSaveDialog(tempPath!, parent, parentRef);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  Future<String> _getAppAudioPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'Whisper/audio');
    final folder = Directory(path);
    if (!await folder.exists()) await folder.create(recursive: true);
    return folder.path;
  }

  Future<void> saveRecording(
      BuildContext ctx,
      String title,
      String type,
      String mode,
      String password,
      WidgetRef parentRef,
      String emotion,
      ) async {
    try {
      final appAudioPath = await _getAppAudioPath();
      final fileName = '${title}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final newPath = p.join(appAudioPath, fileName);

      if (tempPath == null) {
        if (!ctx.mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Temp path is null.")));
        return;
      }

      final tempFile = File(tempPath!);
      if (!await tempFile.exists()) {
        if (!ctx.mounted) return;
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text("Recording not found.")));
        return;
      }

      await tempFile.copy(newPath);

      final audioController = ref.read(AudioFireStoreControllerProvider);
      final user = FirebaseAuth.instance.currentUser?.uid;


      if (user == null) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text("Error: User not signed in")),
          );
        }
        return;
      }

      final address = await audioController.getAddressFromLatLng(widget.lat, widget.long);

      await audioController.uploadAudioFile(
        filePath: newPath,
        name: title,
        uid: user,
        mode: mode,
        type: type,
        password: password,
        latitude: widget.lat,
        longitude: widget.long,
        address: address['address'],
        locationName: address['locationName'],
        emotion: emotion,
      );

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text("Recording saved successfully")),
        );
      }
    } catch (e) {
      debugPrint("Error saving recording: $e");
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }

    }
  }



  Future<void> showSaveDialog(
      String path, BuildContext context, WidgetRef parentRef) async {
    final AudioPlayer _audioPlayer = AudioPlayer();
    final titleController = TextEditingController();
    final passwordController = TextEditingController();

    bool isSave = false;
    String visibility = 'Public';
    String userType = 'User';
    String selectedEmotion = "😊";
    bool isPlaying = false;
    Duration currentPosition = Duration.zero;
    Duration totalDuration = Duration.zero;
    bool isUploading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            _audioPlayer.positionStream.listen((pos) {
              setStateDialog(() => currentPosition = pos);
            });

            _audioPlayer.playerStateStream.listen((state) {
              final playing = state.playing;
              final completed =
                  state.processingState == ProcessingState.completed;
              if (completed) {
                _audioPlayer.seek(Duration.zero);
                _audioPlayer.pause();
              }
              setStateDialog(() => isPlaying = playing);
            });

            Future<void> togglePlayPause() async {
              if (_audioPlayer.playing) {
                await _audioPlayer.pause();
              } else {
                if (_audioPlayer.duration == null) {
                  await _audioPlayer.setFilePath(path);
                  totalDuration = _audioPlayer.duration ?? Duration.zero;
                }
                await _audioPlayer.play();
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.mic, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    "Save Your Recording",
                    style: GoogleFonts.dangrek(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: isUploading
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text("Uploading...", style: GoogleFonts.dangrek(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel Upload"),
                    onPressed: () {
                      setStateDialog(() => isUploading = false);
                      _audioPlayer.stop();
                      File(path).deleteSync();
                      Navigator.of(ctx).pop();
                      Navigator.pop(context);
                    },
                  ),
                ],
              )
                  : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Enter Title *',
                        labelStyle: GoogleFonts.dangrek(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (visibility == 'Private')
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Enter Password *',
                          labelStyle: GoogleFonts.dangrek(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                      ),
                    if (visibility == 'Private') const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedEmotion,
                      decoration: InputDecoration(
                        labelText: 'Select Emotion',
                        labelStyle: GoogleFonts.dangrek(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ["😊", "😢", "🔥", "😂", "😍", "😡"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 20))))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() => selectedEmotion = val!);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: visibility,
                      decoration: InputDecoration(
                        labelText: 'Select Visibility',
                        labelStyle: GoogleFonts.dangrek(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ['Public', 'Private']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        setStateDialog(() => visibility = val!);
                      },
                    ),
                    const SizedBox(height: 10),
                    if (visibility == 'Public')
                      DropdownButtonFormField<String>(
                        value: userType,
                        decoration: InputDecoration(
                          labelText: 'Select User Type',
                          labelStyle: GoogleFonts.dangrek(),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: ['User', 'Anonymous']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          setStateDialog(() => userType = val!);
                        },
                      ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Slider(
                          min: 0,
                          max: totalDuration.inSeconds.toDouble().clamp(1, double.infinity),
                          value: currentPosition.inSeconds.toDouble().clamp(0.0, totalDuration.inSeconds.toDouble()),
                          onChanged: (val) async {
                            await _audioPlayer.seek(Duration(seconds: val.toInt()));
                            setStateDialog(() =>
                            currentPosition = Duration(seconds: val.toInt()));
                          },
                          activeColor: Colors.blueAccent,
                          inactiveColor: Colors.grey.shade300,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 40,
                              icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle,
                                  color: Colors.blueAccent),
                              onPressed: togglePlayPause,
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              iconSize: 40,
                              icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
                              onPressed: () async {
                                await _audioPlayer.stop();
                                setStateDialog(() {
                                  isPlaying = false;
                                  currentPosition = Duration.zero;
                                });
                              },
                            ),
                          ],
                        ),
                        Text(
                          "${currentPosition.inSeconds} / ${totalDuration.inSeconds} sec",
                          style: GoogleFonts.dangrek(),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              actions: isUploading
                  ? []
                  : [
                TextButton(
                  onPressed: () {
                    _audioPlayer.stop();
                    File(path).deleteSync();
                    Navigator.of(ctx).pop();
                    Navigator.pop(context);
                  },

                  child: Text("Discard", style: GoogleFonts.dangrek()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    setStateDialog(() => isUploading = true);
                    _audioPlayer.stop();

                    await saveRecording(
                      ctx,
                      titleController.text,
                      visibility,
                      userType,
                      passwordController.text.trim(),
                      parentRef,
                      selectedEmotion,
                    );

                    if (context.mounted) {
                      Navigator.of(ctx).pop(); // Close dialog
                      Navigator.pop(context); // Back to previous screen
                    }
                  },
                  child: Text("Save", style: GoogleFonts.dangrek()),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => _audioPlayer.dispose());
  }



  Future<void> pauseOrResume() async {
    if (isRecording) {
      await record.pause();
      _pauseTimer();
    } else {
      await record.resume();
      _startTimer();
    }
    setState(() => isRecording = !isRecording);
  }

  void discardRecording() {
    _pauseTimer();
    record.stop();
    if (tempPath != null) File(tempPath!).deleteSync();
    Navigator.pop(context);
  }

  String get _formattedTime {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        top: 30,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Recording...",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Lottie.asset(
            'assets/lottie/mic_wve.json',
            height: 100,
            width: 100,
            repeat: true,
          ),
          const SizedBox(height: 10),
          Text(
            _formattedTime,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(isRecording ? Icons.pause : Icons.play_arrow),
                iconSize: 40,
                onPressed: pauseOrResume,
              ),
              const SizedBox(width: 30),
              IconButton(
                icon: const Icon(Icons.check),
                iconSize: 40,
                onPressed: stopRecording,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }


}
