import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/song.dart';

/// Loads bundled song data from assets/songs/ and keeps it up to date by
/// downloading new songs from the GitHub repo (no backend needed).
class SongRepository {
  static const _remoteBase =
      'https://raw.githubusercontent.com/leentj-dev/kpop-hangul/main/app/assets/songs';

  final Map<String, Song> _cache = {};
  List<SongSummary> _bundled = [];
  List<SongSummary> _downloaded = [];
  Directory? _dir;

  Future<Directory> _songsDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/songs');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _dir = dir;
    return dir;
  }

  List<SongSummary> _parseManifest(String raw) =>
      (jsonDecode(raw) as List<dynamic>)
          .map((e) => SongSummary.fromJson(e as Map<String, dynamic>))
          .toList();

  /// Bundled songs + previously downloaded songs, synced first.
  Future<List<SongSummary>> loadManifest() async {
    _bundled = _parseManifest(
        await rootBundle.loadString('assets/songs/manifest.json'));

    final dir = await _songsDir();
    final cached = File('${dir.path}/manifest.json');
    if (cached.existsSync()) {
      try {
        final remote = _parseManifest(cached.readAsStringSync());
        final bundledIds = _bundled.map((s) => s.id).toSet();
        _downloaded = remote
            .where((s) =>
                !bundledIds.contains(s.id) &&
                File('${dir.path}/${s.id}.json').existsSync())
            .toList();
      } on FormatException {
        _downloaded = [];
      }
    }
    return _merged();
  }

  List<SongSummary> _merged() {
    final list = [..._bundled, ..._downloaded];
    list.sort((a, b) {
      if (a.synced != b.synced) return a.synced ? -1 : 1;
      return a.artist.compareTo(b.artist);
    });
    return list;
  }

  /// Checks GitHub for new songs and downloads the missing ones.
  /// Returns the updated list if anything new arrived, null otherwise.
  Future<List<SongSummary>?> syncRemote() async {
    try {
      final res = await http
          .get(Uri.parse('$_remoteBase/manifest.json'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final remote = _parseManifest(utf8.decode(res.bodyBytes));

      final dir = await _songsDir();
      final knownIds = {
        ..._bundled.map((s) => s.id),
        ..._downloaded.map((s) => s.id),
      };
      final fresh = <SongSummary>[];
      for (final summary in remote.where((s) => !knownIds.contains(s.id))) {
        final song = await http
            .get(Uri.parse('$_remoteBase/${summary.id}.json'))
            .timeout(const Duration(seconds: 10));
        if (song.statusCode != 200) continue;
        final body = utf8.decode(song.bodyBytes);
        jsonDecode(body); // validate before persisting
        File('${dir.path}/${summary.id}.json').writeAsStringSync(body);
        fresh.add(summary);
      }
      if (fresh.isEmpty) return null;

      File('${dir.path}/manifest.json')
          .writeAsStringSync(utf8.decode(res.bodyBytes));
      _downloaded = [..._downloaded, ...fresh];
      return _merged();
    } on Exception {
      return null; // offline or GitHub unreachable — bundled songs still work
    }
  }

  Future<Song> loadSong(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;

    String raw;
    final dir = await _songsDir();
    final file = File('${dir.path}/$id.json');
    if (file.existsSync()) {
      raw = file.readAsStringSync();
    } else {
      raw = await rootBundle.loadString('assets/songs/$id.json');
    }
    final song = Song.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _cache[id] = song;
    return song;
  }
}
