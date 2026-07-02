import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/song_repository.dart';
import '../models/song.dart';
import '../utils/languages.dart';
import '../utils/themes.dart';
import 'song_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _repo = SongRepository();
  List<SongSummary> _songs = [];
  String _query = '';
  String _lang = 'english';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await _repo.loadManifest();
    if (!mounted) return;
    setState(() {
      _lang = prefs.getString('lang') ?? 'english';
      _songs = songs;
      _loading = false;
    });
  }

  Future<void> _setLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
    setState(() => _lang = lang);
  }

  String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s'), '');

  List<SongSummary> get _filtered => _query.isEmpty
      ? _songs
      : _songs
          .where((s) =>
              _norm(s.title).contains(_norm(_query)) ||
              _norm(s.artist).contains(_norm(_query)))
          .toList();

  Future<void> _openSong(SongSummary summary) async {
    final song = await _repo.loadSong(summary.id);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SongScreen(song: song, lang: _lang),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'K-pop 한글',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate_rounded),
            initialValue: _lang,
            onSelected: _setLang,
            itemBuilder: (context) => [
              for (final e in supportedLanguages.entries)
                PopupMenuItem(value: e.key, child: Text(e.value)),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search songs or artists',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final s = _filtered[i];
                final theme = songThemeFor(s.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openSong(s),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: theme.gradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.artist,
                                  style: TextStyle(
                                      color: theme.accent, fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _chip('${s.wordCount} words'),
                                    if (s.synced) ...[
                                      const SizedBox(width: 6),
                                      _chip('sync', color: theme.accent),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_circle_fill_rounded,
                              color: Colors.white70, size: 36),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _chip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color ?? Colors.white60),
      ),
    );
  }
}
