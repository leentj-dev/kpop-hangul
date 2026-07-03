import '../utils/hangul.dart';

/// Strategy for the language being *learned* (Korean, Japanese, Spanish…).
///
/// Each flavor of the app plugs in one of these. The song JSON schema is
/// shared — the headword lives in `WordEntry.korean` regardless of flavor —
/// so only the per-character breakdown and TTS locale differ.
abstract class TargetLanguage {
  const TargetLanguage();

  /// TTS locale for reading the headword aloud, e.g. 'ko-KR', 'ja-JP'.
  String get ttsLocale;

  /// Sub-unit chips shown under the headword (Korean jamo, Japanese kana…).
  /// Return an empty list to hide the breakdown row (e.g. romanized langs).
  List<String> breakdown(String word);
}

/// Korean: decompose each syllable into its jamo (ㅂ + ㅗ + ㄴ).
class KoreanTarget extends TargetLanguage {
  const KoreanTarget();

  @override
  String get ttsLocale => 'ko-KR';

  @override
  List<String> breakdown(String word) {
    return decomposeHangul(word)
        .where((c) => c.parts.length > 1)
        .map((c) => c.parts.join(' + '))
        .toList();
  }
}

/// Japanese: no automatic breakdown yet (furigana would come from the data).
class JapaneseTarget extends TargetLanguage {
  const JapaneseTarget();

  @override
  String get ttsLocale => 'ja-JP';

  @override
  List<String> breakdown(String word) => const [];
}

/// Spanish and other romanized languages: no sub-unit breakdown needed.
class RomanTarget extends TargetLanguage {
  final String locale;
  const RomanTarget(this.locale);

  @override
  String get ttsLocale => locale;

  @override
  List<String> breakdown(String word) => const [];
}
