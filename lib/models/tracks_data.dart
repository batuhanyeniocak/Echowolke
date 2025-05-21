import '../models/track.dart';

class TracksData {
  static final List<Track> trendingTracks = [
    Track(
      id: '1',
      title: 'TITLE 1',
      artist: 'ARTIST 1',
      coverUrl: 'https://via.placeholder.com/300',
      audioUrl: 'https://example.com/audio1.mp3',
      duration: 240,
      playCount: 12500,
    ),
    Track(
      id: '2',
      title: 'TITLE 2',
      artist: 'ARTIST 2',
      coverUrl: 'https://via.placeholder.com/300',
      audioUrl: 'https://example.com/audio2.mp3',
      duration: 198,
      playCount: 8700,
    ),
    Track(
      id: '3',
      title: 'TITLE 3',
      artist: 'ARTIST 3',
      coverUrl: 'https://via.placeholder.com/300',
      audioUrl: 'https://example.com/audio3.mp3',
      duration: 320,
      playCount: 15800,
    ),
  ];

  static final List<Track> newReleaseTracks = [
    Track(
      id: '4',
      title: 'NEW TRACK 1',
      artist: 'ARTIST 1',
      coverUrl: 'https://via.placeholder.com/300',
      audioUrl: 'https://example.com/audio4.mp3',
      duration: 210,
      playCount: 5200,
    ),
    Track(
      id: '5',
      title: 'NEW TRACK 2',
      artist: 'ARTIST 2',
      coverUrl: 'https://via.placeholder.com/300',
      audioUrl: 'https://example.com/audio5.mp3',
      duration: 183,
      playCount: 2800,
    ),
  ];
}
