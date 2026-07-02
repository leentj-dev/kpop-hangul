class WordEntry {
  final String korean;
  final String romanization;
  final String english;
  final String spanish;
  final String portuguese;
  final String indonesian;
  final String japanese;
  final String thai;
  final String french;
  final String partOfSpeech;
  final String emoji;
  final String example;
  final String exampleTranslation;
  final double? timestamp;

  const WordEntry({
    required this.korean,
    required this.romanization,
    required this.english,
    this.spanish = '',
    this.portuguese = '',
    this.indonesian = '',
    this.japanese = '',
    this.thai = '',
    this.french = '',
    this.partOfSpeech = '',
    this.emoji = '',
    this.example = '',
    this.exampleTranslation = '',
    this.timestamp,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        korean: json['korean'] as String? ?? '',
        romanization: json['romanization'] as String? ?? '',
        english: json['english'] as String? ?? '',
        spanish: json['spanish'] as String? ?? '',
        portuguese: json['portuguese'] as String? ?? '',
        indonesian: json['indonesian'] as String? ?? '',
        japanese: json['japanese'] as String? ?? '',
        thai: json['thai'] as String? ?? '',
        french: json['french'] as String? ?? '',
        partOfSpeech: json['partOfSpeech'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '',
        example: json['example'] as String? ?? '',
        exampleTranslation: json['exampleTranslation'] as String? ?? '',
        timestamp: (json['timestamp'] as num?)?.toDouble(),
      );

  /// Translation for the given language code, falling back to English.
  String translation(String lang) {
    final value = switch (lang) {
      'spanish' => spanish,
      'portuguese' => portuguese,
      'indonesian' => indonesian,
      'japanese' => japanese,
      'thai' => thai,
      'french' => french,
      _ => english,
    };
    return value.isEmpty ? english : value;
  }
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String youtubeId;
  final List<WordEntry> words;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.youtubeId,
    required this.words,
  });

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        artist: json['artist'] as String? ?? '',
        youtubeId: json['youtubeId'] as String? ?? '',
        words: (json['words'] as List<dynamic>? ?? [])
            .map((w) => WordEntry.fromJson(w as Map<String, dynamic>))
            .toList(),
      );

  bool get isSynced => words.where((w) => w.timestamp != null).length >= 10;
}

class SongSummary {
  final String id;
  final String title;
  final String artist;
  final String youtubeId;
  final bool synced;
  final int wordCount;

  const SongSummary({
    required this.id,
    required this.title,
    required this.artist,
    required this.youtubeId,
    required this.synced,
    required this.wordCount,
  });

  factory SongSummary.fromJson(Map<String, dynamic> json) => SongSummary(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        artist: json['artist'] as String? ?? '',
        youtubeId: json['youtubeId'] as String? ?? '',
        synced: json['synced'] as bool? ?? false,
        wordCount: json['wordCount'] as int? ?? 0,
      );
}
