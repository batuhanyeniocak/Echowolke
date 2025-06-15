import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String imageUrl;
  final String creatorId;
  final List<String> trackIds;
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.imageUrl,
    required this.creatorId,
    this.trackIds = const [],
    required this.createdAt,
  });

  factory Playlist.fromFirestore(Map<String, dynamic> data, String id) {
    return Playlist(
      id: id,
      name: data['name'] ?? 'Bilinmeyen Çalma Listesi',
      description: data['description'],
      imageUrl: data['imageUrl'] ?? '',
      creatorId: data['creatorId'] ?? '',
      trackIds: List<String>.from(data['trackIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'trackIds': trackIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
