import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/song.dart';

/// Loads bundled song data from assets/songs/.
class SongRepository {
  List<SongSummary>? _manifest;
  final Map<String, Song> _cache = {};

  Future<List<SongSummary>> loadManifest() async {
    if (_manifest != null) return _manifest!;
    final raw = await rootBundle.loadString('assets/songs/manifest.json');
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => SongSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    // Synced songs first — they showcase the core experience.
    list.sort((a, b) {
      if (a.synced != b.synced) return a.synced ? -1 : 1;
      return a.artist.compareTo(b.artist);
    });
    _manifest = list;
    return list;
  }

  Future<Song> loadSong(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/songs/$id.json');
    final song = Song.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _cache[id] = song;
    return song;
  }
}
