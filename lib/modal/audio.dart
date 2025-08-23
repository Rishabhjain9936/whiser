class AudioModel {
  final String name;
  final String uid;
  final String fileName;
  final String downloadUrl;
  final DateTime dateTime;
  final String mode;
  final String type;
  final String password;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? locationName;
  final List<Map<String, String>> comments; // 🔹 Changed
  final int likes;

  // 🆕 Emotion field
  final String? emotion; // e.g., "😊", "😢", "🔥"

  AudioModel({
    required this.name,
    required this.uid,
    required this.fileName,
    required this.downloadUrl,
    required this.dateTime,
    required this.mode,
    required this.type,
    required this.password,
    this.latitude,
    this.longitude,
    this.address,
    this.locationName,
    this.comments = const [],
    this.likes = 0,
    this.emotion,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'uid': uid,
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'dateTime': dateTime.toIso8601String(),
      'mode': mode,
      'type': type,
      'password': password,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'locationName': locationName,
      'comments': comments,
      'likes': likes,
      'emotion': emotion,
    };
  }

  factory AudioModel.fromMap(Map<String, dynamic> map) {
    return AudioModel(
      name: map['name'] ?? '',
      uid: map['uid'] ?? '',
      fileName: map['fileName'] ?? '',
      downloadUrl: map['downloadUrl'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      mode: map['mode'] ?? '',
      type: map['type'] ?? '',
      password: map['password'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      address: map['address'],
      locationName: map['locationName'],
      comments: (map['comments'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e))
          .toList() ??
          [],
      likes: map['likes'] ?? 0,
      emotion: map['emotion'],
    );
  }
}
