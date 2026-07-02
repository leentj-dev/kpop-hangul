import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/song.dart';
import '../utils/ads.dart';
import '../utils/themes.dart';
import '../widgets/ad_banner.dart';
import '../widgets/word_card.dart';

class SongScreen extends StatefulWidget {
  final Song song;
  final String lang;

  const SongScreen({super.key, required this.song, required this.lang});

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  late final YoutubePlayerController _player;
  late final PageController _pageController;
  final FlutterTts _tts = FlutterTts();
  Timer? _syncTimer;
  int _activeIndex = 0;
  bool _userScrolling = false;

  /// Page layout: each entry is a word index, or null for an ad page.
  final List<int?> _pages = [];
  final Map<int, int> _wordToPage = {};

  List<WordEntry> get _words => widget.song.words;
  bool get _synced => widget.song.isSynced;

  void _buildPages() {
    for (var i = 0; i < _words.length; i++) {
      _wordToPage[i] = _pages.length;
      _pages.add(i);
      final isLast = i == _words.length - 1;
      if (!isLast && (i + 1) % Ads.cardInterval == 0) _pages.add(null);
    }
  }

  @override
  void initState() {
    super.initState();
    _buildPages();
    _player = YoutubePlayerController.fromVideoId(
      videoId: widget.song.youtubeId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false,
        strictRelatedVideos: true,
      ),
    );
    _pageController = PageController(viewportFraction: 0.86);
    _tts.setLanguage('ko-KR');
    if (_synced) {
      _syncTimer = Timer.periodic(
          const Duration(milliseconds: 500), (_) => _syncToPlayback());
    }
  }

  Future<void> _syncToPlayback() async {
    if (_userScrolling || !mounted) return;
    final t = await _player.currentTime;
    var index = -1;
    for (var i = 0; i < _words.length; i++) {
      final ts = _words[i].timestamp;
      if (ts != null && ts <= t) index = i;
    }
    if (index >= 0 && index != _activeIndex && mounted) {
      setState(() => _activeIndex = index);
      _pageController.animateToPage(
        _wordToPage[index] ?? index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _seekToWord(int index) async {
    final ts = _words[index].timestamp;
    if (ts != null) {
      _player.seekTo(seconds: ts, allowSeekAhead: true);
    }
    setState(() => _activeIndex = index);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _player.close();
    _pageController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = songThemeFor(widget.song.id);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: theme.gradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.song.artist,
                            style: TextStyle(color: theme.accent, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (_synced)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(Icons.sync_rounded,
                            color: theme.accent, size: 18),
                      ),
                  ],
                ),
              ),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(controller: _player),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollStartNotification &&
                        n.dragDetails != null) {
                      _userScrolling = true;
                    } else if (n is ScrollEndNotification) {
                      // Give the user a moment before auto-sync resumes.
                      Future.delayed(const Duration(seconds: 3), () {
                        _userScrolling = false;
                      });
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (p) {
                      final w = _pages[p];
                      if (w != null && _userScrolling) {
                        setState(() => _activeIndex = w);
                      }
                    },
                    itemBuilder: (context, p) {
                      final i = _pages[p];
                      if (i == null) return _AdCard(theme: theme);
                      return WordCard(
                        word: _words[i],
                        lang: widget.lang,
                        theme: theme,
                        active: i == _activeIndex,
                        onSpeak: () => _tts.speak(_words[i].korean),
                        onTap: _synced ? () => _seekToWord(i) : null,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_activeIndex + 1} / ${_words.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ad shaped like a word card so it doesn't break the swipe deck.
class _AdCard extends StatelessWidget {
  final SongTheme theme;
  const _AdCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'AD',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: theme.accent.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          const AdBanner(),
          const Spacer(),
        ],
      ),
    );
  }
}
