import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/track.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<Track>> getAllTracks() async {
    try {
      final snapshot = await _firestore.collection('tracks').get();
      return snapshot.docs
          .map((doc) => Track.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Şarkıları getirme hatası: $e');
      return [];
    }
  }

  Future<List<Track>> getTrendingTracks() async {
    try {
      final snapshot = await _firestore
          .collection('tracks')
          .orderBy('playCount', descending: true)
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => Track.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Trending şarkıları getirme hatası: $e');
      return [];
    }
  }

  Future<List<Track>> getNewReleaseTracks() async {
    try {
      final snapshot = await _firestore
          .collection('tracks')
          .orderBy('releaseDate', descending: true)
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => Track.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Yeni şarkıları getirme hatası: $e');
      return [];
    }
  }

  Future<Track?> getTrackById(String trackId) async {
    try {
      final doc = await _firestore.collection('tracks').doc(trackId).get();
      if (doc.exists) {
        return Track.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Şarkı detayı getirme hatası: $e');
      return null;
    }
  }
}
