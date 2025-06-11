import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/track.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseAuth get auth => _auth;

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
      print('Kayıt başarılı: ${userCredential.user!.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Kayıt hatası: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Genel kayıt hatası: $e');
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
      print('Giriş başarılı: ${userCredential.user!.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Giriş hatası: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Genel giriş hatası: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('Çıkış başarılı.');
    } catch (e) {
      print('Çıkış hatası: $e');
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

  Future<String> uploadMp3File(File mp3File, String fileName) async {
    try {
      print('MP3 yükleniyor (Mobil): $fileName');
      final ref = _storage.ref().child('audio/$fileName');
      final uploadTask = ref.putFile(mp3File);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('MP3 yüklendi. URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('MP3 yükleme hatası: $e');
      throw Exception('MP3 yükleme hatası: $e');
    }
  }

  Future<String> uploadMp3FileFromBytes(
      Uint8List bytes, String fileName) async {
    try {
      print('MP3 yükleniyor (Web): $fileName, Boyut: ${bytes.length} bytes');
      final ref = _storage.ref().child('audio/$fileName');

      final metadata = SettableMetadata(
        contentType: 'audio/mpeg',
        customMetadata: {'uploaded': DateTime.now().toString()},
      );

      final uploadTask = ref.putData(bytes, metadata);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('MP3 yüklendi. URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('MP3 yükleme hatası (Web): $e');
      throw Exception('MP3 yükleme hatası: $e');
    }
  }

  Future<String> uploadCoverImage(File imageFile, String fileName) async {
    try {
      print('Kapak resmi yükleniyor (Mobil): $fileName');
      final ref = _storage.ref().child('covers/$fileName');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final uploadTask = ref.putFile(imageFile, metadata);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Kapak resmi yüklendi. URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Kapak resmi yükleme hatası: $e');
      throw Exception('Kapak resmi yükleme hatası: $e');
    }
  }

  Future<String> uploadCoverImageFromBytes(
      Uint8List bytes, String fileName) async {
    try {
      print(
          'Kapak resmi yükleniyor (Web): $fileName, Boyut: ${bytes.length} bytes');
      final ref = _storage.ref().child('covers/$fileName');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded': DateTime.now().toString()},
      );

      final uploadTask = ref.putData(bytes, metadata);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Kapak resmi yüklendi. URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Kapak resmi yükleme hatası (Web): $e');
      throw Exception('Kapak resmi yükleme hatası: $e');
    }
  }

  Future<void> saveTrackToFirestore(Track track) async {
    try {
      print('Track Firestore\'a kaydediliyor: ${track.id}');

      final trackData = track.toFirestore();
      print('Track data: $trackData');

      await _firestore.collection('tracks').doc(track.id).set(trackData);

      print('Track başarıyla kaydedildi');
    } catch (e) {
      print('Firestore kaydetme hatası: $e');
      throw Exception('Firestore kaydetme hatası: $e');
    }
  }

  Future<void> deleteTrack(String trackId) async {
    try {
      await _firestore.collection('tracks').doc(trackId).delete();
    } catch (e) {
      print('Şarkı silme hatası: $e');
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
