import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/song_repository.dart';
import '../models/song.dart';
import '../utils/ads.dart';
import '../utils/languages.dart';
import '../utils/themes.dart';
import '../widgets/ad_banner.dart';
import 'song_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _repo = SongRepository();
  final _scrollController = ScrollController();
  List<SongSummary> _songs = [];
  String _query = '';
  String _lang = 'english';
  bool _loading = true;
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > 600;
    if (show != _showScrollTop) setState(() => _showScrollTop = show);
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
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
    _syncRemote();
  }

  Future<void> _syncRemote() async {
    final before = _songs.length;
    final updated = await _repo.syncRemote();
    if (updated == null || !mounted) return;
    setState(() => _songs = updated);
    final added = updated.length - before;
    if (added > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New songs added: $added 🎵')),
      );
    }
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
      floatingActionButton: _showScrollTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              tooltip: 'Scroll to top',
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            )
          : null,
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
          : Builder(builder: (context) {
              final items = _withAds(_filtered);
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final s = items[i];
                  if (s == null) return const AdBanner(size: AdSize.banner);
                  final theme = songThemeFor(s.id);
                  return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openSong(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 136,
                            height: 76,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                      gradient: theme.gradient),
                                ),
                                Image.network(
                                  'https://img.youtube.com/vi/${s.youtubeId}/mqdefault.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Icon(Icons.music_note_rounded,
                                        color: theme.accent, size: 32),
                                  ),
                                ),
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white70,
                                    size: 30,
                                  ),
                                ),
                                if (s.synced)
                                  Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'SYNC',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: theme.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                s.artist,
                                style: TextStyle(
                                    color: theme.accent, fontSize: 12.5),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${s.wordCount} words',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                },
              );
            }),
    );
  }

  /// Interleaves null ad-slots after every [Ads.feedInterval] songs
  /// (no trailing ad).
  List<SongSummary?> _withAds(List<SongSummary> songs) {
    final out = <SongSummary?>[];
    for (var i = 0; i < songs.length; i++) {
      out.add(songs[i]);
      final isLast = i == songs.length - 1;
      if (!isLast && (i + 1) % Ads.feedInterval == 0) out.add(null);
    }
    return out;
  }
}
