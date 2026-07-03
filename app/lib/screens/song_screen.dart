import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../config/app_config.dart';
import '../data/song_repository.dart';
import '../models/song.dart';
import '../utils/themes.dart';
import '../widgets/ad_banner.dart';
import '../widgets/word_card.dart';

class SongScreen extends StatefulWidget {
  final Song song;
  final String lang;
  final List<SongSummary> playlist;
  final int index;
  final SongRepository repo;

  const SongScreen({
    super.key,
    required this.song,
    required this.lang,
    required this.playlist,
    required this.index,
    required this.repo,
  });

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

  late Song _song;
  late int _index;
  bool _advancing = false;

  List<WordEntry> get _words => _song.words;
  bool get _synced => _song.isSynced;

  @override
  void initState() {
    super.initState();
    _song = widget.song;
    _index = widget.index;
    _player = YoutubePlayerController.fromVideoId(
      videoId: _song.youtubeId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: false,
        strictRelatedVideos: true,
      ),
    );
    _player.listen((value) {
      if (value.playerState == PlayerState.ended) _playNext();
    });
    _pageController = PageController(viewportFraction: 0.86);
    _tts.setLanguage(appConfig.target.ttsLocale);
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
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _playNext() async {
    if (_advancing) return;
    if (_index + 1 >= widget.playlist.length) return;
    _advancing = true;
    final next = widget.playlist[_index + 1];
    try {
      final song = await widget.repo.loadSong(next.id);
      if (!mounted) return;
      setState(() {
        _index += 1;
        _song = song;
        _activeIndex = 0;
      });
      _syncTimer?.cancel();
      if (_synced) {
        _syncTimer = Timer.periodic(
            const Duration(milliseconds: 500), (_) => _syncToPlayback());
      }
      if (_pageController.hasClients) _pageController.jumpToPage(0);
      await _player.loadVideoById(videoId: song.youtubeId);
    } finally {
      _advancing = false;
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
    final theme = songThemeFor(_song.id);
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
                            _song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _song.artist,
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
                    itemCount: _words.length,
                    onPageChanged: (i) {
                      if (_userScrolling) setState(() => _activeIndex = i);
                    },
                    itemBuilder: (context, i) => WordCard(
                      word: _words[i],
                      lang: widget.lang,
                      theme: theme,
                      active: i == _activeIndex,
                      onSpeak: () => _tts.speak(_words[i].korean),
                      onTap: _synced ? () => _seekToWord(i) : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const AdCard(),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
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
