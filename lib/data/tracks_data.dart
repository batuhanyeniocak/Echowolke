import '../models/track.dart';
import '../services/firebase_service.dart';

class TracksData {
  static final FirebaseService _firebaseService = FirebaseService();
  static List<Track> trendingTracks = [];
  static List<Track> newReleaseTracks = [];

  static Future<void> loadTracks() async {
    trendingTracks = await _firebaseService.getTrendingTracks();
    newReleaseTracks = await _firebaseService.getNewReleaseTracks();
  }

  static Future<void> refreshTrendingTracks() async {
    trendingTracks = await _firebaseService.getTrendingTracks();
  }

  static Future<void> refreshNewReleaseTracks() async {
    newReleaseTracks = await _firebaseService.getNewReleaseTracks();
  }
}
