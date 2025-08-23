// audio_card.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper/feature/auth/screen/userInformation.dart';
import '../modal/audio.dart';
import '../feature/explore/repository/explore_repo.dart';

class AudioCard extends ConsumerStatefulWidget {
  final AudioModel audio;
  final double? distanceKm;
  final AudioPlayer audioPlayer;
  final String? currentPlayingUrl;
  final VoidCallback onPlayPause;
  final VoidCallback onUpdate;

  const AudioCard({
    super.key,
    required this.audio,
    this.distanceKm,
    required this.audioPlayer,
    required this.currentPlayingUrl,
    required this.onPlayPause,
    required this.onUpdate,
  });

  @override
  ConsumerState<AudioCard> createState() => _AudioCardState();
}

class _AudioCardState extends ConsumerState<AudioCard> {
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  String? localPath;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;
  bool isLiked = false;
  String username = 'anonymous';

  @override
  void initState() {
    super.initState();
    _initLocalCache();
    _attachListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getUserName();
    });
  }

  @override
  void didUpdateWidget(covariant AudioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPlayingUrl != widget.currentPlayingUrl) {
      _detachListeners();
      _attachListeners();
    }
  }

  @override
  void dispose() {
    _detachListeners();
    super.dispose();
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
  }

  void _attachListeners() {
    if (widget.currentPlayingUrl != widget.audio.downloadUrl) return;

    _posSub = widget.audioPlayer.positionStream.listen((pos) {
      setState(() => position = pos);
    });

    _durSub = widget.audioPlayer.durationStream.listen((dur) {
      setState(() => duration = dur ?? Duration.zero);
    });

    _stateSub = widget.audioPlayer.playerStateStream.listen((state) {
      if (widget.currentPlayingUrl == widget.audio.downloadUrl &&
          state.processingState == ProcessingState.completed) {
        setState(() => position = Duration.zero);
        widget.audioPlayer.seek(Duration.zero);
        widget.audioPlayer.pause();
        widget.onUpdate();
      }
    });
  }

  void _detachListeners() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
  }

  Future<void> _initLocalCache() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.audio.fileName}');
    if (await file.exists()) {
      localPath = file.path;
    } else {
      final dio = Dio();
      final resp = await dio.get<List<int>>(
        widget.audio.downloadUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      await file.writeAsBytes(resp.data!);
      localPath = file.path;
    }
  }

  Future<void> _onPlayPause() async {
    if (widget.audio.type == 'Private' && !widget.audioPlayer.playing) {
      final passwordController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (confirmed != true) return; // User cancelled
      if (passwordController.text != widget.audio.password) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password!')),
        );
        return;
      }
    }


    if (widget.currentPlayingUrl == widget.audio.downloadUrl) {
      if (widget.audioPlayer.playing) {
        await widget.audioPlayer.pause();
      } else {
        await widget.audioPlayer.play();
      }
    } else {
      widget.onPlayPause();
    }
    widget.onUpdate();
  }

  void _showComments(List<Map<String, String>> comments, WidgetRef ref) {
    final ctl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            height: 400,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Comments',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (_, i) {
                      final commentMap = comments[i];
                      final uname = commentMap.keys.first;
                      final text = commentMap[uname]!;

                      final isCurrentUser = uname == username;

                      return ListTile(
                        leading: const Icon(Icons.comment),
                        title: Text(
                          text,
                          style: GoogleFonts.dangrek(
                            color: Colors.black,
                            fontSize: 20,
                          ),
                        ),
                        subtitle: Text(
                          widget.audio.mode == 'User' ? '@$uname' : 'anonymous',
                          style: GoogleFonts.cedarvilleCursive(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        trailing: isCurrentUser
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                final editController = TextEditingController(text: text);
                                final updated = await showDialog<String>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Edit Comment'),
                                    content: TextField(
                                      controller: editController,
                                      decoration: const InputDecoration(hintText: 'Edit your comment'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, editController.text),
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );

                                if (updated != null && updated.trim().isNotEmpty) {
                                  final newCommentMap = {uname: updated.trim()};

                                  await ref.read(exploreRepositoryProvider).editComment(
                                    widget.audio.fileName,
                                    commentMap,
                                    newCommentMap,
                                  );

                                  setModalState(() {
                                    comments[i] = newCommentMap;
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () async {
                                await ref.read(exploreRepositoryProvider).deleteComment(
                                  widget.audio.fileName,uname,
                                 text,
                                );

                                setModalState(() {
                                  comments.removeAt(i);
                                });
                              },
                            ),
                          ],
                        )
                            : null,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctl,
                          decoration: const InputDecoration(hintText: 'Add a comment'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          if (ctl.text.isEmpty) return;

                          final commentMap = {username: ctl.text.trim()};

                          await ref
                              .read(exploreRepositoryProvider)
                              .addComment(widget.audio.fileName, commentMap);

                          setModalState(() {
                            comments.add(commentMap);
                          });

                          ctl.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {

    final name=ref.read(userNameProvider);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.read(exploreRepositoryProvider).streamAudio(widget.audio.fileName),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final data = snapshot.data!.data()!;
        final likes = data['likes'] ?? 0;

        final rawComments = data['comments'] as List<dynamic>? ?? [];
        final comments = rawComments.map((e) {
          if (e is String) {
            return {'anonymous': e};
          } else if (e is Map) {
            return Map<String, String>.from(e);
          } else {
            return <String, String>{};
          }
        }).where((map) => map.isNotEmpty).toList();

        final isActive = widget.currentPlayingUrl == widget.audio.downloadUrl;
        final pos = isActive ? position : Duration.zero;
        final dur = isActive ? duration : Duration.zero;
        final isPlaying = isActive && widget.audioPlayer.playing;

        IconData audioIcon = Icons.audiotrack;
        if (widget.audio.type == 'Private') audioIcon = Icons.lock;
        if (widget.audio.mode == 'Anonymous') audioIcon = Icons.person_off;

        return Card(
          color: Colors.black87,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(audioIcon, size: 40, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.audio.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(widget.audio.type,
                              style:  GoogleFonts.cedarvilleCursive(fontSize: 12, fontWeight: FontWeight.bold,color: Colors.blue)),
                          const SizedBox(height: 4),
                          Text(
                            "${widget.audio.address ?? 'Unknown location'}"
                                "${widget.distanceKm != null ? '\n  ${widget.distanceKm!.toStringAsFixed(1)} km away' : ''}",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                    size: 36, color: Colors.blueAccent),
                                onPressed: _onPlayPause,
                              ),
                              Expanded(
                                child: Slider(
                                  value: pos.inMilliseconds.toDouble().clamp(0, dur.inMilliseconds.toDouble()),
                                  min: 0,
                                  max: dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1,
                                  onChanged: isActive
                                      ? (val) => widget.audioPlayer.seek(Duration(milliseconds: val.round()))
                                      : null,
                                  activeColor: Colors.blueAccent,
                                  inactiveColor: Colors.grey[300],
                                ),
                              ),
                              Text("${_fmt(pos)} / ${_fmt(dur)}",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _IconTextButton(
                      icon: isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      text: likes.toString(),
                      onPressed: () {
                        setState(() {
                          isLiked = !isLiked;
                        });
                        ref.read(exploreRepositoryProvider).toggleLike(widget.audio.fileName, isLiked);
                      },
                      color: isLiked ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    _IconTextButton(
                      icon: Icons.comment_outlined,
                      text: comments.length.toString(),
                      onPressed: () => _showComments(comments, ref),
                      color: Colors.grey[700]!,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.share_outlined, color: Colors.grey[700]),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IconTextButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;
  final Color color;

  const _IconTextButton({
    required this.icon,
    required this.text,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }
}
