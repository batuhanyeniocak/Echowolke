import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/track.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseAuth get auth => _auth;

  Future<void> addLikedSong(String userId, Track track) async {
    try {
      Map<String, dynamic> dataToSave = track.toFirestore();
      dataToSave['likedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('likedSongs')
          .doc(track.id)
          .set(dataToSave);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeLikedSong(String userId, String trackId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('likedSongs')
          .doc(trackId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isSongLiked(String userId, String trackId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('likedSongs')
          .doc(trackId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Stream<List<Track>> getLikedSongs(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('likedSongs')
        .orderBy('likedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Track.fromFirestore(doc.data()))
          .toList();
    });
  }

  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return userCredential;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<List<Track>> getAllTracks() async {
    try {
      final snapshot = await _firestore.collection('tracks').get();
      return snapshot.docs
          .map((doc) => Track.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
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
      return null;
    }
  }

  Future<String> uploadMp3File(File mp3File, String fileName) async {
    try {
      final ref = _storage.ref().child('audio/$fileName');
      final uploadTask = ref.putFile(mp3File);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('MP3 yükleme hatası: $e');
    }
  }

  Future<String> uploadMp3FileFromBytes(
      Uint8List bytes, String fileName) async {
    try {
      final ref = _storage.ref().child('audio/$fileName');
      final metadata = SettableMetadata(contentType: 'audio/mpeg');
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('MP3 yükleme hatası: $e');
    }
  }

  Future<String> uploadCoverImage(File imageFile, String fileName) async {
    try {
      final ref = _storage.ref().child('covers/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Kapak resmi yükleme hatası: $e');
    }
  }

  Future<String> uploadCoverImageFromBytes(
      Uint8List bytes, String fileName) async {
    try {
      final ref = _storage.ref().child('covers/$fileName');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Kapak resmi yükleme hatası: $e');
    }
  }

  Future<void> saveTrackToFirestore(Track track) async {
    try {
      await _firestore
          .collection('tracks')
          .doc(track.id)
          .set(track.toFirestore());
    } catch (e) {
      throw Exception('Firestore kaydetme hatası: $e');
    }
  }

  Future<void> deleteTrack(String trackId) async {
    try {
      await _firestore.collection('tracks').doc(trackId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Stream<double> uploadMp3FileWithProgress(File mp3File, String fileName) {
    final ref = _storage.ref().child('audio/$fileName');
    final uploadTask = ref.putFile(mp3File);
    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
