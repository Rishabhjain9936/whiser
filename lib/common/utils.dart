import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

/// Helper to combine position & duration streams for slider
Stream<PositionData> getPositionDataStream(AudioPlayer player) {
  return Rx.combineLatest2<Duration, Duration?, PositionData>(
    player.positionStream,
    player.durationStream,
        (position, duration) => PositionData(
      position,
      duration ?? Duration.zero,
    ),
  );
}

class PositionData {
  final Duration position;
  final Duration duration;

  PositionData(this.position, this.duration);
}

void showAudioBottomSheet({
  required BuildContext context,
  required String audioUrl,
  required String userName,
  required String emotion,
  required String address,
  required double distance,
}) {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Initialize audio once
  _audioPlayer.setUrl(audioUrl);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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

            // Seekbar
            StreamBuilder<PositionData>(
              stream: getPositionDataStream(_audioPlayer),
              builder: (context, snapshot) {
                final positionData = snapshot.data ??
                    PositionData(Duration.zero, _audioPlayer.duration ?? Duration.zero);
                return Column(
                  children: [
                    Slider(
                      min: 0.0,
                      max: positionData.duration.inMilliseconds.toDouble(),
                      value: positionData.position.inMilliseconds
                          .clamp(0, positionData.duration.inMilliseconds)
                          .toDouble(),
                      onChanged: (value) {
                        _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(positionData.position)),
                        Text(_formatDuration(positionData.duration)),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // Play/Pause & Stop buttons
            StreamBuilder<bool>(
              stream: _audioPlayer.playingStream,
              initialData: false,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(isPlaying ? "Pause" : "Play"),
                      onPressed: () {
                        if (isPlaying) {
                          _audioPlayer.pause();
                        } else {
                          _audioPlayer.play();
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text("Stop"),
                      onPressed: () {
                        _audioPlayer.stop();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(() => _audioPlayer.dispose());
}

/// Format duration to mm:ss
String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$minutes:$seconds";
}
