import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/track.dart';
import '../models/playlist.dart';
import 'package:rxdart/rxdart.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseAuth get auth => _auth;
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithUsernameAndPassword(
      String username, String password) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Bu kullanıcı adına sahip bir hesap bulunamadı.');
    }
    final userDoc = querySnapshot.docs.first;
    final email = userDoc.data()['email'] as String?;

    if (email == null) {
      throw Exception('Kullanıcı verisi bozuk, e-posta adresi eksik.');
    }

    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserCredential> registerWithUsernameEmailAndPassword(
      String username, String email, String password) async {
    final existingUser = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      throw Exception(
          'Bu kullanıcı adı zaten kullanılıyor. Lütfen farklı bir tane seçin.');
    }

    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username.toLowerCase(),
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
  }

  String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi formatı.';
      case 'weak-password':
        return 'Şifreniz çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Kullanıcı adı veya şifre hatalı.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

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

  Stream<List<Track>> getLikedSongs(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('likedSongs')
        .orderBy('likedAt', descending: true)
        .snapshots()
        .asyncMap((likedSongsSnapshot) async {
      List<Track> likedTracksWithLatestData = [];
      for (var likedSongDoc in likedSongsSnapshot.docs) {
        final trackId = likedSongDoc.id;
        final mainTrackDoc =
            await _firestore.collection('tracks').doc(trackId).get();

        if (mainTrackDoc.exists) {
          Track track =
              Track.fromFirestore(mainTrackDoc.data()!, mainTrackDoc.id);
          likedTracksWithLatestData.add(track);
        } else {
          print(
              'Uyarı: Ana koleksiyonda IDsi ${trackId} olan şarkı bulunamadı.');
        }
      }
      return likedTracksWithLatestData;
    });
  }

  Future<void> incrementTrackPlayCount(String trackId) async {
    try {
      await _firestore.collection('tracks').doc(trackId).update({
        'playCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('PlayCount artırılırken hata: $e');
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

  Stream<List<Track>> getAllTracks() {
    return _firestore.collection('tracks').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Track.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<Track>> getTrendingTracks() async {
    try {
      final snapshot = await _firestore
          .collection('tracks')
          .orderBy('playCount', descending: true)
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => Track.fromFirestore(doc.data(), doc.id))
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
          .map((doc) => Track.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Track?> getTrackById(String trackId) async {
    try {
      final doc = await _firestore.collection('tracks').doc(trackId).get();
      if (doc.exists) {
        return Track.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String> uploadMp3File(dynamic file, String fileName) async {
    try {
      final ref = _storage.ref().child('audio/$fileName');
      UploadTask uploadTask;
      final metadata = SettableMetadata(contentType: 'audio/mpeg');

      if (kIsWeb) {
        if (file is Uint8List) {
          uploadTask = ref.putData(file, metadata);
        } else {
          throw Exception(
              "Web platformunda MP3 için dosya tipi Uint8List olmalı.");
        }
      } else {
        if (file is File) {
          uploadTask = ref.putFile(file, metadata);
        } else {
          throw Exception("Mobil platformda MP3 için dosya tipi File olmalı.");
        }
      }
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('MP3 yükleme hatası: $e');
    }
  }

  Future<String> uploadCoverImage(dynamic file, String fileName) async {
    try {
      final ref = _storage.ref().child('covers/$fileName');
      UploadTask uploadTask;
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      if (kIsWeb) {
        if (file is Uint8List) {
          uploadTask = ref.putData(file, metadata);
        } else {
          throw Exception(
              "Web platformunda kapak resmi için dosya tipi Uint8List olmalı.");
        }
      } else {
        if (file is File) {
          uploadTask = ref.putFile(file, metadata);
        } else {
          throw Exception(
              "Mobil platformda kapak resmi için dosya tipi File olmalı.");
        }
      }
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

  Stream<double> uploadMp3FileWithProgress(dynamic file, String fileName) {
    final ref = _storage.ref().child('audio/$fileName');
    UploadTask uploadTask;
    final metadata = SettableMetadata(contentType: 'audio/mpeg');

    if (kIsWeb) {
      if (file is Uint8List) {
        uploadTask = ref.putData(file, metadata);
      } else {
        throw Exception(
            "Web platformunda MP3 progress için dosya tipi Uint8List olmalı.");
      }
    } else {
      if (file is File) {
        uploadTask = ref.putFile(file, metadata);
      } else {
        throw Exception(
            "Mobil platformda MP3 progress için dosya tipi File olmalı.");
      }
    }

    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  Future<void> createPlaylist(Playlist playlist) async {
    try {
      Map<String, dynamic> playlistData = playlist.toFirestore();
      playlistData['searchableName'] = playlist.name.toLowerCase();

      await _firestore
          .collection('playlists')
          .doc(playlist.id)
          .set(playlistData);
    } catch (e) {
      throw Exception('Çalma listesi oluşturulurken hata: $e');
    }
  }

  Stream<List<Playlist>> getUserPlaylists(String userId) {
    return _firestore
        .collection('playlists')
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Playlist.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updatePlaylist(
      String playlistId, Map<String, dynamic> data) async {
    try {
      if (data.containsKey('name')) {
        data['searchableName'] = (data['name'] as String).toLowerCase();
      }
      await _firestore.collection('playlists').doc(playlistId).update(data);
    } catch (e) {
      throw Exception('Çalma listesi güncellenirken hata: $e');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).delete();
    } catch (e) {
      throw Exception('Çalma listesi silinirken hata: $e');
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'trackIds': FieldValue.arrayUnion([trackId]),
      });
    } catch (e) {
      throw Exception('Şarkı çalma listesine eklenirken hata: $e');
    }
  }

  Future<void> removeTrackFromPlaylist(
      String playlistId, String trackId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'trackIds': FieldValue.arrayRemove([trackId]),
      });
    } catch (e) {
      throw Exception('Şarkı çalma listesinden çıkarılırken hata: $e');
    }
  }

  Future<Playlist?> getPlaylistById(String playlistId) async {
    try {
      final doc =
          await _firestore.collection('playlists').doc(playlistId).get();
      if (doc.exists) {
        return Playlist.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Çalma listesi getirilirken hata: $e');
      return null;
    }
  }

  Future<List<Track>> getTracksByIds(List<String> trackIds) async {
    if (trackIds.isEmpty) {
      return [];
    }
    try {
      final snapshot = await _firestore
          .collection('tracks')
          .where(FieldPath.documentId, whereIn: trackIds)
          .get();
      return snapshot.docs
          .map((doc) => Track.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Şarkılar ID\'lere göre getirilirken hata: $e');
      return [];
    }
  }

  Future<List<Track>> getAllTracksOnce() async {
    try {
      final snapshot = await _firestore.collection('tracks').get();
      return snapshot.docs
          .map((doc) => Track.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Tüm şarkılar getirilirken hata: $e');
      return [];
    }
  }

  Stream<bool> isTrackLikedStream(String trackId) {
    if (currentUser == null) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('likedSongs')
        .doc(trackId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Future<bool> isTrackLiked(String trackId) async {
    if (currentUser == null) return false;
    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('likedSongs')
        .doc(trackId)
        .get();
    return doc.exists;
  }

  Future<void> toggleLikedSong(String trackId, bool like) async {
    if (currentUser == null) {
      throw Exception("Kullanıcı oturum açmamış.");
    }
    final userLikedSongsRef = _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('likedSongs')
        .doc(trackId);

    if (like) {
      final trackDoc = await _firestore.collection('tracks').doc(trackId).get();
      if (trackDoc.exists) {
        await userLikedSongsRef.set({
          'likedAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      await userLikedSongsRef.delete();
    }
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  Future<List<Track>> searchTracks(String query) async {
    if (query.isEmpty) return [];

    try {
      final lowerCaseQuery = query.toLowerCase();
      final searchEnd = '$lowerCaseQuery\uf8ff';

      final titleQuery = _firestore
          .collection('tracks')
          .where('searchableTitle', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('searchableTitle', isLessThanOrEqualTo: searchEnd)
          .limit(10)
          .get();

      final artistQuery = _firestore
          .collection('tracks')
          .where('searchableArtist', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('searchableArtist', isLessThanOrEqualTo: searchEnd)
          .limit(10)
          .get();

      final results = await Future.wait([titleQuery, artistQuery]);

      final titleDocs = results[0].docs;
      final artistDocs = results[1].docs;

      final Map<String, Track> uniqueTracks = {};

      for (var doc in titleDocs) {
        final track = Track.fromFirestore(doc.data(), doc.id);
        uniqueTracks[track.id] = track;
      }

      for (var doc in artistDocs) {
        final track = Track.fromFirestore(doc.data(), doc.id);
        uniqueTracks[track.id] = track;
      }

      return uniqueTracks.values.toList();
    } catch (e) {
      print("Şarkı arama hatası: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('username',
              isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(10)
          .get();
      return snapshot.docs.map((doc) {
        var data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print("Kullanıcı arama hatası: $e");
      return [];
    }
  }

  Future<List<Playlist>> searchPlaylists(String query) async {
    if (query.isEmpty) return [];
    try {
      final lowerCaseQuery = query.toLowerCase();
      final snapshot = await _firestore
          .collection('playlists')
          .where('searchableName', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('searchableName', isLessThanOrEqualTo: '$lowerCaseQuery\uf8ff')
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => Playlist.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Çalma listesi arama hatası: $e");
      return [];
    }
  }
}
